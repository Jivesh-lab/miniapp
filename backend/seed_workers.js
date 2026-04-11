import dotenv from "dotenv";
import mongoose from "mongoose";
import bcrypt from "bcryptjs";

import Service from "./src/models/service.model.js";
import Worker from "./src/models/worker.model.js";

dotenv.config();

const formatDate = (date) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
};

const buildDefaultSlots = () => {
  const now = new Date();
  const day1 = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
  const day2 = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 2);

  return [
    {
      date: formatDate(day1),
      timeSlots: ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM"],
    },
    {
      date: formatDate(day2),
      timeSlots: ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM"],
    },
  ];
};

const workerSeeds = [
  {
    name: "Rakesh Patil",
    serviceName: "Plumber",
    phone: "9000000001",
    password: "worker123",
    location: "Navi Mumbai",
    price: 350,
    skills: ["Pipe Leakage", "Bathroom Fittings", "Tank Cleaning"],
  },
  {
    name: "Vikram Deshmukh",
    serviceName: "Electrician",
    phone: "9000000002",
    password: "worker123",
    location: "Mumbai",
    price: 450,
    skills: ["Wiring", "MCB Installation", "Fan Repair"],
  },
  {
    name: "Meena Kale",
    serviceName: "Cleaner",
    phone: "9000000003",
    password: "worker123",
    location: "Thane",
    price: 220,
    skills: ["Home Deep Cleaning", "Kitchen Cleaning", "Sofa Cleaning"],
  },
  {
    name: "Imran Shaikh",
    serviceName: "AC Repair",
    phone: "9000000004",
    password: "worker123",
    location: "Pune",
    price: 500,
    skills: ["AC Gas Refill", "Cooling Issue", "Compressor Check"],
  },
];

const ensureServices = async (serviceNames) => {
  for (const name of serviceNames) {
    await Service.updateOne({ name }, { $setOnInsert: { name } }, { upsert: true });
  }

  const services = await Service.find({ name: { $in: serviceNames } }).lean();
  return Object.fromEntries(services.map((service) => [service.name, service._id]));
};

const seedWorkers = async () => {
  const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI;

  if (!mongoUri) {
    throw new Error("MONGO_URI or MONGODB_URI is required in .env");
  }

  await mongoose.connect(mongoUri);
  console.log("Connected to MongoDB");

  try {
    const serviceNames = [...new Set(workerSeeds.map((item) => item.serviceName))];
    const serviceMap = await ensureServices(serviceNames);
    const slots = buildDefaultSlots();

    for (const workerData of workerSeeds) {
      const serviceId = serviceMap[workerData.serviceName];
      const passwordHash = await bcrypt.hash(workerData.password, 10);

      await Worker.updateOne(
        { phone: workerData.phone },
        {
          $set: {
            name: workerData.name,
            serviceId,
            phone: workerData.phone,
            password: passwordHash,
            location: workerData.location,
            price: workerData.price,
            skills: workerData.skills,
            role: "worker",
            availableSlots: slots,
          },
          $setOnInsert: {
            rating: 0,
            ratingCount: 0,
            ratingSum: 0,
            reviews: [],
          },
        },
        { upsert: true }
      );
    }

    console.log("Workers seeded successfully.");
    console.log("Postman login credentials:");
    workerSeeds.forEach((worker) => {
      console.log(`phone=${worker.phone} password=${worker.password}`);
    });
  } finally {
    await mongoose.connection.close();
    console.log("MongoDB connection closed");
  }
};

seedWorkers().catch((error) => {
  console.error("Worker seed failed:", error.message);
  process.exitCode = 1;
});
