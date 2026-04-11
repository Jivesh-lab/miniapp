const includeInternalError = process.env.NODE_ENV !== "production";

const buildErrorPayload = ({ message, error }) => {
  const payload = {
    success: false,
    message,
  };

  if (includeInternalError && error) {
    payload.error = error.message || String(error);
  }

  return payload;
};

export const sendWorkerError = (res, statusCode, message, error) => {
  return res.status(statusCode).json(buildErrorPayload({ message, error }));
};

export const sendWorkerValidationError = (res, message = "Invalid input. Please check your data.") => {
  return sendWorkerError(res, 400, message);
};

export const sendWorkerNotFound = (res, message = "Worker not found") => {
  return sendWorkerError(res, 404, message);
};

export const handleWorkerException = (
  res,
  error,
  fallbackMessage = "Something went wrong. Please try again."
) => {
  if (error?.code === 11000) {
    return sendWorkerError(res, 400, "Selected slot is not available", error);
  }

  if (error?.name === "ValidationError") {
    return sendWorkerValidationError(res, "Invalid input. Validation failed.");
  }

  if (error?.name === "CastError") {
    return sendWorkerValidationError(res, "Invalid input. Please check IDs and values.");
  }

  return sendWorkerError(res, 500, fallbackMessage, error);
};
