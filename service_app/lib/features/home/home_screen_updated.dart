import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/api_exception.dart';
import '../../core/services/service_service.dart';
import '../../core/widgets/category_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../worker/worker_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  final ServiceService _serviceService = ServiceService();
  bool _isLoadingServices = true;
  String? _serviceError;
  List<ServiceItem> _services = [];
  String? _userName;
  String? _userLocation = 'Your Location';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchServices();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name') ?? 'Guest';
      setState(() {
        _userName = name;
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoadingServices = true;
      _serviceError = null;
    });

    try {
      final data = await _serviceService.getServices();
      if (!mounted) return;
      setState(() {
        _services = data;
        _isLoadingServices = false;
      });
    } catch (e) {
      if (!mounted) return;

      if (e is ApiException && e.statusCode == 401) {
        return;
      }

      setState(() {
        _serviceError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingServices = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = AppBreakpoints.isMobile(width);

          return SingleChildScrollView(
            child: ResponsiveContent(
              maxWidth: 1160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // 🎯 USER GREETING SECTION (NEW)
                  _buildGreetingSection(),
                  
                  const SizedBox(height: 28),
                  
                  // Search Bar
                  SearchBarWidget(onChanged: (value) {}),
                  const SizedBox(height: 20),
                  
                  // Services Title
                  Text(
                    'Popular Services',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Services Grid
                  _buildServicesGrid(width),
                  const SizedBox(height: 28),
                  
                  // Why Choose Us Section
                  Text(
                    'Why Choose Us?',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Features Grid
                  _buildFeatureGrid(width),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// 🎯 NEW: Greeting section with user name and location
  Widget _buildGreetingSection() {
    final greeting = _getTimeBasedGreeting();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting with emoji
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$greeting ',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                TextSpan(
                  text: _userName ?? 'Guest',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                TextSpan(
                  text: ' 👋',
                  style: GoogleFonts.spaceGrotesk(fontSize: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtext
          Text(
            'Welcome back!',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Location with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _userLocation ?? 'Your Location',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Widget _buildServicesGrid(double width) {
    if (_isLoadingServices) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_serviceError != null) {
      return Center(
        child: Column(
          children: [
            Text(
              _serviceError!,
              style: GoogleFonts.inter(color: Colors.red.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchServices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final columns = AppBreakpoints.gridColumns(
      width,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: columns >= 4 ? 1.05 : 1,
      ),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return CategoryCard(
          icon: _iconForService(service.name),
          label: service.name,
          color: _colorForService(service.name),
          onTap: () {
            _navigateToWorkerList(context, service.id, service.name);
          },
        );
      },
    );
  }

  Widget _buildFeatureGrid(double width) {
    final isDesktop = AppBreakpoints.isDesktop(width);
    final itemWidth = isDesktop ? ((width - 32) / 2) : width;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: itemWidth,
          child: _buildFeatureItem(
            Icons.verified_user,
            'Verified Professionals',
            'All professionals are verified and background checked',
            AppBreakpoints.isMobile(width),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _buildFeatureItem(
            Icons.shield,
            'Secure Payments',
            'Transparent pricing with no hidden charges',
            AppBreakpoints.isMobile(width),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _buildFeatureItem(
            Icons.schedule,
            'Quick Booking',
            'Book services within minutes at your convenience',
            AppBreakpoints.isMobile(width),
          ),
        ),
      ],
    );
  }

  IconData _iconForService(String name) {
    final key = name.toLowerCase();
    if (key.contains('plumb')) return Icons.plumbing;
    if (key.contains('electric')) return Icons.flash_on;
    if (key.contains('clean')) return Icons.cleaning_services;
    if (key.contains('ac')) return Icons.ac_unit;
    return Icons.home_repair_service;
  }

  Color _colorForService(String name) {
    final key = name.toLowerCase();
    if (key.contains('plumb')) return const Color(0xFF3B82F6);
    if (key.contains('electric')) return const Color(0xFFF59E0B);
    if (key.contains('clean')) return const Color(0xFF8B5CF6);
    if (key.contains('ac')) return const Color(0xFF06B6D4);
    return const Color(0xFF10B981);
  }

  PreferredSize _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () async {
            if (!await ConnectivityService.ensureConnectedOrShow(context)) {
              return;
            }
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        title: Text(
          _userLocation ?? 'Kalamboli',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              if (!await ConnectivityService.ensureConnectedOrShow(context)) {
                return;
              }
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
            child: Icon(icon, color: AppColors.primary, size: 20),
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
                    fontWeight: FontWeight.w400,
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

  void _navigateToWorkerList(BuildContext context, String serviceId, String serviceName) {
    ConnectivityService.ensureConnectedOrShow(context).then((ok) {
      if (!ok) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkerListScreen(
            serviceId: serviceId,
            serviceName: serviceName,
          ),
        ),
      );
    });
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        setState(() {
          _selectedNavIndex = index;
        });

        switch (index) {
          case 0:
            break;
          case 1:
            ConnectivityService.ensureConnectedOrShow(context).then((ok) {
              if (ok) Navigator.pushNamed(context, '/my-bookings');
            });
            break;
          case 2:
            ConnectivityService.ensureConnectedOrShow(context).then((ok) {
              if (ok) Navigator.pushNamed(context, '/profile');
            });
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
