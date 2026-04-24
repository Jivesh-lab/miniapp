import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

import Worker from "../models/worker.model.js";
import Booking from "../models/booking.model.js";
import Service from "../models/service.model.js";
import { isStrongEnoughPassword, isValidObjectId, isValidPhone, parsePagination } from "../utils/validators.js";
import {
  handleWorkerException,
  sendWorkerError,
  sendWorkerNotFound,
  sendWorkerValidationError,
} from "../utils/worker-error.util.js";
import { isValidCoordinates } from "../utils/distance.util.js";

const JWT_SECRET = process.env.JWT_SECRET || "dev_worker_jwt_secret";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";

const signWorkerToken = (workerId) => {
  return jwt.sign({ id: workerId, role: "worker" }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
};

const isProfileComplete = (worker) => {
  return Boolean(worker.serviceId && String(worker.location || "").trim() && Number(worker.price) > 0);
};

export const registerWorker = async (req, res) => {
  try {
    const { name, phone, password, serviceId, skills, location, price } = req.body;
    const normalizedName = String(name || "").trim();
    const normalizedPhone = String(phone || "").trim();

    if (!normalizedName || !normalizedPhone || !password || !serviceId || location === undefined || price === undefined) {
      return sendWorkerValidationError(
        res,
        "name, phone, password, serviceId, location, and price are required"
      );
    }

    if (!isValidPhone(normalizedPhone)) {
      return sendWorkerValidationError(res, "Invalid phone format");
    }

    if (!isStrongEnoughPassword(password)) {
      return sendWorkerValidationError(res, "Password must be at least 6 characters");
    }

    if (!isValidObjectId(serviceId)) {
      return sendWorkerValidationError(res, "serviceId must be a valid ObjectId");
    }

    const existing = await Worker.findOne({ phone: normalizedPhone }).lean();

    if (existing) {
      return sendWorkerValidationError(res, "Worker with this phone already exists");
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const worker = await Worker.create({
      name: normalizedName,
      phone: normalizedPhone,
      password: hashedPassword,
      serviceId,
      skills: Array.isArray(skills) ? skills : [],
      location,
      price,
      rating: 0,
      reviews: [],
      role: "worker",
    });

    return res.status(201).json({
      success: true,
      message: "Worker registered successfully",
      data: {
        _id: worker._id,
        id: worker._id,
        workerId: worker._id,
        name: worker.name,
        phone: worker.phone,
        serviceId: worker.serviceId,
        role: worker.role,
      },
    });
  } catch (error) {
    return handleWorkerException(res, error, "Failed to register worker");
  }
};

export const loginWorker = async (req, res) => {
  try {
    const { phone, password, identifier, emailOrPhone } = req.body ?? {};
    const loginValue = String(phone || identifier || emailOrPhone || "").trim();

    if (!loginValue || !password) {
      return sendWorkerValidationError(res, "phone and password are required");
    }

    if (!isValidPhone(loginValue)) {
      return sendWorkerValidationError(res, "Invalid phone format");
    }

    const worker = await Worker.findOne({ phone: loginValue }).select("+password");

    if (!worker) {
      return sendWorkerError(res, 401, "Invalid credentials");
    }

    const isMatch = await bcrypt.compare(password, worker.password);

    if (!isMatch) {
      return sendWorkerError(res, 401, "Invalid credentials");
    }

    const token = signWorkerToken(worker._id.toString());

    return res.status(200).json({
      success: true,
      message: "Login successful",
      data: {
        id: worker._id,
        workerId: worker._id,
        token,
        role: worker.role,
      },
    });
  } catch (error) {
    return handleWorkerException(res, error, "Failed to login worker");
  }
};

export const getWorkerProfile = async (req, res) => {
  try {
    const { workerId } = req.worker;

    const worker = await Worker.findById(workerId)
      .select("name phone serviceId skills location price rating reviews role createdAt")
      .lean();

    if (!worker) {
      return sendWorkerNotFound(res, "Worker not found");
    }

    return res.status(200).json({
      success: true,
      data: worker,
      profileComplete: isProfileComplete(worker),
    });
  } catch (error) {
    return handleWorkerException(res, error, "Failed to fetch worker profile");
  }
};

  export const updateWorkerProfile = async (req, res) => {
    try {
      const workerId = req.worker?.workerId || req.user?.id;
      const { serviceId, price, location, skills } = req.body ?? {};

      if (!workerId) {
        return sendWorkerError(res, 401, "Unauthorized");
      }

      if (!serviceId || price === undefined || location === undefined) {
        return sendWorkerValidationError(res, "serviceId, price, and location are required");
      }

      if (!isValidObjectId(serviceId)) {
        return sendWorkerValidationError(res, "serviceId must be a valid ObjectId");
      }

      const parsedPrice = Number(price);
      if (!Number.isFinite(parsedPrice) || parsedPrice < 0) {
        return sendWorkerValidationError(res, "price must be a valid number");
      }

      const normalizedLocation = String(location).trim();
      if (!normalizedLocation) {
        return sendWorkerValidationError(res, "location is required");
      }

      const normalizedSkills = Array.isArray(skills)
        ? skills.map((skill) => String(skill).trim()).filter(Boolean)
        : String(skills || "")
            .split(",")
            .map((skill) => skill.trim())
            .filter(Boolean);

      const serviceExists = await Service.findById(serviceId).select("_id").lean();
      if (!serviceExists) {
        return sendWorkerValidationError(res, "Invalid serviceId");
      }

      const worker = await Worker.findByIdAndUpdate(
        workerId,
        {
          serviceId,
          price: parsedPrice,
          location: normalizedLocation,
          skills: normalizedSkills,
        },
        { new: true, runValidators: true }
      )
        .select("name phone serviceId skills location price rating reviews role createdAt updatedAt")
        .lean();

      if (!worker) {
        return sendWorkerNotFound(res, "Worker not found");
      }

      return res.status(200).json({
        success: true,
        message: "Worker profile updated successfully",
        data: worker,
        profileComplete: isProfileComplete(worker),
      });
    } catch (error) {
      return handleWorkerException(res, error, "Failed to update worker profile");
    }
  };

export const getWorkerDashboardBookings = async (req, res) => {
  try {
    const { workerId } = req.worker;
    const { status } = req.query;
    const { page, limit, skip } = parsePagination(req.query);

    const query = { workerId };

    if (status) {
      query.status = status;
    }

    const [bookings, total] = await Promise.all([
      Booking.find(query)
        .select("userId workerId date time address status createdAt")
        .populate("userId", "name phone email")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Booking.countDocuments(query),
    ]);

    return res.status(200).json({
      success: true,
      count: bookings.length,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      data: bookings,
    });
  } catch (error) {
    return handleWorkerException(res, error, "Failed to fetch worker bookings");
  }
};

export const updateWorkerLocation = async (req, res) => {
  try {
    const { workerId } = req.worker;
    const { latitude, longitude, isOnline } = req.body ?? {};

    if (!workerId) {
      return sendWorkerError(res, 401, "Unauthorized");
    }

    if (latitude === undefined || longitude === undefined) {
      return sendWorkerValidationError(res, "latitude and longitude are required");
    }

    const lat = Number(latitude);
    const lng = Number(longitude);

    if (!isValidCoordinates(lat, lng)) {
      return sendWorkerValidationError(res, "Invalid latitude or longitude coordinates");
    }

    const worker = await Worker.findByIdAndUpdate(
      workerId,
      {
        latitude: lat,
        longitude: lng,
        isOnline: typeof isOnline === "boolean" ? isOnline : true,
        lastLocationUpdate: new Date(),
      },
      { new: true, runValidators: true }
    )
      .select("name phone latitude longitude isOnline lastLocationUpdate")
      .lean();

    if (!worker) {
      return sendWorkerNotFound(res, "Worker not found");
    }

    return res.status(200).json({
      success: true,
      message: "Location updated successfully",
      data: worker,
    });
  } catch (error) {
    return handleWorkerException(res, error, "Failed to update worker location");
  }
};
