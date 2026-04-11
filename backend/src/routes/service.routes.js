import express from "express";
import {
  getServices,
  createService,
} from "../controllers/service.controller.js";
import { authMiddleware, authorizeRoles } from "../middleware/auth.middleware.js";

const router = express.Router();

router.use(authMiddleware);
router.use(authorizeRoles("user", "worker"));

// GET /api/services
router.get("/", getServices);

// POST /api/services
router.post("/", createService);

export default router;
