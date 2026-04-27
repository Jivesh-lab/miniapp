import Worker from "../models/worker.model.js";
import Booking from "../models/booking.model.js";
import mongoose from "mongoose";
import {
  handleWorkerException,
  sendWorkerNotFound,
  sendWorkerValidationError,
} from "../utils/worker-error.util.js";
import { calculateDistance, formatDistance, isValidCoordinates } from "../utils/distance.util.js";

const DEFAULT_ALL_SLOTS = ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM"];

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

const buildCompletedWorkerQuery = () => ({
  name: { $exists: true, $ne: "" },
  serviceId: { $exists: true, $ne: null },
  location: { $exists: true, $ne: "" },
  price: { $gt: 0 },
});

const buildWorkerQuery = ({ serviceId, query }) => {
  const workerQuery = buildCompletedWorkerQuery();

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
    workerQuery.price = {
      ...workerQuery.price,
    };

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

/**
 * Add distance information to workers if user location is provided
 * Sorts by distance if sortByDistance is true
 */
const enrichWorkersWithDistance = (workers, userLatitude, userLongitude, sortByDistance = false) => {
  const canCalculateDistance =
    userLatitude !== undefined &&
    userLongitude !== undefined &&
    isValidCoordinates(userLatitude, userLongitude);

  const enriched = workers.map((worker) => {
    let distance = null;
    let distanceFormatted = null;

    if (
      canCalculateDistance &&
      worker.latitude !== null &&
      worker.longitude !== null &&
      isValidCoordinates(worker.latitude, worker.longitude)
    ) {
      distance = calculateDistance(userLatitude, userLongitude, worker.latitude, worker.longitude);
      distanceFormatted = formatDistance(distance);
    }

    return {
      ...worker,
      distance: distance,
      distanceFormatted: distanceFormatted,
    };
  });

  if (sortByDistance && canCalculateDistance) {
    enriched.sort((a, b) => {
      if (a.distance === null) return 1;
      if (b.distance === null) return -1;
      return a.distance - b.distance;
    });
  }

  return enriched;
};

export const getAllWorkers = async (req, res) => {
  try {
    const { q, sort, order, serviceId, userLatitude, userLongitude } = req.query;

    const pageParsed = parseOptionalPositiveInt(req.query.page, 1);
    const limitParsed = parseOptionalPositiveInt(req.query.limit, 10, 50);

    if (pageParsed.error || limitParsed.error) {
      return sendWorkerValidationError(res, pageParsed.error || limitParsed.error);
    }

    const page = pageParsed.value;
    const limit = limitParsed.value;
    const skip = (page - 1) * limit;

    // Support both `rating` and legacy `minRating` to avoid breaking clients.
    const minRatingParsed = parseOptionalNumber(req.query.rating ?? req.query.minRating);
    const minPriceParsed = parseOptionalNumber(req.query.minPrice);
    const maxPriceParsed = parseOptionalNumber(req.query.maxPrice);
    const userLatParsed = parseOptionalNumber(userLatitude);
    const userLngParsed = parseOptionalNumber(userLongitude);

    const parseError = [minRatingParsed, minPriceParsed, maxPriceParsed, userLatParsed, userLngParsed].find(
      (item) => item?.error
    );

    if (parseError) {
      return sendWorkerValidationError(res, parseError.error);
    }

    const minRating = minRatingParsed.value;
    const minPrice = minPriceParsed.value;
    const maxPrice = maxPriceParsed.value;

    if (minRating !== undefined && (minRating < 0 || minRating > 5)) {
      return sendWorkerValidationError(res, "rating must be between 0 and 5");
    }

    if (minPrice !== undefined && maxPrice !== undefined && minPrice > maxPrice) {
      return sendWorkerValidationError(res, "minPrice cannot be greater than maxPrice");
    }

    const workerQuery = buildCompletedWorkerQuery();

    if (q !== undefined && typeof q === "object") {
      return sendWorkerValidationError(res, "q must be a string");
    }

    if (typeof q === "string" && q.trim()) {
      const pattern = new RegExp(q.trim(), "i");
      workerQuery.$or = [{ name: pattern }, { skills: pattern }];
    }

    if (minRating !== undefined) {
      workerQuery.rating = { $gte: minRating };
    }

    if (minPrice !== undefined || maxPrice !== undefined) {
      workerQuery.price = {
        ...workerQuery.price,
      };

      if (minPrice !== undefined) {
        workerQuery.price.$gte = minPrice;
      }

      if (maxPrice !== undefined) {
        workerQuery.price.$lte = maxPrice;
      }
    }

    if (serviceId !== undefined) {
      if (typeof serviceId !== "string" || !mongoose.Types.ObjectId.isValid(serviceId)) {
        return sendWorkerValidationError(res, "serviceId must be a valid ObjectId");
      }

      workerQuery.serviceId = serviceId;
    }

    const sortQuery = buildGlobalSortQuery({ sort, order });

    const [workers, total] = await Promise.all([
      Worker.find(workerQuery).sort(sortQuery).skip(skip).limit(limit).lean(),
      Worker.countDocuments(workerQuery),
    ]);

    const userLat = userLatParsed.value;
    const userLng = userLngParsed.value;
    const hasUserLocation = userLat !== undefined && userLng !== undefined;
    const enrichedWorkers = enrichWorkersWithDistance(workers, userLat, userLng, sort === "nearest" || !sort);

    return res.status(200).json({
      success: true,
      count: enrichedWorkers.length,
      total,
      page,
      pages: Math.ceil(total / limit),
      data: enrichedWorkers,
    });
  } catch (err) {
    return handleWorkerException(res, err, "Failed to fetch workers");
  }
};

export const getWorkers = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const { userLatitude, userLongitude } = req.query;
    const { page, limit, skip } = parsePagination(req.query);
    const workerQuery = buildWorkerQuery({ serviceId, query: req.query });
    const sortQuery = buildSortQuery(req.query.sort);

    const userLatParsed = parseOptionalNumber(userLatitude);
    const userLngParsed = parseOptionalNumber(userLongitude);

    const parseError = [userLatParsed, userLngParsed].find((item) => item?.error);
    if (parseError) {
      return sendWorkerValidationError(res, parseError.error);
    }

    const [workers, total] = await Promise.all([
      Worker.find(workerQuery).sort(sortQuery).skip(skip).limit(limit).lean(),
      Worker.countDocuments(workerQuery),
    ]);

    const userLat = userLatParsed.value;
    const userLng = userLngParsed.value;
    const enrichedWorkers = enrichWorkersWithDistance(workers, userLat, userLng, req.query.sort === "nearest");

    return res.status(200).json({
      success: true,
      count: enrichedWorkers.length,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      data: enrichedWorkers,
    });
  } catch (err) {
    return handleWorkerException(res, err, "Failed to fetch workers");
  }
};

export const searchWorkers = async (req, res) => {
  try {
    const { userLatitude, userLongitude } = req.query;
    const { page, limit, skip } = parsePagination(req.query);
    const workerQuery = buildWorkerQuery({ query: req.query });
    const sortQuery = buildSortQuery(req.query.sort);

    const userLatParsed = parseOptionalNumber(userLatitude);
    const userLngParsed = parseOptionalNumber(userLongitude);

    const parseError = [userLatParsed, userLngParsed].find((item) => item?.error);
    if (parseError) {
      return sendWorkerValidationError(res, parseError.error);
    }

    const [workers, total] = await Promise.all([
      Worker.find(workerQuery).sort(sortQuery).skip(skip).limit(limit).lean(),
      Worker.countDocuments(workerQuery),
    ]);

    const userLat = userLatParsed.value;
    const userLng = userLngParsed.value;
    const enrichedWorkers = enrichWorkersWithDistance(workers, userLat, userLng, req.query.sort === "nearest");

    return res.status(200).json({
      success: true,
      count: enrichedWorkers.length,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      data: enrichedWorkers,
    });
  } catch (err) {
    return handleWorkerException(res, err, "Failed to search workers");
  }
};

export const getWorkerById = async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return sendWorkerValidationError(res, "Invalid worker id");
    }

    const worker = await Worker.findById(req.params.id).lean();
    const { userLatitude, userLongitude } = req.query;
    const userLatParsed = parseOptionalNumber(userLatitude);
    const userLngParsed = parseOptionalNumber(userLongitude);

    const parseError = [userLatParsed, userLngParsed].find((item) => item?.error);
    if (parseError) {
      return sendWorkerValidationError(res, parseError.error);
    }

    if (!worker) {
      return sendWorkerNotFound(res, "Worker not found");
    }

    const [enrichedWorker] = enrichWorkersWithDistance(
      [worker],
      userLatParsed.value,
      userLngParsed.value,
      false
    );

    return res.status(200).json({
      success: true,
      data: enrichedWorker,
    });
  } catch (err) {
    return handleWorkerException(res, err, "Failed to fetch worker");
  }
};

export const getNearbyWorkers = async (req, res) => {
  try {
    const { lat, lng, serviceId } = req.query;

    const latParsed = parseOptionalNumber(lat);
    const lngParsed = parseOptionalNumber(lng);
    const pageParsed = parseOptionalPositiveInt(req.query.page, 1);
    const limitParsed = parseOptionalPositiveInt(req.query.limit, 20, 50);
    const minRatingParsed = parseOptionalNumber(req.query.rating ?? req.query.minRating);
    const minPriceParsed = parseOptionalNumber(req.query.minPrice);
    const maxPriceParsed = parseOptionalNumber(req.query.maxPrice);

    const parseError = [
      latParsed,
      lngParsed,
      pageParsed,
      limitParsed,
      minRatingParsed,
      minPriceParsed,
      maxPriceParsed,
    ].find((item) => item?.error);

    if (parseError) {
      return sendWorkerValidationError(res, parseError.error);
    }

    if (latParsed.value === undefined || lngParsed.value === undefined) {
      return sendWorkerValidationError(res, "lat and lng are required");
    }

    if (!isValidCoordinates(latParsed.value, lngParsed.value)) {
      return sendWorkerValidationError(res, "Invalid latitude or longitude coordinates");
    }

    const minRating = minRatingParsed.value;
    const minPrice = minPriceParsed.value;
    const maxPrice = maxPriceParsed.value;

    if (minRating !== undefined && (minRating < 0 || minRating > 5)) {
      return sendWorkerValidationError(res, "rating must be between 0 and 5");
    }

    if (minPrice !== undefined && maxPrice !== undefined && minPrice > maxPrice) {
      return sendWorkerValidationError(res, "minPrice cannot be greater than maxPrice");
    }

    const page = pageParsed.value;
    const limit = limitParsed.value;
    const skip = (page - 1) * limit;

    const match = {
      ...buildCompletedWorkerQuery(),
      role: "worker",
      isOnline: true,
      "geoLocation.coordinates": { $exists: true },
    };

    if (serviceId !== undefined) {
      if (typeof serviceId !== "string" || !mongoose.Types.ObjectId.isValid(serviceId)) {
        return sendWorkerValidationError(res, "serviceId must be a valid ObjectId");
      }
      match.serviceId = new mongoose.Types.ObjectId(serviceId);
    }

    if (typeof req.query.q === "string" && req.query.q.trim()) {
      const pattern = new RegExp(req.query.q.trim(), "i");
      match.$or = [{ name: pattern }, { skills: pattern }];
    }

    if (minRating !== undefined) {
      match.rating = { $gte: minRating };
    }

    if (minPrice !== undefined || maxPrice !== undefined) {
      match.price = {
        ...match.price,
      };

      if (minPrice !== undefined) {
        match.price.$gte = minPrice;
      }

      if (maxPrice !== undefined) {
        match.price.$lte = maxPrice;
      }
    }

    const basePipeline = [
      {
        $geoNear: {
          near: {
            type: "Point",
            coordinates: [lngParsed.value, latParsed.value],
          },
          maxDistance: 5000,
          key: "geoLocation",
          spherical: true,
          distanceField: "distanceInMeters",
          query: match,
        },
      },
      {
        $addFields: {
          distance: {
            $round: [{ $divide: ["$distanceInMeters", 1000] }, 1],
          },
        },
      },
      {
        $addFields: {
          distanceFormatted: {
            $cond: [
              { $lt: ["$distance", 1] },
              {
                $concat: [
                  { $toString: { $round: ["$distanceInMeters", 0] } },
                  " m",
                ],
              },
              {
                $concat: [{ $toString: "$distance" }, " km"],
              },
            ],
          },
        },
      },
      {
        $project: {
          distanceInMeters: 0,
        },
      },
    ];

    let [countResult, workers] = await Promise.all([
      Worker.aggregate([...basePipeline, { $count: "total" }]),
      Worker.aggregate([...basePipeline, { $skip: skip }, { $limit: limit }]),
    ]);

    let total = countResult[0]?.total ?? 0;
    let isFallback = false;

    if (total === 0) {
      const matchForFallback = { ...match };
      delete matchForFallback["geoLocation.coordinates"];

      const allWorkers = await Worker.find(matchForFallback).lean();
      const enrichedWorkers = enrichWorkersWithDistance(
        allWorkers,
        latParsed.value,
        lngParsed.value,
        true
      );
      
      total = enrichedWorkers.length;
      workers = enrichedWorkers.slice(skip, skip + limit);
      isFallback = true;
    }

    return res.status(200).json({
      success: true,
      count: workers.length,
      total,
      page,
      totalPages: Math.ceil(total / limit),
      data: workers,
      isFallback,
    });
  } catch (err) {
    return handleWorkerException(res, err, "Failed to fetch nearby workers");
  }
};

export const getWorkerAvailableSlots = async (req, res) => {
  try {
    const { id } = req.params;
    const { date } = req.query;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return sendWorkerValidationError(res, "Invalid worker id");
    }

    if (!date || typeof date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return sendWorkerValidationError(res, "date query is required in YYYY-MM-DD format");
    }

    const selectedDate = new Date(date);

    if (Number.isNaN(selectedDate.getTime())) {
      return sendWorkerValidationError(res, "Invalid date");
    }

    const today = new Date();
    const minDate = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()));
    const maxDate = new Date(minDate);
    maxDate.setUTCMonth(maxDate.getUTCMonth() + 2);

    if (selectedDate < minDate || selectedDate > maxDate) {
      return sendWorkerValidationError(res, "Date must be within the current 2 months window");
    }

    const worker = await Worker.findById(id).select("_id").lean();

    if (!worker) {
      return sendWorkerNotFound(res, "Worker not found");
    }

    const allSlots = [...DEFAULT_ALL_SLOTS];

    const booked = await Booking.find({
      workerId: id,
      date,
      status: { $in: ["pending", "confirmed"] },
    })
      .select("time -_id")
      .lean();

    const bookedSlots = booked.map((item) => item.time);
    const availableSlots = allSlots.filter((slot) => !bookedSlots.includes(slot));

    return res.status(200).json({
      success: true,
      availableSlots,
      bookedSlots,
      allSlots,
    });
  } catch (err) {
    return handleWorkerException(res, err, "Failed to fetch worker slots");
  }
};
