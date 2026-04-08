import Worker from "../models/worker.model.js";
import Booking from "../models/booking.model.js";
import mongoose from "mongoose";

const parseOptionalNumber = (value) => {
  if (value === undefined || value === null || value === "") return { value: undefined };

  if (typeof value === "object") {
    return { error: "Invalid query parameter type" };
  }

  const parsed = Number(value);

  if (!Number.isFinite(parsed) || Number.isNaN(parsed)) {
    return { error: "Invalid numeric query parameter" };
  }

  return { value: parsed };
};

const parseOptionalPositiveInt = (value, fallback, max = Number.MAX_SAFE_INTEGER) => {
  if (value === undefined || value === null || value === "") {
    return { value: fallback };
  }

  if (typeof value === "object") {
    return { error: "Invalid query parameter type" };
  }

  const parsed = parseInt(String(value), 10);

  if (!Number.isFinite(parsed) || Number.isNaN(parsed)) {
    return { error: "Invalid integer query parameter" };
  }

  const clamped = Math.min(Math.max(parsed, 1), max);
  return { value: clamped };
};

const parsePagination = (query) => {
  const page = Math.max(parseInt(query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(query.limit, 10) || 10, 1), 50);
  const skip = (page - 1) * limit;
  return { page, limit, skip };
};

const buildWorkerQuery = ({ serviceId, query }) => {
  const workerQuery = {};

  if (serviceId) {
    workerQuery.serviceId = serviceId;
  }

  if (query.q && query.q.trim()) {
    const pattern = new RegExp(query.q.trim(), "i");
    workerQuery.$or = [{ name: pattern }, { skills: pattern }];
  }

  if (query.rating) {
    workerQuery.rating = { $gte: Number(query.rating) };
  }

  if (query.minPrice || query.maxPrice) {
    workerQuery.price = {};

    if (query.minPrice) {
      workerQuery.price.$gte = Number(query.minPrice);
    }

    if (query.maxPrice) {
      workerQuery.price.$lte = Number(query.maxPrice);
    }
  }

  return workerQuery;
};

const buildSortQuery = (sort) => {
  if (sort === "rating") {
    return { rating: -1 };
  }

  if (sort === "price") {
    return { price: 1 };
  }

  return { createdAt: -1 };
};

const buildGlobalSortQuery = ({ sort, order }) => {
  let field = "createdAt";
  let direction = -1;

  if (typeof sort === "string" && sort.trim()) {
    const normalizedSort = sort.trim().toLowerCase();

    if (normalizedSort === "rating" || normalizedSort === "-rating") {
      field = "rating";
      direction = normalizedSort.startsWith("-") ? -1 : 1;
    }

    if (normalizedSort === "price" || normalizedSort === "-price") {
      field = "price";
      direction = normalizedSort.startsWith("-") ? -1 : 1;
    }
  }

  if (field !== "createdAt" && typeof order === "string") {
    const normalizedOrder = order.trim().toLowerCase();
    if (normalizedOrder === "asc" || normalizedOrder === "1") {
      direction = 1;
    }
    if (normalizedOrder === "desc" || normalizedOrder === "-1") {
      direction = -1;
    }
  }

  return { [field]: direction };
};

export const getAllWorkers = async (req, res) => {
  try {
    const { q, sort, order, serviceId } = req.query;

    const pageParsed = parseOptionalPositiveInt(req.query.page, 1);
    const limitParsed = parseOptionalPositiveInt(req.query.limit, 10, 50);

    if (pageParsed.error || limitParsed.error) {
      return res.status(400).json({
        success: false,
        message: pageParsed.error || limitParsed.error,
      });
    }

    const page = pageParsed.value;
    const limit = limitParsed.value;
    const skip = (page - 1) * limit;

    // Support both `rating` and legacy `minRating` to avoid breaking clients.
    const minRatingParsed = parseOptionalNumber(req.query.rating ?? req.query.minRating);
    const minPriceParsed = parseOptionalNumber(req.query.minPrice);
    const maxPriceParsed = parseOptionalNumber(req.query.maxPrice);

    const parseError = [minRatingParsed, minPriceParsed, maxPriceParsed].find(
      (item) => item?.error
    );

    if (parseError) {
      return res.status(400).json({
        success: false,
        message: parseError.error,
      });
    }

    const minRating = minRatingParsed.value;
    const minPrice = minPriceParsed.value;
    const maxPrice = maxPriceParsed.value;

    if (minRating !== undefined && (minRating < 0 || minRating > 5)) {
      return res.status(400).json({
        success: false,
        message: "rating must be between 0 and 5",
      });
    }

    if (minPrice !== undefined && maxPrice !== undefined && minPrice > maxPrice) {
      return res.status(400).json({
        success: false,
        message: "minPrice cannot be greater than maxPrice",
      });
    }

    const workerQuery = {};

    if (q !== undefined && typeof q === "object") {
      return res.status(400).json({
        success: false,
        message: "q must be a string",
      });
    }

    if (typeof q === "string" && q.trim()) {
      const pattern = new RegExp(q.trim(), "i");
      workerQuery.$or = [{ name: pattern }, { skills: pattern }];
    }

    if (minRating !== undefined) {
      workerQuery.rating = { $gte: minRating };
    }

    if (minPrice !== undefined || maxPrice !== undefined) {
      workerQuery.price = {};

      if (minPrice !== undefined) {
        workerQuery.price.$gte = minPrice;
      }

      if (maxPrice !== undefined) {
        workerQuery.price.$lte = maxPrice;
      }
    }

    if (serviceId !== undefined) {
      if (typeof serviceId !== "string" || !mongoose.Types.ObjectId.isValid(serviceId)) {
        return res.status(400).json({
          success: false,
          message: "serviceId must be a valid ObjectId",
        });
      }

      workerQuery.serviceId = serviceId;
    }

    const sortQuery = buildGlobalSortQuery({ sort, order });

    const [workers, total] = await Promise.all([
      Worker.find(workerQuery).sort(sortQuery).skip(skip).limit(limit).lean(),
      Worker.countDocuments(workerQuery),
    ]);

    return res.status(200).json({
      success: true,
      count: workers.length,
      total,
      page,
      pages: Math.ceil(total / limit),
      data: workers,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch workers",
      error: err.message,
    });
  }
};

export const getWorkers = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const { page, limit, skip } = parsePagination(req.query);
    const workerQuery = buildWorkerQuery({ serviceId, query: req.query });
    const sortQuery = buildSortQuery(req.query.sort);

    const [workers, total] = await Promise.all([
      Worker.find(workerQuery).sort(sortQuery).skip(skip).limit(limit).lean(),
      Worker.countDocuments(workerQuery),
    ]);

    return res.status(200).json({
      success: true,
      count: workers.length,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      data: workers,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch workers",
      error: err.message,
    });
  }
};

export const searchWorkers = async (req, res) => {
  try {
    const { page, limit, skip } = parsePagination(req.query);
    const workerQuery = buildWorkerQuery({ query: req.query });
    const sortQuery = buildSortQuery(req.query.sort);

    const [workers, total] = await Promise.all([
      Worker.find(workerQuery).sort(sortQuery).skip(skip).limit(limit).lean(),
      Worker.countDocuments(workerQuery),
    ]);

    return res.status(200).json({
      success: true,
      count: workers.length,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      data: workers,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Failed to search workers",
      error: err.message,
    });
  }
};

export const getWorkerById = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid worker id",
      });
    }

    const worker = await Worker.findById(req.params.id).lean();

    if (!worker) {
      return res.status(404).json({
        success: false,
        message: "Worker not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: worker,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch worker",
      error: err.message,
    });
  }
};

export const getWorkerAvailableSlots = async (req, res) => {
  try {
    const { id } = req.params;
    const { date } = req.query;

    const worker = await Worker.findById(id).select("availableSlots").lean();

    if (!worker) {
      return res.status(404).json({
        success: false,
        message: "Worker not found",
      });
    }

    if (!date) {
      return res.status(200).json({
        success: true,
        data: worker.availableSlots,
      });
    }

    const slotEntry = worker.availableSlots.find((slot) => slot.date === date);
    const availableSlots = slotEntry?.timeSlots ?? [];

    const booked = await Booking.find({
      workerId: id,
      date,
      status: { $in: ["pending", "confirmed"] },
    })
      .select("time -_id")
      .lean();

    const bookedSlots = booked.map((item) => item.time);
    const openSlots = availableSlots.filter((slot) => !bookedSlots.includes(slot));

    return res.status(200).json({
      success: true,
      data: {
        date,
        availableSlots,
        bookedSlots,
        openSlots,
      },
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch worker slots",
      error: err.message,
    });
  }
};
