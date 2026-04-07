import express from "express";
import {
  getServices,
  createService,
} from "../controllers/service.controller.js";

const router = express.Router();

// GET /api/services
router.get("/", getServices);

// POST /api/services
router.post("/", createService);

export default router;
