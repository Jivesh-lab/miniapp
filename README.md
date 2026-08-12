# Local Service App

> A location-aware service marketplace that connects users with nearby service professionals for on-demand local services such as electrical work, plumbing, repairs, and other household services.

Built with **Flutter, Node.js, Express.js, and MongoDB**, the application provides separate experiences for customers and service workers, including authentication, worker discovery, location-based services, availability, booking management, ratings, reviews, and real-time updates.

---

## 📖 Overview

Finding a reliable local service professional can involve calling multiple people, checking availability manually, and coordinating appointments through disconnected channels.

**Local Service App** brings this workflow into a single mobile platform.

### Users can

- Discover available service professionals
- Find workers based on service and location
- View worker profiles, pricing, ratings, skills, and availability
- Select available time slots
- Create and manage service bookings
- Track booking status
- Rate and review completed services
- Manage their profile and booking history

### Service workers can

- Create and manage professional profiles
- Select service categories
- Manage skills and pricing
- Maintain availability
- Receive booking requests
- Accept or reject bookings
- Manage ongoing and completed bookings
- Maintain online and location status

---

## ✨ Key Features

### 👤 User Experience

- User registration and login
- JWT-based authentication
- Service category discovery
- Worker listing and search
- Worker profile details
- Ratings and reviews
- Pricing and skill information
- Availability and time-slot selection
- Booking creation and management
- Booking history and status tracking
- Profile management
- Location-aware service discovery
- Internet connectivity handling

### 🧑‍🔧 Worker Experience

- Worker registration and authentication
- Worker profile completion
- Service category selection
- Skills and pricing management
- Availability management
- Worker dashboard
- Booking request management
- Accept/reject booking requests
- Booking status updates
- Worker profile management
- Online/offline availability
- Location updates

### 📍 Location & Discovery

The application uses device location to support location-aware service discovery.

The backend supports:

- Latitude and longitude storage
- Geospatial worker data
- MongoDB `2dsphere` indexing
- Worker location updates
- Online worker status
- Geocoding-related endpoints

This provides a foundation for proximity-based worker discovery and localized service matching.

### 📅 Booking Management

Each booking contains:

- Customer
- Service worker
- Date and time
- Service address
- Booking status
- Rating and review
- Comments

Supported booking states:
authentication, worker discovery, location functionality, booking workflows, and real-time backend infrastructure.

1. Clone the Repository
git clone https://github.com/Jivesh-lab/miniapp.git

cd miniapp
2. Configure the Backend
cd backend
npm install

Create a .env file:

PORT=5000
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
FRONTEND_URL=http://localhost:3000

Add any additional environment variables required by the authentication, email, location, or deployment configuration.

3. Start the Backend
npm start

The backend will start using the server entry point configured in package.json.

For development, you can use your preferred Node.js development workflow.

4. Seed Workers

The repository includes a worker seeding script.

npm run seed:workers

This can be used to populate development data for testing worker discovery and booking flows.

5. Run the Flutter Application

Open a new terminal:

cd service_app

flutter pub get

flutter run

To check the Flutter environment:

flutter doctor
Configuration

The mobile application communicates with the backend through HTTP and Socket.IO.

For local development, configure the API/server address according to the environment in which the Flutter application is running.

For a physical Android device, remember that:

localhost

refers to the device itself, not your development computer.

Use the appropriate machine/network address or deployed backend URL when testing on a physical device.

Booking Flow
User
 │
 ▼
Select Service
 │
 ▼
Discover Workers
 │
 ▼
View Worker Profile
 │
 ├── Rating
 ├── Skills
 ├── Price
 ├── Location
 └── Availability
 │
 ▼
Select Date & Time
 │
 ▼
Enter Service Address
 │
 ▼
Create Booking
 │
 ▼
Worker Receives Request
 │
 ├── Reject
 │
 └── Confirm
       │
       ▼
   In Progress
       │
       ▼
    Completed
       │
       ▼
 Rating & Review
User Flow
Launch
  ↓
Splash Screen
  ↓
Authentication
  ├── Login
  └── Sign Up
        ↓
      Home
        ↓
  Select Service
        ↓
  Find Workers
        ↓
  Worker Details
        ↓
     Booking
        ↓
   My Bookings
        ↓
   Rate / Review
Worker Flow
Worker Login
     ↓
Profile Completion
     ↓
Worker Dashboard
     ↓
Booking Requests
     ├── Accept
     └── Reject
          ↓
    Booking Details
          ↓
   Update Status
          ↓
      Completed
Screens & Modules

The Flutter application includes dedicated screens/modules for:

Splash screen
Login
Registration
Home
Worker listing
Worker details
Booking
My bookings
User profile
Worker dashboard
Worker bookings
Worker booking details
Worker profile
Worker profile completion
No-internet handling

These routes are registered directly in the application's navigation configuration.

Development Highlights

This project demonstrates practical full-stack application concepts including:

Cross-platform mobile development
REST API architecture
JWT-based authentication
Role-based authorization
MongoDB data modeling
Geospatial indexing
Location services
Booking and scheduling logic
Real-time communication
Password security
Centralized error handling
Network connectivity handling
Modular Flutter architecture
Backend route/controller separation
Roadmap

Potential future improvements include:

Push notifications

Advanced worker search and filtering

Distance-based worker ranking

Integrated maps

Online payments

Worker earnings dashboard

Service completion verification

Chat between users and workers

Image/document uploads

Admin dashboard

Worker verification

Analytics and reporting

Automated testing and CI/CD

Production monitoring and logging

Screenshots

Add application screenshots here to showcase the user and worker experiences.

Recommended screenshots:

Login / Sign Up
Home / Service Categories
Worker Listing
Worker Details
Booking Screen
My Bookings
Worker Dashboard
Worker Booking Management
Worker Profile

Example:

docs/
└── screenshots/
    ├── login.png
    ├── home.png
    ├── workers.png
    ├── worker-details.png
    ├── booking.png
    ├── my-bookings.png
    └── worker-dashboard.png
Project Status

Status: Active Development

The project currently contains a functional full-stack foundation with Flutter mobile clients, REST APIs, MongoDB persistence, authentication, worker discovery, location functionality, booking workflows, and real-time backend infrastructure.

Contributing

Contributions, suggestions, and improvements are welcome.

Fork the repository
Create a feature branch
git checkout -b feature/your-feature
Commit your changes
git commit -m "feat: add your feature"
Push the branch
git push origin feature/your-feature
Open a Pull Request

Please keep pull requests focused, clearly describe the change, and test the affected functionality before submitting.

License

This project is currently intended for educational and development purposes.

Add an explicit open-source license such as MIT, Apache-2.0, or another appropriate license before presenting the repository as an officially licensed open-source project.

Author

Jivesh-lab

GitHub: Jivesh-lab
