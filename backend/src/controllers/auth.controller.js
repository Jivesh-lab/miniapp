import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

import User from "../models/user.model.js";
import Worker from "../models/worker.model.js";
import { isStrongEnoughPassword, isValidEmail, isValidPhone } from "../utils/validators.js";

const JWT_SECRET = process.env.JWT_SECRET || "dev_worker_jwt_secret";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";

const normalizePhone = (phone) => String(phone || "").trim();
const normalizeEmail = (email) => String(email || "").trim().toLowerCase();
const normalizeName = (name) => String(name || "").trim();

const isEmailIdentifier = (identifier) => String(identifier).includes("@");

const signToken = (id, role) => {
  try {
    return jwt.sign({ userId: id, role }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
  } catch (error) {
    throw new Error(`Failed to generate token: ${error.message}`);
  }
};

const serializeUser = (user) => ({
  _id: user._id,
  id: user._id,
  userId: user._id,
  name: user.name,
  email: user.email,
  phone: user.phone,
  role: user.role,
  favoriteWorkers: user.favoriteWorkers ?? [],
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

const serializeWorker = (worker) => ({
  _id: worker._id,
  id: worker._id,
  workerId: worker._id,
  name: worker.name,
  phone: worker.phone,
  role: worker.role,
  serviceId: worker.serviceId ?? null,
  price: worker.price ?? 0,
  location: worker.location ?? "",
  skills: worker.skills ?? [],
  profileComplete: Boolean(worker.serviceId && String(worker.location || "").trim() && Number(worker.price) > 0),
  createdAt: worker.createdAt,
  updatedAt: worker.updatedAt,
});

const sendValidationError = (res, message) => {
  return res.status(400).json({
    success: false,
    message,
  });
};

const sendNotFoundError = (res, message) => {
  return res.status(404).json({
    success: false,
    message,
  });
};

const sendConflictError = (res, message) => {
  return res.status(409).json({
    success: false,
    message,
  });
};

const isProfileComplete = (worker) => {
  return Boolean(worker.serviceId && String(worker.location || "").trim() && Number(worker.price) > 0);
};

export const registerUser = async (req, res) => {
  try {
    const { name, phone, email, password } = req.body ?? {};

    if (!name || !phone || !email || !password) {
      return sendValidationError(res, "name, phone, email, and password are required");
    }

    const normalizedPhone = normalizePhone(phone);
    const normalizedEmail = normalizeEmail(email);
    const normalizedName = normalizeName(name);

    if (!normalizedName) {
      return sendValidationError(res, "name is required");
    }

    if (!isValidPhone(normalizedPhone)) {
      return sendValidationError(res, "Invalid phone format");
    }

    if (!normalizedEmail || !isValidEmail(normalizedEmail)) {
      return sendValidationError(res, "Invalid email format");
    }

    if (!isStrongEnoughPassword(password)) {
      return sendValidationError(res, "Password must be at least 6 characters");
    }

    const [existingUserByPhone, existingUserByEmail, existingWorkerByPhone] = await Promise.all([
      User.findOne({ phone: normalizedPhone }).lean(),
      User.findOne({ email: normalizedEmail }).lean(),
      Worker.findOne({ phone: normalizedPhone }).lean(),
    ]);

    if (existingUserByPhone || existingWorkerByPhone) {
      return sendConflictError(res, "User with this phone already exists");
    }

    if (existingUserByEmail) {
      return sendConflictError(res, "User with this email already exists");
    }

    const passwordHash = await bcrypt.hash(String(password), 10);

    const user = await User.create({
      name: normalizedName,
      phone: normalizedPhone,
      email: normalizedEmail,
      password: passwordHash,
      role: "user",
    });

    return res.status(201).json({
      success: true,
      message: "User registered successfully",
      data: serializeUser(user.toObject()),
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to register user",
      error: error.message,
    });
  }
};

export const registerWorker = async (req, res) => {
  try {
    const { name, phone, password } = req.body ?? {};

    if (!name || !phone || !password) {
      return sendValidationError(res, "name, phone, and password are required");
    }

    const normalizedPhone = normalizePhone(phone);
    const normalizedName = normalizeName(name);

    if (!normalizedName) {
      return sendValidationError(res, "name is required");
    }

    if (!isValidPhone(normalizedPhone)) {
      return sendValidationError(res, "Invalid phone format");
    }

    if (!isStrongEnoughPassword(password)) {
      return sendValidationError(res, "Password must be at least 6 characters");
    }

    const [existingWorker, existingUser] = await Promise.all([
      Worker.findOne({ phone: normalizedPhone }).lean(),
      User.findOne({ phone: normalizedPhone }).lean(),
    ]);

    if (existingWorker || existingUser) {
      return sendConflictError(res, "Worker with this phone already exists");
    }

    const passwordHash = await bcrypt.hash(String(password), 10);

    const worker = await Worker.create({
      name: normalizedName,
      phone: normalizedPhone,
      password: passwordHash,
      role: "worker",
    });

    return res.status(201).json({
      success: true,
      message: "Worker registered successfully",
      data: serializeWorker(worker.toObject()),
    });
  } catch (error) {
    if (error?.code === 11000) {
      return sendConflictError(res, "Duplicate phone number");
    }

    return res.status(500).json({
      success: false,
      message: "Failed to register worker",
      error: error.message,
    });
  }
};

export const login = async (req, res) => {
  try {
    const { phone, identifier, emailOrPhone, password, role } = req.body ?? {};
    const loginValue = String(phone || identifier || emailOrPhone || "").trim();
    const requestedRole = String(role || "").trim().toLowerCase();

    if (!loginValue || !password) {
      return sendValidationError(res, "phone or email and password are required");
    }

    if (requestedRole && !["user", "worker"].includes(requestedRole)) {
      return sendValidationError(res, "role must be either user or worker");
    }

    const loginAsEmail = isEmailIdentifier(loginValue);

    if (loginAsEmail) {
      if (!isValidEmail(loginValue)) {
        return sendValidationError(res, "Invalid email format");
      }

      if (requestedRole === "worker") {
        return sendValidationError(res, "Worker login requires a phone number");
      }
    } else if (!isValidPhone(loginValue)) {
      return sendValidationError(res, "Invalid phone format");
    }

    const allowWorkerLogin = !requestedRole || requestedRole === "worker";

    if (!loginAsEmail && allowWorkerLogin) {
      const worker = await Worker.findOne({ phone: loginValue }).select("+password");

      if (worker) {
        const isMatch = await bcrypt.compare(String(password), worker.password || "");

        if (!isMatch) {
          return res.status(401).json({
            success: false,
            message: "Invalid credentials",
          });
        }

        const token = signToken(worker._id.toString(), "worker");

        return res.status(200).json({
          success: true,
          message: "Login successful",
          token,
          role: "worker",
          profileComplete: isProfileComplete(worker),
          id: worker._id,
          data: {
            ...serializeWorker(worker.toObject()),
            token,
            role: "worker",
          },
        });
      }
    }

    if (requestedRole === "worker") {
      return res.status(401).json({
        success: false,
        message: "Invalid credentials",
      });
    }

    const userQuery = loginAsEmail
      ? { email: loginValue.toLowerCase() }
      : { $or: [{ phone: loginValue }, { userId: loginValue }] };

    const user = await User.findOne(userQuery).select("+password");

    if (!user) {
      return sendNotFoundError(res, "User not found");
    }

    const isMatch = await bcrypt.compare(String(password), user.password || "");

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Invalid credentials",
      });
    }

    const token = signToken(user._id.toString(), "user");

    return res.status(200).json({
      success: true,
      message: "Login successful",
      token,
      role: "user",
      id: user._id,
      data: {
        ...serializeUser(user.toObject()),
        token,
        role: "user",
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to login",
      error: error.message,
    });
  }
};

export const verifyLoginOtp = async (_req, res) => {
  return res.status(501).json({
    success: false,
    message: "Login OTP verification is not implemented",
  });
};

export const logout = async (req, res) => {
  try {
    const authHeader = req.headers.authorization || "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.split(" ")[1]?.trim() : "";

    if (!token) {
      return res.status(401).json({ message: "No token, unauthorized" });
    }

    return res.status(200).json({
      success: true,
      message: "Logged out successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to logout",
      error: error.message,
    });
  }
};