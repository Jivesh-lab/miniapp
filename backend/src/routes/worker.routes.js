import express from "express";
import {
  getAllWorkers,
  getWorkers,
  getWorkerById,
  searchWorkers,
  getWorkerAvailableSlots,
} from "../controllers/worker.controller.js";
import {
  getWorkerProfile,
  getWorkerDashboardBookings,
  updateWorkerProfile,
} from "../controllers/worker.auth.controller.js";
import { authMiddleware, authorizeRoles } from "../middleware/auth.middleware.js";

const router = express.Router();

router.use(authMiddleware);

// GET /api/workers/profile
router.get("/profile", authorizeRoles("worker"), getWorkerProfile);

// PUT /api/workers/profile
router.put("/profile", authorizeRoles("worker"), updateWorkerProfile);

// GET /api/workers/bookings?page=1&limit=10&status=pending
router.get("/bookings", authorizeRoles("worker"), getWorkerDashboardBookings);

// GET /api/workers/search?q=...
router.get("/search", searchWorkers);

// GET /api/workers?page=1&limit=10&sort=rating&order=desc&q=imran&minRating=4&minPrice=100&maxPrice=600
router.get("/", getAllWorkers);

// GET /api/workers/detail/:id
router.get("/detail/:id", getWorkerById);

// GET /api/workers/:id/slots?date=YYYY-MM-DD
router.get("/:id/slots", getWorkerAvailableSlots);

// GET /api/workers/:serviceId?sort=rating|price
router.get("/:serviceId", getWorkers);

export default router;
