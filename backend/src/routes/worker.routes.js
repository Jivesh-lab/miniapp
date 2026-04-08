import express from "express";
import {
  getAllWorkers,
  getWorkers,
  getWorkerById,
  searchWorkers,
  getWorkerAvailableSlots,
} from "../controllers/worker.controller.js";

const router = express.Router();

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
