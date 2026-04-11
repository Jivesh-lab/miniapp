import express from "express";
import cors from "cors";
import workerRoutes from "./routes/worker.routes.js";
import bookingRoutes from "./routes/booking.routes.js";
import serviceRoutes from "./routes/service.routes.js";
import userRoutes from "./routes/user.routes.js";
import authRoutes from "./routes/auth.routes.js";
import { authMiddleware, authorizeRoles } from "./middleware/auth.middleware.js";
import { errorHandler, notFoundHandler } from "./middleware/error.middleware.js";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/worker", workerRoutes);
app.use("/api/workers", workerRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/services", serviceRoutes);
app.use("/api/users", userRoutes);
app.use("/api/auth", authRoutes);

app.get("/", authMiddleware, authorizeRoles("user", "worker"), (req, res) => {
  res.status(200).json({
    success: true,
    message: "API is running...",
  });
});

app.use(notFoundHandler);
app.use(errorHandler);

export default app;