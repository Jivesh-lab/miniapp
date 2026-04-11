import express from "express";
import {
  createUser,
  getUserById,
  updateUser,
  getFavoriteWorkers,
  addFavoriteWorker,
  getUserProfile,
} from "../controllers/user.controller.js";
import { loginUser, registerUser } from "../controllers/user.auth.controller.js";
import { authMiddleware, authorizeRoles } from "../middleware/auth.middleware.js";

const router = express.Router();

// POST /api/users/register
router.post("/register", registerUser);

// POST /api/users/login
router.post("/login", loginUser);

router.use(authMiddleware);
router.use(authorizeRoles("user"));

// POST /api/users
router.post("/", createUser);

// GET /api/users/profile
router.get("/profile", getUserProfile);

// GET /api/users/favorites/:userId
router.get("/favorites/:userId", getFavoriteWorkers);

// POST /api/users/favorites
router.post("/favorites", addFavoriteWorker);

// GET /api/users/:id
router.get("/:id", getUserById);

// PUT /api/users/:id
router.put("/:id", updateUser);

export default router;
