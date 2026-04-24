import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/models/worker_model.dart';
import 'core/navigation/app_navigator.dart';
import 'features/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'features/auth/loginscreen.dart';
import 'features/auth/signup_screen.dart';
import 'features/worker/worker_list_screen.dart';
import 'features/worker/worker_detail_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/my_bookings/my_bookings_screen.dart';
import 'features/profie_screen.dart/profile_screen.dart';
import 'screens/worker/worker_login.dart';
import 'screens/worker/worker_dashboard.dart';
import 'screens/worker/worker_bookings.dart';
import 'screens/worker/booking_detail.dart';
import 'screens/worker/worker_profile_completion_screen.dart';

void main() {
  runApp(const ServiceApp());
}

class ServiceApp extends StatelessWidget {
  const ServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Service App',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        textTheme: GoogleFonts.manropeTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color(0xFF0F766E), width: 2),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/worker-list': (context) => const WorkerListScreen(),
        '/my-bookings': (context) => const MyBookingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/worker/login': (context) => const WorkerLoginScreen(),
        '/worker/complete-profile': (context) => const WorkerProfileCompletionScreen(),
        '/worker/dashboard': (context) => const WorkerDashboardScreen(),
        '/worker/bookings': (context) => const WorkerBookingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/worker-detail') {
          final workerId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => WorkerDetailScreen(workerId: workerId),
          );
        }

        if (settings.name == '/booking') {
          final worker = settings.arguments as WorkerModel;
          return MaterialPageRoute(
            builder: (context) => BookingScreen(worker: worker),
          );
        }

        if (settings.name == '/worker/booking-detail') {
          final args = settings.arguments as WorkerBookingDetailArgs;
          return MaterialPageRoute(
            builder: (context) => BookingDetailScreen(
              booking: args.booking,
              session: args.session,
            ),
          );
        }

        return null;
      },
    );
  }
}
