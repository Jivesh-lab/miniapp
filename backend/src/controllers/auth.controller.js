import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

import User from "../models/user.model.js";
import Worker from "../models/worker.model.js";
import EmailOtp from "../models/emailOtp.model.js";
import { sendOtpEmail } from "../utils/email.util.js";
import crypto from "crypto";
import { isStrongEnoughPassword, isValidEmail, isValidPhone } from "../utils/validators.js";

const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();
const hashOtp = (otp) => crypto.createHash("sha256").update(otp).digest("hex");

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

    const otp = generateOtp();
    await EmailOtp.deleteMany({ email: normalizedEmail, purpose: "register" });
    await EmailOtp.create({
      email: normalizedEmail,
      purpose: "register",
      userId: user._id,
      otpHash: hashOtp(otp),
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    });

    await sendOtpEmail(user.email, otp);

    return res.status(201).json({
      success: true,
      message: "OTP sent to your email",
      requires_otp: true,
      identifier: normalizedEmail,
      role: "user",
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

    const otp = generateOtp();
    console.log(`MOCK SMS OTP for ${worker.phone}: ${otp}`);
    
    await EmailOtp.deleteMany({ email: worker.phone, purpose: "register" });
    await EmailOtp.create({
      email: worker.phone,
      purpose: "register",
      userId: worker._id,
      otpHash: hashOtp(otp),
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    });

    return res.status(201).json({
      success: true,
      message: "OTP sent to your phone",
      requires_otp: true,
      identifier: worker.phone,
      role: "worker",
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

export const verifyLoginOtp = async (req, res) => {
  try {
    const { identifier, otp, role } = req.body ?? {};

    if (!identifier || !otp || !role) {
      return sendValidationError(res, "identifier, otp, and role are required");
    }

    const otpRecord = await EmailOtp.findOne({ 
      email: String(identifier).toLowerCase(), 
      purpose: "register" 
    }).select("+otpHash");

    if (!otpRecord) {
      return res.status(400).json({ success: false, message: "Invalid or expired OTP" });
    }

    if (otpRecord.expiresAt < new Date()) {
      await EmailOtp.deleteOne({ _id: otpRecord._id });
      return res.status(400).json({ success: false, message: "OTP expired" });
    }

    if (otpRecord.otpHash !== hashOtp(String(otp))) {
      return res.status(400).json({ success: false, message: "Invalid OTP" });
    }

    await EmailOtp.deleteOne({ _id: otpRecord._id });

    const token = signToken(otpRecord.userId.toString(), role);

    if (role === "worker") {
      const worker = await Worker.findById(otpRecord.userId).lean();
      return res.status(200).json({
        success: true,
        message: "Login successful",
        token,
        role: "worker",
        profileComplete: isProfileComplete(worker),
        id: worker._id,
        data: {
          ...serializeWorker(worker),
          token,
          role: "worker",
        },
      });
    } else {
      const user = await User.findById(otpRecord.userId).lean();
      return res.status(200).json({
        success: true,
        message: "Login successful",
        token,
        role: "user",
        id: user._id,
        data: {
          ...serializeUser(user),
          token,
          role: "user",
        },
      });
    }
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to verify OTP",
      error: error.message,
    });
  }
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