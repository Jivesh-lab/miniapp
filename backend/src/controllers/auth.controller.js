import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

import User from "../models/user.model.js";
import Worker from "../models/worker.model.js";
import EmailOtp from "../models/emailOtp.model.js";
import Blacklist from "../models/blacklist.model.js";
import { sendOtpEmail } from "../utils/email.util.js";
import crypto from "crypto";
import { isStrongEnoughPassword, isValidEmail, isValidPhone } from "../utils/validators.js";

const MAX_OTP_ATTEMPTS = 5;

const generateOtp = () => crypto.randomInt(100000, 1000000).toString();
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
  let createdUser = null;

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

    createdUser = await User.create({
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
      userId: createdUser._id,
      otpHash: hashOtp(otp),
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    });

    await sendOtpEmail(createdUser.email, otp);

    return res.status(201).json({
      success: true,
      message: "OTP sent to your email",
      requires_otp: true,
      identifier: normalizedEmail,
      role: "user",
    });
  } catch (error) {
    if (createdUser?._id) {
      await Promise.allSettled([
        EmailOtp.deleteMany({ email: normalizeEmail(req.body?.email), purpose: "register" }),
        User.deleteOne({ _id: createdUser._id }),
      ]);
    }

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
      message: "Worker account created successfully",
      requires_otp: false,
      role: "worker",
      id: worker._id,
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

export const verifyLoginOtp = async (req, res) => {
  try {
    const { identifier, otp } = req.body ?? {};

    if (!identifier || !otp) {
      return sendValidationError(res, "identifier and otp are required");
    }

    // OTPs are only issued for user registration, so the role is never taken from the client.
    const role = "user";

    const otpRecord = await EmailOtp.findOne({
      email: normalizeEmail(identifier),
      purpose: "register",
    })
      .sort({ createdAt: -1 })
      .select("+otpHash");

    if (!otpRecord) {
      return res.status(400).json({ success: false, message: "Invalid or expired OTP" });
    }

    if (otpRecord.expiresAt < new Date()) {
      await EmailOtp.deleteOne({ _id: otpRecord._id });
      return res.status(400).json({ success: false, message: "OTP expired" });
    }

    if (otpRecord.attempts >= MAX_OTP_ATTEMPTS) {
      await EmailOtp.deleteOne({ _id: otpRecord._id });
      return res.status(429).json({ success: false, message: "Too many attempts. Please register again." });
    }

    const submittedHash = Buffer.from(hashOtp(String(otp).trim()));
    const storedHash = Buffer.from(otpRecord.otpHash);
    const otpMatches =
      submittedHash.length === storedHash.length && crypto.timingSafeEqual(submittedHash, storedHash);

    if (!otpMatches) {
      await EmailOtp.updateOne({ _id: otpRecord._id }, { $inc: { attempts: 1 } });
      return res.status(400).json({ success: false, message: "Invalid OTP" });
    }

    await EmailOtp.deleteOne({ _id: otpRecord._id });

    const token = signToken(otpRecord.userId.toString(), role);

    const user = await User.findById(otpRecord.userId).lean();
    if (!user) {
      return sendNotFoundError(res, "User not found");
    }
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

    const expSeconds = Number(req.user?.exp);
    const expiresAt = Number.isFinite(expSeconds)
      ? new Date(expSeconds * 1000)
      : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await Blacklist.updateOne({ token }, { $setOnInsert: { token, expiresAt } }, { upsert: true });

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