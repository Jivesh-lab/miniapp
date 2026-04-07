import Booking from "../models/booking.model.js";

export const createBooking = async (req, res) => {
  try {
    const { userId, workerId, date, time, address } = req.body;

    if (!userId || !workerId || !date || !time || !address) {
      return res.status(400).json({
        success: false,
        message: "userId, workerId, date, time, and address are required",
      });
    }

    const booking = await Booking.create({
      userId,
      workerId,
      date,
      time,
      address,
    });

    return res.status(201).json({
      success: true,
      message: "Booking created successfully",
      data: booking,
    });
  } catch (error) {
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

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required",
      });
    }

    const bookings = await Booking.find({ userId })
      .populate("workerId")
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json({
      success: true,
      count: bookings.length,
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

    if (!status || !["ongoing", "completed"].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "status must be either ongoing or completed",
      });
    }

    const booking = await Booking.findByIdAndUpdate(
      id,
      { status },
      { new: true, runValidators: true }
    ).populate("workerId");

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: "Booking not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Booking status updated successfully",
      data: booking,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update booking status",
      error: error.message,
    });
  }
};
