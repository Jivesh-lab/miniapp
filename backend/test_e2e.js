import mongoose from 'mongoose';
import dotenv from 'dotenv';
import EmailOtp from './src/models/emailOtp.model.js';
import crypto from 'crypto';

dotenv.config();

const BASE_URL = 'http://127.0.0.1:3000/api';

const hashOtp = (otp) => crypto.createHash("sha256").update(otp).digest("hex");

async function test() {
  console.log("=== Starting E2E Test ===\n");
  
  await mongoose.connect(process.env.MONGODB_URI);
  console.log("Connected to MongoDB for testing.");

  const rand = Math.floor(Math.random() * 100000);
  const workerPhone = `99999${rand}`.slice(0, 10);
  const userPhone = `88888${rand}`.slice(0, 10);
  const userEmail = `user${rand}@example.com`;

  // 1. Register Worker
  console.log(`[1] Registering worker with phone: ${workerPhone}`);
  let res = await fetch(`${BASE_URL}/auth/register-worker`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'Test Worker', phone: workerPhone, password: 'password123' })
  });
  let data = await res.json();
  if(!data.success) { console.error("Worker registration failed:", data); process.exit(1); }
  const workerId = data.data.workerId;

  // 2. Register User
  console.log(`\n[2] Registering user with phone: ${userPhone}, email: ${userEmail}`);
  res = await fetch(`${BASE_URL}/auth/register-user`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'Test User', phone: userPhone, email: userEmail, password: 'password123' })
  });
  data = await res.json();
  if(!data.success) { console.error("User registration failed:", data); process.exit(1); }

  // 3. Login User (Triggers OTP)
  console.log("\n[3] Logging in User (to trigger OTP)");
  res = await fetch(`${BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: userEmail, password: 'password123', role: 'user' })
  });
  data = await res.json();
  if(!data.requires_otp) { console.error("OTP not requested:", data); process.exit(1); }

  // 4. Overwrite OTP with a known value in DB to bypass hashing issue
  console.log("\n[4] Overwriting OTP in DB to '123456'");
  const knownOtpHash = hashOtp("123456");
  await EmailOtp.updateOne({ email: userEmail }, { otpHash: knownOtpHash });

  // 5. Verify OTP
  console.log("\n[5] Verifying OTP '123456'");
  res = await fetch(`${BASE_URL}/auth/verify-login-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: userEmail, otp: '123456', role: 'user' })
  });
  data = await res.json();
  if(!data.success) { console.error("OTP Verification failed:", data); process.exit(1); }
  const userToken = data.token;
  console.log("    -> User Logged in, Token received.");

  // 6. Create a Booking
  console.log("\n[6] Creating a booking");
  res = await fetch(`${BASE_URL}/bookings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${userToken}` },
    body: JSON.stringify({ workerId, date: '2026-05-01', time: '10:00 AM', address: '123 Test St' })
  });
  data = await res.json();
  if(!data.success) { console.error("Booking creation failed:", data); process.exit(1); }
  console.log("    -> Booking created.");

  // 7. Create identical booking to test conflict
  console.log("\n[7] Creating an overlapping booking (Should Fail)");
  res = await fetch(`${BASE_URL}/bookings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${userToken}` },
    body: JSON.stringify({ workerId, date: '2026-05-01', time: '10:00 AM', address: '123 Test St' })
  });
  data = await res.json();
  if(res.status === 409) { 
    console.log("    -> Conflict properly detected! (Success)"); 
  } else {
    console.error("    -> Expected 409 Conflict, got:", data);
    process.exit(1);
  }

  console.log("\n=== All Tests Passed! ===");
  process.exit(0);
}

test().catch(console.error);
