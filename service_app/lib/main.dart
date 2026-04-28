import 'package:flutter/material.dart';

import 'core/config/app_theme.dart';
import 'core/models/worker_model.dart';
import 'core/navigation/app_navigator.dart';
import 'features/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'features/no_internet_screen.dart';
import 'features/auth/loginscreen.dart';
import 'features/auth/signup_screen.dart';
import 'features/worker/worker_list_screen.dart';
import 'features/worker/worker_detail_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/my_bookings/my_bookings_screen.dart';
import 'features/profie_screen.dart/profile_screen.dart';
import 'screens/worker/worker_dashboard.dart';
import 'screens/worker/worker_bookings.dart';
import 'screens/worker/booking_detail.dart';
import 'screens/worker/worker_profile_completion_screen.dart';
import 'screens/worker/worker_profile_screen.dart';

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
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/no-internet': (context) => const NoInternetScreen(),
        '/worker-list': (context) => const WorkerListScreen(),
        '/my-bookings': (context) => const MyBookingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/worker/complete-profile': (context) => const WorkerProfileCompletionScreen(),
        '/worker/dashboard': (context) => const WorkerDashboardScreen(),
        '/worker/bookings': (context) => const WorkerBookingsScreen(),
        '/worker/profile': (context) => const WorkerProfileScreen(),
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

