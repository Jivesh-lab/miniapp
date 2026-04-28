import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "dev_worker_jwt_secret";

const extractToken = (req) => {
  const authHeader = req.headers.authorization || "";

  if (!authHeader.startsWith("Bearer ")) {
    return null;
  }

  const token = authHeader.split(" ")[1]?.trim();
  return token || null;
};

export const authMiddleware = async (req, res, next) => {
  const token = extractToken(req);

  if (!token) {
    return res.status(401).json({
      success: false,
      message: "No token, unauthorized",
    });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const tokenUserId = decoded?.userId ?? decoded?.id;

    if (!tokenUserId || !decoded?.role) {
      return res.status(403).json({
        success: false,
        message: "Invalid token",
      });
    }

    const normalizedId = String(tokenUserId);
    const normalizedRole = String(decoded.role);

    req.user = {
      ...decoded,
      id: normalizedId,
      userId: normalizedId,
      role: normalizedRole,
    };

    if (normalizedRole === "worker") {
      req.worker = {
        workerId: normalizedId,
        role: normalizedRole,
      };
    }

    return next();
  } catch (error) {
    if (error?.name === "TokenExpiredError") {
      return res.status(401).json({
        success: false,
        message: "Token expired, login again",
      });
    }

    return res.status(403).json({
      success: false,
      message: "Invalid token",
    });
  }
};

export const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user?.role || !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: "Forbidden",
      });
    }

    return next();
  };
};

export const protectWorker = (req, res, next) => {
  return authMiddleware(req, res, (error) => {
    if (error) {
      return next(error);
    }

    if (req.user?.role !== "worker") {
      return res.status(403).json({
        success: false,
        message: "Forbidden",
      });
    }

    return next();
  });
};

export const protectUser = (req, res, next) => {
  return authMiddleware(req, res, (error) => {
    if (error) {
      return next(error);
    }

    if (req.user?.role !== "user") {
      return res.status(403).json({
        success: false,
        message: "Forbidden",
      });
    }

    return next();
  });
};
