import express from "express";
import cors from "cors";
import workerRoutes from "./routes/worker.routes.js";
import bookingRoutes from "./routes/booking.routes.js";
import serviceRoutes from "./routes/service.routes.js";
import userRoutes from "./routes/user.routes.js";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/workers", workerRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/services", serviceRoutes);
app.use("/api/users", userRoutes);

app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "API is running...",
  });
});

app.use((req, res, next) => {
  const error = new Error("Route not found");
  error.statusCode = 404;
  next(error);
});

app.use((err, req, res, next) => {
  const statusCode = err.statusCode || 500;

  res.status(statusCode).json({
    success: false,
    message: err.message || "Internal server error",
  });
});

export default app;