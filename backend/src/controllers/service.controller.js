import Service from "../models/service.model.js";

const defaultServices = [
  { _id: "1", name: "Plumber" },
  { _id: "2", name: "Electrician" },
  { _id: "3", name: "Cleaner" },
  { _id: "4", name: "AC Repair" },
];

export const getServices = async (req, res) => {
  try {
    const services = await Service.find().sort({ name: 1 }).lean();
    const data = services.length ? services : defaultServices;

    return res.status(200).json({
      success: true,
      count: data.length,
      data,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to fetch services",
      error: error.message,
    });
  }
};

export const createService = async (req, res) => {
  try {
    const { name } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({
        success: false,
        message: "Service name is required",
      });
    }

    const existingService = await Service.findOne({
      name: name.trim(),
    }).lean();

    if (existingService) {
      return res.status(400).json({
        success: false,
        message: "Service already exists",
      });
    }

    const service = await Service.create({ name: name.trim() });

    return res.status(201).json({
      success: true,
      message: "Service created successfully",
      data: service,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to create service",
      error: error.message,
    });
  }
};
