import Booking from "../models/booking.model.js";
import Worker from "../models/worker.model.js";

const allowedTransitions = {
  pending: ["confirmed", "cancelled"],
  confirmed: ["completed"],
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

    if (!status || !["pending", "confirmed", "completed", "cancelled"].includes(status)) {
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
