import jwt from "jsonwebtoken";
import Blacklist from "../models/blacklist.model.js";

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

  console.log("TOKEN:", token);

  if (!token) {
    return res.status(401).json({ message: "No token, unauthorized" });
  }

  try {
    const blacklisted = await Blacklist.findOne({ token }).lean();

    if (blacklisted) {
      return res.status(401).json({ message: "Token expired, login again" });
    }

    const decoded = jwt.verify(token, JWT_SECRET);

    console.log("DECODED:", decoded);

    if (!decoded?.id || !decoded?.role) {
      return res.status(401).json({ message: "Invalid token" });
    }

    const normalizedId = String(decoded.id);
    const normalizedRole = String(decoded.role);

    req.user = {
      ...decoded,
      id: normalizedId,
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
      return res.status(401).json({ message: "Token expired, login again" });
    }

    console.log("DECODED:", "invalid token");
    return res.status(401).json({ message: "Invalid token" });
  }
};

export const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user?.role || !roles.includes(req.user.role)) {
      return res.status(403).json({ message: "Forbidden" });
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
      return res.status(401).json({ message: "Unauthorized" });
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
      return res.status(401).json({ message: "Unauthorized" });
    }

    return next();
  });
};
