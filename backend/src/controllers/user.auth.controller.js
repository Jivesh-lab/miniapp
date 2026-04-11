import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

import User from "../models/user.model.js";

const JWT_SECRET = process.env.JWT_SECRET || "dev_worker_jwt_secret";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";

const normalizePhone = (phone) => String(phone || "").trim();

const isValidPhone = (phone) => /^[0-9]{10,15}$/.test(normalizePhone(phone));

const signUserToken = (userId) => {
  return jwt.sign({ id: userId, role: "user" }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
};

const serializeUser = (user) => ({
  _id: user._id,
  id: user._id,
  name: user.name,
  email: user.email,
  phone: user.phone,
  role: user.role,
  favoriteWorkers: user.favoriteWorkers ?? [],
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

export const registerUser = async (req, res) => {
  try {
    const { name, phone, password, email } = req.body ?? {};

    if (!name || !phone || !password) {
      return res.status(400).json({
        success: false,
        message: "name, phone, and password are required",
      });
    }

    if (!isValidPhone(phone)) {
      return res.status(400).json({
        success: false,
        message: "Invalid phone format",
      });
    }

    if (String(password).trim().length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 6 characters",
      });
    }

    const normalizedPhone = normalizePhone(phone);
    const normalizedEmail = String(email || "").trim().toLowerCase();
    const safeEmail = normalizedEmail || `${normalizedPhone}@local.user`;

    const existingUser = await User.findOne({
      $or: [{ phone: normalizedPhone }, { email: safeEmail }],
    }).lean();

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: existingUser.phone === normalizedPhone
          ? "User with this phone already exists"
          : "User with this email already exists",
      });
    }

    const passwordHash = await bcrypt.hash(String(password), 10);

    const user = await User.create({
      name: String(name).trim(),
      phone: normalizedPhone,
      email: safeEmail,
      password: passwordHash,
      role: "user",
    });

    return res.status(201).json({
      success: true,
      message: "User registered successfully",
      data: serializeUser(user.toObject()),
    });
  } catch (error) {
    if (error?.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Duplicate phone or email",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to register user",
      error: error.message,
    });
  }
};

export const loginUser = async (req, res) => {
  try {
    const { phone, password, emailOrPhone } = req.body ?? {};
    const identifier = String(phone || emailOrPhone || "").trim();

    if (!identifier || !password) {
      return res.status(400).json({
        success: false,
        message: "email or phone and password are required",
      });
    }

    const userQuery = identifier.includes("@")
      ? { email: identifier.toLowerCase() }
      : { $or: [{ phone: identifier }, { userId: identifier }] };

    const user = await User.findOne(userQuery).select("+password").lean();

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "User not found",
      });
    }

    const isPasswordMatch = await bcrypt.compare(String(password), user.password || "");

    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: "Invalid credentials",
      });
    }

    const token = signUserToken(String(user._id));

    return res.status(200).json({
      success: true,
      message: "Login successful",
      data: {
        ...serializeUser(user),
        token,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to login user",
      error: error.message,
    });
  }
};
