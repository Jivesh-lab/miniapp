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

    const now = new Date();
    const todayUtc = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
    // One day of tolerance so users ahead of UTC can still book "today".
    if (selectedDate.getTime() < todayUtc - 24 * 60 * 60 * 1000) {
      return sendWorkerValidationError(res, "Cannot book a date in the past");
    }

    if (!mongoose.Types.ObjectId.isValid(workerId)) {
      return sendWorkerValidationError(res, "Invalid worker id");
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
      status: { $in: ["pending", "confirmed", "in-progress", "completed"] },
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
      return sendWorkerError(res, 403, "Unauthorized access to booking");
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
      return sendWorkerError(res, 403, "Unauthorized: You can only cancel your own booking");
    }

    if (["completed", "cancelled", "rejected"].includes(booking.status)) {
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

    // Filtering on isRated:false makes the claim atomic, so concurrent requests cannot double-rate.
    const updatedBooking = await Booking.findOneAndUpdate(
      { _id: id, userId, isRated: false },
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

    if (!updatedBooking) {
      return sendWorkerValidationError(res, "Already rated");
    }

    const reviewEntry = {
      userId: String(booking.userId),
      comment: normalizedComment,
      rating: parsedRating,
      createdAt: new Date(),
    };

    // Single pipeline update so concurrent ratings cannot overwrite each other's sums.
    const worker = await Worker.findByIdAndUpdate(
      booking.workerId,
      [
        {
          $set: {
            reviews: { $concatArrays: [{ $ifNull: ["$reviews", []] }, [{ $literal: reviewEntry }]] },
            ratingSum: { $add: [{ $ifNull: ["$ratingSum", 0] }, parsedRating] },
            ratingCount: { $add: [{ $ifNull: ["$ratingCount", 0] }, 1] },
          },
        },
        { $set: { rating: { $round: [{ $divide: ["$ratingSum", "$ratingCount"] }, 1] } } },
      ],
      { returnDocument: "after" }
    ).lean();

    if (!worker) {
      return sendWorkerNotFound(res, "Worker not found");
    }

    return res.status(200).json({
      success: true,
      message: "Rating and comment submitted",
      data: updatedBooking,
    });
  } catch (error) {
    return handleWorkerException(res, error, "Server error");
  }
};
