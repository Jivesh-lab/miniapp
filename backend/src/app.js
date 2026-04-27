import express from "express";
import cors from "cors";
import workerRoutes from "./routes/worker.routes.js";
import bookingRoutes from "./routes/booking.routes.js";
import serviceRoutes from "./routes/service.routes.js";
import userRoutes from "./routes/user.routes.js";
import authRoutes from "./routes/auth.routes.js";
import geocodingRoutes from "./routes/geocoding.routes.js";
import locationRoutes from "./routes/location.routes.js";
import { login, registerUser } from "./controllers/auth.controller.js";
import { getServices } from "./controllers/service.controller.js";
import { getUserProfile } from "./controllers/user.controller.js";
import { authMiddleware, authorizeRoles } from "./middleware/auth.middleware.js";
import { errorHandler, notFoundHandler } from "./middleware/error.middleware.js";

const app = express();

// CORS Configuration
const allowedOrigins = [
  "http://localhost:3000",
  "http://localhost:8081",
  process.env.FRONTEND_URL || "https://yourdomain.com",
];

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error("Not allowed by CORS"));
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
};

app.use(cors(corsOptions));
app.use(express.json());

// ============================================
// 🏥 HEALTH CHECK ENDPOINT FOR RENDER COLD START
// ============================================
// This endpoint helps Flutter warm up the server on startup
// No authentication required - responds instantly
app.get("/ping", (req, res) => {
  res.status(200).json({
    success: true,
    message: "pong",
    timestamp: new Date().toISOString(),
  });
});

app.post("/api/register", registerUser);
app.post("/api/login", login);
app.get("/api/services", getServices);
app.get("/api/profile", authMiddleware, authorizeRoles("user"), getUserProfile);

app.use("/api/worker", workerRoutes);
app.use("/api/workers", workerRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/services", serviceRoutes);
app.use("/api/users", userRoutes);
app.use("/api/users", locationRoutes);
app.use("/api/auth", authRoutes);
app.use("/", geocodingRoutes);

app.get("/", authMiddleware, authorizeRoles("user", "worker"), (req, res) => {
  res.status(200).json({
    success: true,
    message: "API is running...",
  });
});

app.use(notFoundHandler);
app.use(errorHandler);

export default app;