import express from "express";
import { authMiddleware } from "../middleware/auth.middleware.js";
import {
	login,
	logout,
	registerUser,
	registerWorker,
	verifyLoginOtp,
} from "../controllers/auth.controller.js";

const router = express.Router();

router.post("/register-user", registerUser);
router.post("/register-worker", registerWorker);
router.post("/login", login);
router.post("/verify-login-otp", verifyLoginOtp);
router.post("/logout", authMiddleware, logout);

export default router;