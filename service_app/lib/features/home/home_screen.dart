import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/category_card.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../worker/worker_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {
      'icon': Icons.plumbing,
      'label': 'Plumber',
      'color': 0xFF3B82F6,
    },
    {
      'icon': Icons.flash_on,
      'label': 'Electrician',
      'color': 0xFFF59E0B,
    },
    {
      'icon': Icons.cleaning_services,
      'label': 'Cleaner',
      'color': 0xFF8B5CF6,
    },
    {
      'icon': Icons.ac_unit,
      'label': 'AC Repair',
      'color': 0xFF06B6D4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              child: SearchBarWidget(
                onChanged: (value) {
                  // Handle search
                },
              ),
            ),
            // Section Title
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 8,
              ),
              child: Text(
                'Popular Services',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            // Categories Grid
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 8,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 4,
                  crossAxisSpacing: isMobile ? 12 : 16,
                  mainAxisSpacing: isMobile ? 12 : 16,
                  childAspectRatio: 1,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryCard(
                    icon: category['icon'],
                    label: category['label'],
                    color: Color(category['color']),
                    onTap: () {
                      _navigateToWorkerList(context, category['label']);
                    },
                  );
                },
              ),
            ),
            // Featured Section
            Padding(
              padding: EdgeInsets.only(
                left: isMobile ? 16 : 24,
                right: isMobile ? 16 : 24,
                top: 24,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Choose Us?',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.verified_user,
                    'Verified Professionals',
                    'All professionals are verified and background checked',
                    isMobile,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.shield,
                    'Secure Payments',
                    'Transparent pricing with no hidden charges',
                    isMobile,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.schedule,
                    'Quick Booking',
                    'Book services within minutes at your convenience',
                    isMobile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        title: Text(
          'Kalamboli',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              _selectedNavIndex = 2;
              setState(() {});
              Navigator.pushNamed(context, '/profile');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, '/my-bookings');
          }
          if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _selectedNavIndex == 0 ? Icons.home : Icons.home_outlined,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedNavIndex == 1
                  ? Icons.calendar_today
                  : Icons.calendar_today_outlined,
            ),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedNavIndex == 2 ? Icons.person : Icons.person_outline,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _navigateToWorkerList(BuildContext context, String serviceType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerListScreen(serviceType: serviceType),
      ),
    );
  }
}