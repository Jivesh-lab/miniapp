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

```text
Pending → Confirmed → In Progress → Completed
```

Additional states include **Rejected** and **Cancelled**.

The database also enforces worker/date/time uniqueness to prevent duplicate bookings for the same worker and time slot.

### ⚡ Real-Time Communication

The backend integrates **Socket.IO** to support real-time application events, including:

- Booking updates
- Worker status changes
- Availability updates
- User/worker synchronization

---

## 🛠️ Tech Stack

### Mobile Application

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile application |
| Dart | Application development |
| Google Fonts | Typography |
| HTTP | REST API communication |
| Socket.IO Client | Real-time communication |
| Geolocator | Device location |
| Geocoding | Location and address conversion |
| Shared Preferences | Local persistence |
| Connectivity Plus | Network connectivity detection |
| WebView | Web content integration |
| URL Launcher | External URL handling |

The Flutter project currently targets **Dart SDK `^3.11.4`**.

### Backend

| Technology | Purpose |
|---|---|
| Node.js | Server runtime |
| Express.js | REST API |
| MongoDB | Database |
| Mongoose | MongoDB ODM |
| JWT | Authentication |
| bcryptjs | Password hashing |
| Socket.IO | Real-time communication |
| Nodemailer | Email communication |
| CORS | Cross-origin configuration |
| dotenv | Environment configuration |

The backend uses ES modules and separates routes for authentication, workers, bookings, services, users, location, and geocoding.

---

## 🏗️ Architecture

```text
┌───────────────────────────────┐
│       Flutter Mobile App      │
│                               │
│  User Experience              │
│  Worker Experience            │
│  Location Services            │
│  Booking Management           │
└───────────────┬───────────────┘
                │
          REST API / Socket.IO
                │
                ▼
┌───────────────────────────────┐
│       Node.js + Express       │
│                               │
│  Authentication               │
│  Users                        │
│  Workers                      │
│  Services                     │
│  Bookings                     │
│  Location / Geocoding         │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│            MongoDB            │
│                               │
│  Users • Workers • Services   │
│  Bookings • OTP • Blacklist   │
└───────────────────────────────┘
```

---

## 📂 Project Structure

```text
miniapp/
│
├── backend/
│   ├── src/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   ├── routes/
│   │   └── services/
│   ├── server.js
│   └── package.json
│
├── service_app/
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   └── pubspec.yaml
│
└── README.md
```

---

## 🔄 Booking Flow

```text
Select Service
      ↓
Discover Workers
      ↓
View Worker Profile
      ↓
Select Date & Time
      ↓
Enter Service Address
      ↓
Create Booking
      ↓
Worker Receives Request
      ↓
Accept / Reject
      ↓
In Progress
      ↓
Completed
      ↓
Rating & Review
```

---

## 👤 User Flow

```text
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
```

---

## 🧑‍🔧 Worker Flow

```text
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
```

---

## 🔐 Security

- JWT-based authentication
- Role-based authorization
- Password hashing with bcrypt
- Protected API routes
- Token blacklist support
- Environment-based configuration
- CORS protection
- Centralized error handling

> **Security:** Never commit database credentials, JWT secrets, email credentials, or other sensitive configuration to the repository.

---

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Node.js
- npm
- MongoDB or MongoDB Atlas
- Android Studio / Xcode
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/Jivesh-lab/miniapp.git
cd miniapp
```

### 2. Configure the Backend

```bash
cd backend
npm install
```

Create a `.env` file:

```env
PORT=5000
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
FRONTEND_URL=http://localhost:3000
```

Add any additional environment variables required by your deployment or external services.

### 3. Start the Backend

```bash
npm start
```

### 4. Seed Workers

```bash
npm run seed:workers
```

This populates development worker data for testing worker discovery and booking flows.

### 5. Run the Flutter Application

Open a new terminal:

```bash
cd service_app
flutter pub get
flutter run
```

Check the Flutter environment with:

```bash
flutter doctor
```

### Local Device Configuration

The mobile application communicates with the backend through HTTP and Socket.IO.

For a physical Android device, `localhost` refers to the device itself rather than your development computer. Use the appropriate machine/network address or deployed backend URL when testing on a physical device.

---

## 📱 Screens & Modules

The Flutter application includes:

- Splash Screen
- Login / Registration
- Home
- Worker Listing
- Worker Details
- Booking
- My Bookings
- User Profile
- Worker Dashboard
- Worker Bookings
- Worker Booking Details
- Worker Profile
- Worker Profile Completion
- No-Internet Screen

---

## 📸 Screenshots

Add application screenshots here to showcase the main user and worker experiences.

Recommended screenshots:

```text
docs/
└── screenshots/
    ├── login.png
    ├── home.png
    ├── workers.png
    ├── worker-details.png
    ├── booking.png
    ├── my-bookings.png
    └── worker-dashboard.png
```

---

## 💡 Development Highlights

This project demonstrates practical full-stack development concepts, including:

- Cross-platform mobile development
- REST API architecture
- JWT authentication
- Role-based authorization
- MongoDB data modeling
- Geospatial indexing
- Location services
- Booking and scheduling
- Real-time communication
- Password security
- Centralized error handling
- Network connectivity handling
- Modular Flutter architecture
- Backend route/controller separation

---

## 🗺️ Roadmap

- [ ] Push notifications
- [ ] Advanced worker search and filtering
- [ ] Distance-based worker ranking
- [ ] Integrated maps
- [ ] Online payments
- [ ] Worker earnings dashboard
- [ ] Service completion verification
- [ ] User-worker chat
- [ ] Image/document uploads
- [ ] Admin dashboard
- [ ] Worker verification
- [ ] Analytics and reporting
- [ ] Automated testing
- [ ] CI/CD
- [ ] Production monitoring

---

## 📌 Project Status

**Active Development**

The project currently provides a full-stack foundation for a location-aware local service marketplace with Flutter mobile clients, REST APIs, MongoDB persistence, authentication, worker discovery, location functionality, booking workflows, and real-time backend infrastructure.

---

## 🤝 Contributing

Contributions, suggestions, and improvements are welcome.

1. Fork the repository.
2. Create a feature branch:

```bash
git checkout -b feature/your-feature
```

3. Commit your changes:

```bash
git commit -m "feat: add your feature"
```

4. Push the branch:

```bash
git push origin feature/your-feature
```

5. Open a Pull Request.

Please keep pull requests focused, clearly describe the change, and test affected functionality before submitting.

---

## 📄 License

This project is currently intended for educational and development purposes.

If you plan to distribute it as open-source software, add an appropriate license such as **MIT** or **Apache-2.0**.

---

## 👨‍💻 Author

**Jivesh-lab**

GitHub: [Jivesh-lab](https://github.com/Jivesh-lab)

---

<p align="center">
  Built with Flutter • Node.js • Express.js • MongoDB • Socket.IO
</p>
