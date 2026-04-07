import express from "express";
import {
  createUser,
  getUserById,
} from "../controllers/user.controller.js";

const router = express.Router();

const updateUser = async (req, res) => {
  return res.status(501).json({
    success: false,
    message: "updateUser controller not implemented",
  });
};

const getFavoriteWorkers = async (req, res) => {
  return res.status(501).json({
    success: false,
    message: "getFavoriteWorkers controller not implemented",
  });
};

const addFavoriteWorker = async (req, res) => {
  return res.status(501).json({
    success: false,
    message: "addFavoriteWorker controller not implemented",
  });
};

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
