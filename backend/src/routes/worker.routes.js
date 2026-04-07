import express from "express";
import {
  getWorkers,
  getWorkerById
} from "../controllers/worker.controller.js";

const router = express.Router();

// GET workers by service + sorting
router.get("/:serviceId", getWorkers);

// GET single worker
router.get("/detail/:id", getWorkerById);

export default router;
