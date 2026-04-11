import mongoose from "mongoose";

export const isValidPhone = (phone) => {
  return /^[0-9]{10,15}$/.test(String(phone ?? "").trim());
};

export const isStrongEnoughPassword = (password) => {
  return typeof password === "string" && password.trim().length >= 6;
};

export const isValidObjectId = (id) => {
  return mongoose.Types.ObjectId.isValid(id);
};

export const parsePagination = (query, defaults = { page: 1, limit: 10, maxLimit: 50 }) => {
  const page = Math.max(parseInt(query.page, 10) || defaults.page, 1);
  const limit = Math.min(Math.max(parseInt(query.limit, 10) || defaults.limit, 1), defaults.maxLimit);
  const skip = (page - 1) * limit;

  return { page, limit, skip };
};
