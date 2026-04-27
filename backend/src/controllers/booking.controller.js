import Booking from "../models/booking.model.js";
import Worker from "../models/worker.model.js";
import mongoose from "mongoose";
import {
  handleWorkerException,
  sendWorkerError,
  sendWorkerNotFound,
  sendWorkerValidationError,
} from "../utils/worker-error.util.js";
import { getIO } from "../socket.js";

const DEFAULT_ALL_SLOTS = ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM"];

const allowedTransitions = {
  pending: ["confirmed", "cancelled"],
  confirmed: ["in-progress", "completed", "cancelled"],
  "in-progress": ["completed", "cancelled"],
  completed: [],
  cancelled: [],
};

const invalidSlotResponse = (res) => {
  return sendWorkerValidationError(res, "Selected slot is not available");
};

export const createBooking = async (req, res) => {
  try {
    const userId = String(req.user?.id ?? "").trim();
    const { workerId, date, time, address } = req.body;

    if (!userId) {
      return sendWorkerError(res, 401, "Unauthorized");
    }

    if (!workerId || !date || !time || !address) {
      return sendWorkerValidationError(
        res,
        "workerId, date, time, and address are required"
      );
    }

    if (!/^\d{4}-\d{2}-\d{2}$/.test(String(date))) {
      return sendWorkerValidationError(res, "date must be in YYYY-MM-DD format");
    }

    const selectedDate = new Date(String(date));
    if (Number.isNaN(selectedDate.getTime())) {
      return sendWorkerValidationError(res, "Invalid date");
    }

    const worker = await Worker.findById(workerId).select("_id").lean();

    if (!worker) {
      return sendWorkerNotFound(res, "Worker not found");
    }

    const hasSlot = DEFAULT_ALL_SLOTS.includes(String(time));

    if (!hasSlot) {
      return invalidSlotResponse(res);
    }

    const existingBooking = await Booking.findOne({
      workerId,
      date,
      time,
      status: { $nin: ["cancelled", "rejected"] },
    }).lean();

    if (existingBooking) {
      return res.status(409).json({
        success: false,
        message: "This worker is already booked for the selected time slot",
      });
    }

    const booking = await Booking.create({
      userId,
      workerId,
      date,
      time,
      address,
      status: "pending",
    });

    try {
      getIO().to(String(workerId)).emit("new_booking", booking);
    } catch (e) {
      console.error("Socket error on new_booking:", e);
    }

    return res.status(201).json({
      success: true,
      message: "Booking created successfully",
      data: booking,
    });
  } catch (error) {
    return handleWorkerException(res, error, "Failed to create booking");
  }
};

export const getBookings = async (req, res) => {
  return getUserBookings(req, res);
};

export const getUserBookings = async (req, res) => {
  try {
    const userId = String(req.user?.id ?? "").trim();

    if (!userId) {
      return sendWorkerError(res, 401, "Unauthorized");
    }

    const bookings = await Booking.find({ userId })
      .populate("workerId", "name rating")
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json({
      success: true,
      count: bookings.length,
      data: bookings,
    });
  } catch (error) {
    return handleWorkerException(res, error, "Failed to fetch user bookings");
  }
};

export const updateBookingStatus = async (req, res) => {
  try {
    const workerFromToken = req.worker?.workerId;
    const { id } = req.params;
    const { status } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendWorkerValidationError(res, "Invalid booking id");
    }

    if (!workerFromToken) {
      return sendWorkerError(res, 401, "Unauthorized");
    }

    if (
      !status ||
      !["confirmed", "rejected", "in-progress", "completed"].includes(status)
    ) {
      return sendWorkerValidationError(res, "Invalid status");
    }

    const booking = await Booking.findById(id);

    if (!booking) {
      return sendWorkerError(res, 404, "Booking not found");
    }

    if (booking.workerId.toString() !== String(workerFromToken)) {
      return sendWorkerError(res, 401, "Unauthorized access to booking");
    }

    const workerAllowedTransitions = {
      pending: ["confirmed", "rejected"],
      confirmed: ["in-progress", "rejected"],
      rejected: [],
      "in-progress": ["completed"],
      completed: [],
      cancelled: [],
    };

    const nextAllowed = workerAllowedTransitions[booking.status] || [];

    if (!nextAllowed.includes(status)) {
      return sendWorkerValidationError(
        res,
        `Invalid status transition from ${booking.status} to ${status}`
      );
    }

    booking.status = status;
    await booking.save();

    const updated = await Booking.findById(booking._id)
      .populate("workerId", "name rating")
      .lean();

    try {
      getIO().to(String(updated.userId)).emit("booking_status_updated", updated);
    } catch (e) {
      console.error("Socket error on booking_status_updated:", e);
    }

    return res.status(200).json({
      success: true,
      message: "Booking status updated successfully",
      data: updated,
    });
  } catch (error) {
    return handleWorkerException(res, error, "Failed to update booking status");
  }
};

export const deleteBooking = async (req, res) => {
  return res.status(405).json({
    success: false,
    message: "Use PATCH /api/bookings/cancel/:id to cancel booking",
  });
};

export const cancelBooking = async (req, res) => {
  try {
    const bookingId = req.params.id;
    const userId = String(req.user?.id ?? "").trim();

    if (!mongoose.Types.ObjectId.isValid(bookingId)) {
      return sendWorkerValidationError(res, "Invalid booking id");
    }

    if (!userId) {
      return sendWorkerError(res, 401, "Unauthorized");
    }

    const booking = await Booking.findById(bookingId);

    if (!booking) {
      return sendWorkerError(res, 404, "Booking not found");
    }

    if (String(booking.userId) !== userId) {
      return sendWorkerError(res, 401, "Unauthorized: You can only cancel your own booking");
    }

    if (booking.status === "completed" || booking.status === "cancelled") {
      return sendWorkerValidationError(res, "Cannot cancel this booking");
    }

    booking.status = "cancelled";
    await booking.save();

    try {
      getIO().to(String(booking.workerId)).emit("booking_status_updated", booking);
    } catch (e) {
      console.error("Socket error on booking_status_updated:", e);
    }

    return res.status(200).json({
      success: true,
      message: "Booking cancelled successfully",
    });
  } catch (error) {
    return handleWorkerException(res, error, "Failed to cancel booking");
  }
};

export const rateBooking = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, comment } = req.body ?? {};
    const userId = String(req.user?.id ?? "").trim();

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendWorkerValidationError(res, "Invalid booking id");
    }

    if (!userId) {
      return sendWorkerError(res, 401, "Unauthorized");
    }

    const parsedRating = Number(rating);
    if (!Number.isInteger(parsedRating) || parsedRating < 1 || parsedRating > 5) {
      return sendWorkerValidationError(res, "rating must be an integer between 1 and 5");
    }

    if (comment !== undefined && typeof comment !== "string") {
      return sendWorkerValidationError(res, "comment must be a string");
    }

    const normalizedComment = typeof comment === "string" ? comment.trim() : "";

    const booking = await Booking.findById(id).select("_id userId workerId status isRated").lean();

    if (!booking) {
      return sendWorkerError(res, 404, "Booking not found");
    }

    if (String(booking.userId) !== userId) {
      return sendWorkerError(res, 401, "Unauthorized");
    }

    if (booking.status !== "completed") {
      return sendWorkerValidationError(res, "Booking not completed");
    }

    if (booking.isRated) {
      return sendWorkerValidationError(res, "Already rated");
    }

    const updatedBooking = await Booking.findByIdAndUpdate(
      id,
      {
        $set: {
          isRated: true,
          rating: parsedRating,
          comment: normalizedComment,
          // Keep legacy field in sync for backward compatibility.
          review: normalizedComment,
        },
      },
      { returnDocument: "after", runValidators: true }
    ).lean();

    const reviewEntry = {
      userId: booking.userId,
      comment: normalizedComment,
      rating: parsedRating,
      createdAt: new Date(),
    };

    await Worker.findByIdAndUpdate(booking.workerId, {
      $push: {
        reviews: reviewEntry,
      },
    });

    const worker = await Worker.findById(booking.workerId);

    if (!worker) {
      return sendWorkerNotFound(res, "Worker not found");
    }

    worker.ratingSum = Number(worker.ratingSum || 0) + parsedRating;
    worker.ratingCount = Number(worker.ratingCount || 0) + 1;
    const averageRating = worker.ratingCount > 0 ? worker.ratingSum / worker.ratingCount : 0;
    worker.rating = Number(averageRating.toFixed(1));

    await worker.save();

    return res.status(200).json({
      success: true,
      message: "Rating and comment submitted",
      data: updatedBooking,
    });
  } catch (error) {
    return handleWorkerException(res, error, "Server error");
  }
};
