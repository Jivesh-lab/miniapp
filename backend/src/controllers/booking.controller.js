import Booking from "../models/booking.model.js";
import Worker from "../models/worker.model.js";
import mongoose from "mongoose";

const allowedTransitions = {
  pending: ["confirmed", "cancelled"],
  confirmed: ["in-progress", "completed", "cancelled"],
  "in-progress": ["completed", "cancelled"],
  completed: [],
  cancelled: [],
};

const invalidSlotResponse = (res) => {
  return res.status(400).json({
    success: false,
    message: "Invalid slot",
  });
};

export const createBooking = async (req, res) => {
  try {
    const { userId, workerId, date, time, address } = req.body;

    if (!userId || !workerId || !date || !time || !address) {
      return res.status(400).json({
        success: false,
        message: "userId, workerId, date, time, and address are required",
      });
    }

    const worker = await Worker.findById(workerId).select("availableSlots").lean();

    if (!worker) {
      return res.status(404).json({
        success: false,
        message: "Worker not found",
      });
    }

    const slotEntry = worker.availableSlots.find((slot) => slot.date === date);
    const hasSlot = slotEntry?.timeSlots.includes(time);

    if (!hasSlot) {
      return invalidSlotResponse(res);
    }

    const booking = await Booking.create({
      userId,
      workerId,
      date,
      time,
      address,
      status: "pending",
    });

    return res.status(201).json({
      success: true,
      message: "Booking created successfully",
      data: booking,
    });
  } catch (error) {
    if (error?.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Slot already booked",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to create booking",
      error: error.message,
    });
  }
};

export const getBookings = async (req, res) => {
  try {
    const { userId } = req.params;
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 50);
    const skip = (page - 1) * limit;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const bookingQuery = { userId };

    const [bookings, total] = await Promise.all([
      Booking.find(bookingQuery)
        .populate("workerId", "name rating")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Booking.countDocuments(bookingQuery),
    ]);

    return res.status(200).json({
      success: true,
      count: bookings.length,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      data: bookings,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch bookings",
      error: error.message,
    });
  }
};

export const updateBookingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (
      !status ||
      !["pending", "confirmed", "in-progress", "completed", "cancelled"].includes(status)
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid status",
      });
    }

    const booking = await Booking.findById(id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: "Booking not found",
      });
    }

    const nextAllowed = allowedTransitions[booking.status] || [];

    if (!nextAllowed.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status transition from ${booking.status} to ${status}`,
      });
    }

    booking.status = status;
    await booking.save();

    const updated = await Booking.findById(booking._id)
      .populate("workerId", "name rating")
      .lean();

    return res.status(200).json({
      success: true,
      message: "Booking status updated successfully",
      data: updated,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update booking status",
      error: error.message,
    });
  }
};

export const deleteBooking = async (req, res) => {
  try {
    const { id } = req.params;

    const booking = await Booking.findById(id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: "Booking not found",
      });
    }

    if (booking.status !== "pending") {
      return res.status(400).json({
        success: false,
        message: "Only pending bookings can be cancelled",
      });
    }

    booking.status = "cancelled";
    await booking.save();

    return res.status(200).json({
      success: true,
      message: "Booking cancelled successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to cancel booking",
      error: error.message,
    });
  }
};

export const rateBooking = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, comment, skip } = req.body ?? {};

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid booking id",
      });
    }

    if (comment !== undefined && typeof comment !== "string") {
      return res.status(400).json({
        success: false,
        message: "comment must be a string",
      });
    }

    const normalizedComment = typeof comment === "string" ? comment.trim() : "";
    const isSkip = skip === true;

    let normalizedRating;
    if (!isSkip) {
      const parsedRating = Number(rating);
      if (!Number.isInteger(parsedRating) || parsedRating < 1 || parsedRating > 5) {
        return res.status(400).json({
          success: false,
          message: "rating must be an integer between 1 and 5",
        });
      }
      normalizedRating = parsedRating;
    }

    const booking = await Booking.findById(id)
      .select("_id userId workerId status isRated")
      .lean();

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: "Booking not found",
      });
    }

    if (booking.status !== "completed") {
      return res.status(400).json({
        success: false,
        message: "Booking not completed",
      });
    }

    if (booking.isRated) {
      return res.status(400).json({
        success: false,
        message: "Already rated",
      });
    }

    const bookingUpdate = { isRated: true };
    if (!isSkip) {
      bookingUpdate.rating = normalizedRating;
      bookingUpdate.review = normalizedComment;
    }

    const updatedBooking = await Booking.findByIdAndUpdate(
      id,
      {
        $set: bookingUpdate,
      },
      { new: true, runValidators: true }
    ).lean();

    if (isSkip) {
      return res.status(200).json({
        success: true,
        message: "Rating skipped successfully",
        data: updatedBooking,
      });
    }

    const reviewEntry = {
      userId: booking.userId,
      comment: normalizedComment,
      rating: normalizedRating,
      createdAt: new Date(),
    };

    await Worker.findByIdAndUpdate(booking.workerId, {
      $push: {
        reviews: reviewEntry,
      },
    });

    const worker = await Worker.findById(booking.workerId);

    if (!worker) {
      return res.status(404).json({
        success: false,
        message: "Worker not found",
      });
    }

    const totalRating = worker.reviews.reduce((sum, review) => sum + review.rating, 0);
    const reviewCount = worker.reviews.length;

    worker.rating = reviewCount ? totalRating / reviewCount : 0;
    worker.ratingCount = reviewCount;
    worker.ratingSum = totalRating;

    await worker.save();

    return res.status(200).json({
      success: true,
      message: "Rating submitted successfully",
      data: {
        booking: updatedBooking,
        worker: {
          _id: worker._id,
          rating: worker.rating,
          ratingCount: worker.ratingCount,
        },
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to submit rating",
      error: error.message,
    });
  }
};
