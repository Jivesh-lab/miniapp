import dotenv from "dotenv";
import mongoose from "mongoose";

import Service from "./src/models/service.model.js";
import Worker from "./src/models/worker.model.js";

dotenv.config();

const DEFAULT_PASSWORD_HASH = "$2b$10$qRSlqDoeGcXTFZ18h4q0xeqHrq.dBvx9LjR6rt65eIVK06BTIWHW.";

const workerSeeds = [
  {
    name: "Harsh Sharma",
    serviceName: "Electrician",
    phone: "7838399292",
    passwordHash: DEFAULT_PASSWORD_HASH,
    location: "Karjat",
    latitude: 19.251812826387624,
    longitude: 73.13584448763137,
    price: 372,
    rating: 4.5,
    ratingCount: 8,
    skills: ["fixing", "socket", "wiring"],
    isOnline: true,
  },
  {
    name: "Rajesh Kumar",
    serviceName: "Plumber",
    phone: "8765432101",
    passwordHash: DEFAULT_PASSWORD_HASH,
    location: "Panvel",
    latitude: 18.992,
    longitude: 73.119,
    price: 450,
    rating: 4.7,
    ratingCount: 15,
    skills: ["pipe repair", "tank cleaning", "faucet installation"],
    isOnline: true,
  },
  {
    name: "Priya Desai",
    serviceName: "Cleaner",
    phone: "9123456789",
    passwordHash: DEFAULT_PASSWORD_HASH,
    location: "Kharghar",
    latitude: 19.0456,
    longitude: 73.0618,
    price: 280,
    rating: 4.3,
    ratingCount: 12,
    skills: ["deep cleaning", "kitchen sanitization", "floor polishing"],
    isOnline: true,
  },
  {
    name: "Arjun Patil",
    serviceName: "AC Repair",
    phone: "9876543410",
    passwordHash: DEFAULT_PASSWORD_HASH,
    location: "Navi Mumbai",
    latitude: 19.0795,
    longitude: 73.0014,
    price: 520,
    rating: 4.8,
    ratingCount: 22,
    skills: ["gas refill", "cooling repair", "compressor service"],
    isOnline: true,
  },
  {
    name: "Sanjana Singh",
    serviceName: "Cleaner",
    phone: "7654321098",
    passwordHash: DEFAULT_PASSWORD_HASH,
    location: "Kalamboli",
    latitude: 19.0318,
    longitude: 73.0989,
    price: 250,
    rating: 4.2,
    ratingCount: 10,
    skills: ["sofa cleaning", "carpet wash", "dust removal"],
    isOnline: true,
  },
  {
    name: "Vikram Rao",
    serviceName: "Electrician",
    phone: "8901234567",
    passwordHash: DEFAULT_PASSWORD_HASH,
    location: "Thane",
    latitude: 19.218,
    longitude: 72.978,
    price: 380,
    rating: 4.6,
    ratingCount: 18,
    skills: ["wiring", "mcb installation", "inverter setup"],
    isOnline: true,
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
    await Worker.deleteMany({});
    console.log("Deleted existing workers");

    const serviceNames = [...new Set(workerSeeds.map((item) => item.serviceName))];
    const serviceMap = await ensureServices(serviceNames);

    for (const workerData of workerSeeds) {
      const serviceId = serviceMap[workerData.serviceName];
      const rating = Number(workerData.rating);
      const ratingCount = Number(workerData.ratingCount);
      const ratingSum = Number((rating * ratingCount).toFixed(1));
      const now = new Date();

      await Worker.create({
        name: workerData.name,
        serviceId,
        phone: workerData.phone,
        password: workerData.passwordHash,
        location: workerData.location,
        price: workerData.price,
        skills: workerData.skills,
        latitude: workerData.latitude,
        longitude: workerData.longitude,
        geoLocation: {
          type: "Point",
          coordinates: [workerData.longitude, workerData.latitude],
        },
        rating,
        ratingCount,
        ratingSum,
        isOnline: workerData.isOnline,
        lastLocationUpdate: now,
        role: "worker",
        availableSlots: [],
        reviews: [],
      });
    }

    console.log(`Workers seeded successfully. Inserted ${workerSeeds.length} workers.`);
  } finally {
    await mongoose.connection.close();
    console.log("MongoDB connection closed");
  }
};

seedWorkers().catch((error) => {
  console.error("Worker seed failed:", error.message);
  process.exitCode = 1;
});
