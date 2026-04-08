import mongoose from "mongoose";

export const notFoundHandler = (req, res, next) => {
  const error = new Error("Route not found");
  error.statusCode = 404;
  next(error);
};

export const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || "Internal server error";

  if (err instanceof mongoose.Error.CastError) {
    statusCode = 400;
    message = `Invalid ${err.path}`;
  }

  if (err instanceof mongoose.Error.ValidationError) {
    statusCode = 400;
    const messages = Object.values(err.errors || {}).map((e) => e.message);
    message = messages.length ? messages.join(", ") : "Validation failed";
  }

  // Duplicate key error from MongoDB
  if (err && err.code === 11000) {
    statusCode = 409;
    message = "Duplicate resource";
  }

  if (statusCode >= 500) {
    console.error("Unhandled API error:", err);
  }

  res.status(statusCode).json({
    success: false,
    message,
  });
};
