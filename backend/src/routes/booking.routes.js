import express from "express";
import {
  createBooking,
  getBookings,
  updateBookingStatus,
  deleteBooking,
  rateBooking,
} from "../controllers/booking.controller.js";

const router = express.Router();

// POST /api/bookings
router.post("/", createBooking);

// GET /api/bookings/:userId
router.get("/:userId", getBookings);

// PATCH /api/bookings/:id
router.patch("/:id", updateBookingStatus);

// POST /api/bookings/:id/rate
router.post("/:id/rate", rateBooking);

// DELETE /api/bookings/:id
router.delete("/:id", deleteBooking);

export default router;
