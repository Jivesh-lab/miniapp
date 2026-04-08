import express from "express";
import {
  createUser,
  getUserById,
  updateUser,
  getFavoriteWorkers,
  addFavoriteWorker,
} from "../controllers/user.controller.js";

const router = express.Router();

// POST /api/users
router.post("/", createUser);

// GET /api/users/favorites/:userId
router.get("/favorites/:userId", getFavoriteWorkers);

// POST /api/users/favorites
router.post("/favorites", addFavoriteWorker);

// GET /api/users/:id
router.get("/:id", getUserById);

// PUT /api/users/:id
router.put("/:id", updateUser);

export default router;
