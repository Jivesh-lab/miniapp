import express from "express";
import {
  createBooking,
  getBookings,
  updateBookingStatus,
} from "../controllers/booking.controller.js";

const router = express.Router();

const deleteBooking = async (req, res) => {
  return res.status(501).json({
    success: false,
    message: "deleteBooking controller not implemented",
  });
};

// POST /api/bookings
router.post("/", createBooking);

// GET /api/bookings/:userId
router.get("/:userId", getBookings);

// PATCH /api/bookings/:id
router.patch("/:id", updateBookingStatus);

// DELETE /api/bookings/:id
router.delete("/:id", deleteBooking);

export default router;
