import express from "express";
import {
  getWorkers,
  getWorkerById,
} from "../controllers/worker.controller.js";

const router = express.Router();

const searchWorkers = async (req, res) => {
  return res.status(501).json({
    success: false,
    message: "searchWorkers controller not implemented",
  });
};

// GET /api/workers/search?q=...
router.get("/search", searchWorkers);

// GET /api/workers/detail/:id
router.get("/detail/:id", getWorkerById);

// GET /api/workers/:serviceId?sort=rating|price
router.get("/:serviceId", getWorkers);

export default router;
