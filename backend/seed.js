import dotenv from "dotenv";
import mongoose from "mongoose";

import Service from "./src/models/service.model.js";
import Worker from "./src/models/worker.model.js";
import Booking from "./src/models/booking.model.js";
import User from "./src/models/user.model.js";

const defaultSlots = [
  {
    date: "2026-04-10",
    timeSlots: ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM"],
  },
  {
    date: "2026-04-11",
    timeSlots: ["10:00 AM", "12:00 PM", "2:00 PM", "4:00 PM"],
  },
];

dotenv.config();

const seedDatabase = async () => {
  const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI;

  if (!mongoUri) {
    throw new Error("MONGO_URI or MONGODB_URI is required in .env");
  }

  try {
    await mongoose.connect(mongoUri);
    console.log("Connected to MongoDB for seeding");

    await Booking.deleteMany({});
    await Worker.deleteMany({});
    await Service.deleteMany({});
    await User.deleteMany({});
    console.log("Cleared existing data");

    await User.create({
      userId: "12345",
      name: "Demo User",
      email: "demo.user@example.com",
      phone: "9876543210",
    });

    const services = await Service.insertMany([
      { name: "Plumber" },
      { name: "Electrician" },
      { name: "Cleaner" },
      { name: "AC Repair" },
    ]);

    const serviceMap = Object.fromEntries(services.map((s) => [s.name, s._id]));

    const workers = await Worker.insertMany([
      {
        name: "Rakesh Patil",
        serviceId: serviceMap.Plumber,
        rating: 4.7,
        price: 350,
        location: "Navi Mumbai",
        skills: ["Pipe Leakage", "Bathroom Fittings", "Tank Cleaning"],
        reviews: [
          { user: "Amit", comment: "Very quick and professional", rating: 5 },
          { user: "Neha", comment: "Solved leakage issue perfectly", rating: 4 },
        ],
        availableSlots: defaultSlots,
      },
      {
        name: "Sanjay More",
        serviceId: serviceMap.Plumber,
        rating: 4.3,
        price: 220,
        location: "Mumbai",
        skills: ["Tap Repair", "Drain Cleaning", "Pipeline Maintenance"],
        reviews: [
          { user: "Pooja", comment: "Affordable and good service", rating: 4 },
          { user: "Rohit", comment: "Came on time and fixed quickly", rating: 4 },
          { user: "Rahul", comment: "Good work quality", rating: 5 },
        ],
        availableSlots: defaultSlots,
      },
      {
        name: "Vikram Deshmukh",
        serviceId: serviceMap.Electrician,
        rating: 4.9,
        price: 450,
        location: "Navi Mumbai",
        skills: ["Wiring", "MCB Installation", "Inverter Setup"],
        reviews: [
          { user: "Kiran", comment: "Excellent electrical knowledge", rating: 5 },
          { user: "Seema", comment: "Very safe and neat work", rating: 5 },
        ],
        availableSlots: defaultSlots,
      },
      {
        name: "Nitin Jadhav",
        serviceId: serviceMap.Electrician,
        rating: 4.4,
        price: 300,
        location: "Mumbai",
        skills: ["Fan Repair", "Switch Board", "Light Installation"],
        reviews: [
          { user: "Deepak", comment: "Fixed fan issue in one visit", rating: 4 },
          { user: "Monika", comment: "Good behavior and service", rating: 4 },
          { user: "Anita", comment: "Recommended electrician", rating: 5 },
        ],
        availableSlots: defaultSlots,
      },
      {
        name: "Meena Kale",
        serviceId: serviceMap.Cleaner,
        rating: 4.6,
        price: 180,
        location: "Navi Mumbai",
        skills: ["Home Deep Cleaning", "Kitchen Cleaning", "Bathroom Sanitization"],
        reviews: [
          { user: "Sakshi", comment: "Very clean finishing", rating: 5 },
          { user: "Arjun", comment: "Polite and hardworking", rating: 4 },
        ],
        availableSlots: defaultSlots,
      },
      {
        name: "Priya Sawant",
        serviceId: serviceMap.Cleaner,
        rating: 4.2,
        price: 140,
        location: "Mumbai",
        skills: ["Sofa Cleaning", "Floor Cleaning", "Dust Removal"],
        reviews: [
          { user: "Tanya", comment: "Good service at low price", rating: 4 },
          { user: "Vivek", comment: "House looked fresh and clean", rating: 4 },
          { user: "Manoj", comment: "Satisfied with cleaning", rating: 5 },
        ],
        availableSlots: defaultSlots,
      },
      {
        name: "Imran Shaikh",
        serviceId: serviceMap["AC Repair"],
        rating: 4.8,
        price: 500,
        location: "Navi Mumbai",
        skills: ["AC Gas Refill", "Cooling Issue", "Compressor Check"],
        reviews: [
          { user: "Rina", comment: "AC cooling restored perfectly", rating: 5 },
          { user: "Harsh", comment: "Expert in AC servicing", rating: 5 },
        ],
        availableSlots: defaultSlots,
      },
      {
        name: "Anil Gaikwad",
        serviceId: serviceMap["AC Repair"],
        rating: 4.1,
        price: 260,
        location: "Mumbai",
        skills: ["AC Filter Cleaning", "General Service", "Water Leakage Fix"],
        reviews: [
          { user: "Komal", comment: "Did proper servicing", rating: 4 },
          { user: "Nilesh", comment: "Reasonable and helpful", rating: 4 },
          { user: "Ajay", comment: "Good for regular AC maintenance", rating: 4 },
        ],
        availableSlots: defaultSlots,
      },
    ]);

    await Booking.insertMany([
      {
        userId: "12345",
        workerId: workers[0]._id,
        date: "2026-04-10",
        time: "10:00 AM",
        address: "Sector 10, Vashi, Navi Mumbai",
        status: "pending",
      },
      {
        userId: "12345",
        workerId: workers[2]._id,
        date: "2026-04-09",
        time: "2:00 PM",
        address: "Andheri East, Mumbai",
        status: "completed",
      },
      {
        userId: "12345",
        workerId: workers[4]._id,
        date: "2026-04-11",
        time: "12:00 PM",
        address: "Kharghar, Navi Mumbai",
        status: "confirmed",
      },
    ]);

    console.log(`Seed complete: ${services.length} services, ${workers.length} workers, 3 bookings`);
  } catch (error) {
    console.error(`Seeding failed: ${error.message}`);
    process.exitCode = 1;
  } finally {
    await mongoose.connection.close();
    console.log("MongoDB connection closed");
  }
};

seedDatabase();
