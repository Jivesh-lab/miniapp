import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/models/worker_model.dart';
import 'core/navigation/app_navigator.dart';

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
  runApp(const LocalServicesApp());
}

class LocalServicesApp extends StatelessWidget {
  const LocalServicesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Services',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,

      // 🎯 THEME
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),

        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),

        scaffoldBackgroundColor: const Color(0xFFF9FAFB),

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF2563EB),
              width: 2,
            ),
          ),
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
        ),
      ),

      initialRoute: '/login',

      routes: {
        '/': (context) => const LoginScreen(),
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