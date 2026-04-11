import express from "express";
import {
  createBooking,
  getUserBookings,
  updateBookingStatus,
  cancelBooking,
  rateBooking,
} from "../controllers/booking.controller.js";

import { authMiddleware, authorizeRoles } from "../middleware/auth.middleware.js";

const router = express.Router();

router.use(authMiddleware);

// ✅ CREATE BOOKING
// POST /api/bookings
router.post("/", authorizeRoles("user"), createBooking);


// ✅ UPDATE BOOKING STATUS (Worker only)
// PATCH /api/bookings/:id
router.patch("/:id", authorizeRoles("worker"), updateBookingStatus);


// ✅ GET BOOKINGS BY USER
// GET /api/bookings/user
router.get("/user", authorizeRoles("user"), getUserBookings);


// ✅ CANCEL BOOKING (User only)
// PATCH /api/bookings/cancel/:id
router.patch("/cancel/:id", authorizeRoles("user"), cancelBooking);

// ✅ RATE BOOKING (User only)
// POST /api/bookings/rate/:id
router.post("/rate/:id", authorizeRoles("user"), rateBooking);


export default router;