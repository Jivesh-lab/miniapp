import Worker from "../models/worker.model.js";

// ✅ Get workers by service + sorting
export const getWorkers = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const { sort } = req.query;

    let sortQuery = {};

    if (sort === "rating") {
      sortQuery = { rating: -1 };
    } else if (sort === "price") {
      sortQuery = { price: 1 };
    }

    const workers = await Worker.find({ serviceId }).sort(sortQuery).lean();

    if (!workers.length) {
      return res.status(404).json({
        success: false,
        message: "No workers found for this service",
        data: [],
      });
    }

    return res.status(200).json({
      success: true,
      count: workers.length,
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

// ✅ Get single worker details
export const getWorkerById = async (req, res) => {
  try {
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
