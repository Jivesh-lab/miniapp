import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/booking_model.dart';
import '../../core/widgets/booking_card.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  final List<BookingModel> allBookings = [
    BookingModel(
      id: '1',
      workerId: '1',
      workerName: 'Rajesh Kumar',
      serviceType: 'Plumbing',
      date: DateTime.now().add(const Duration(days: 2)),
      timeSlot: '10:00 AM',
      address: '123 Main Street, Apartment 4B',
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    ),
    BookingModel(
      id: '2',
      workerId: '2',
      workerName: 'Vikram Singh',
      serviceType: 'Electrical',
      date: DateTime.now().subtract(const Duration(days: 5)),
      timeSlot: '2:00 PM',
      address: '456 Oak Avenue, Suite 200',
      status: BookingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    BookingModel(
      id: '3',
      workerId: '3',
      workerName: 'Suresh Nair',
      serviceType: 'Cleaning',
      date: DateTime.now().add(const Duration(days: 5)),
      timeSlot: '12:00 PM',
      address: '789 Pine Road, Floor 3',
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    ),
    BookingModel(
      id: '4',
      workerId: '1',
      workerName: 'Rajesh Kumar',
      serviceType: 'Plumbing',
      date: DateTime.now().subtract(const Duration(days: 15)),
      timeSlot: '4:00 PM',
      address: '321 Elm Street, Bungalow 5',
      status: BookingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  late List<BookingModel> ongoingBookings;
  late List<BookingModel> completedBookings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
    });

    ongoingBookings = allBookings
        .where((b) => b.status == BookingStatus.pending)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    completedBookings = allBookings
        .where((b) => b.status == BookingStatus.completed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isMobile),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(ongoingBookings, isMobile),
                _buildTabContent(completedBookings, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSize _buildAppBar(bool isMobile) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              return;
            }
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        centerTitle: false,
        title: Text(
          'My Bookings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<BookingModel> bookings, bool isMobile) {
    if (bookings.isEmpty) {
      return _buildEmptyState(isMobile);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BookingCard(booking: bookings[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Bookings Yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTabIndex == 0
                ? 'You don\'t have any ongoing bookings'
                : 'You don\'t have any completed bookings',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_selectedTabIndex == 0)
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to home to book service
              },
              icon: const Icon(Icons.add),
              label: Text(
                'Book a Service',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}