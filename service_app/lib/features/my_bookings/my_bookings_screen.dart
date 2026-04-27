import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_exception.dart';
import '../../core/models/booking_model.dart';
import '../../core/services/api_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/widgets/booking_card.dart';
import '../../core/widgets/responsive_layout.dart';

class MyBookingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MyBookingsScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRatingDialogVisible = false;
  bool _isSubmittingRating = false;
  final Set<String> _promptedRatingBookingIds = <String>{};
  Timer? _autoRefreshTimer;

  List<BookingModel> ongoingBookings = [];
  List<BookingModel> completedBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
    });

    _fetchBookings();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Auto-refresh bookings every 10 seconds to catch updates from backend
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Only refresh if not already loading
      if (!_isLoading && mounted) {
        _fetchBookingsQuietly();
      }
    });
  }

  // Silent refresh (doesn't show loading spinner, just updates data)
  Future<void> _fetchBookingsQuietly() async {
    try {
      final userId = await ApiService.getSavedUserId();
      final allBookings = await _bookingService.getBookings(userId ?? '');

      if (!mounted) return;
      setState(() {
        ongoingBookings =
            allBookings
                .where(
                  (b) =>
                      b.status == BookingStatus.pending ||
                      b.status == BookingStatus.confirmed ||
                      b.status == BookingStatus.inProgress,
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

        completedBookings =
            allBookings
                .where((b) => b.status == BookingStatus.completed)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
      });

      _promptRatingIfNeeded();
    } catch (e) {
      // Silent fail on auto-refresh - keep existing UI state.
    }
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await ApiService.getSavedUserId();
      final allBookings = await _bookingService.getBookings(userId ?? '');

      if (!mounted) return;
      setState(() {
        ongoingBookings =
            allBookings
                .where(
                  (b) =>
                      b.status == BookingStatus.pending ||
                      b.status == BookingStatus.confirmed ||
                      b.status == BookingStatus.inProgress,
                )
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

        completedBookings =
            allBookings
                .where((b) => b.status == BookingStatus.completed)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

        _isLoading = false;
      });

      _promptRatingIfNeeded();
    } catch (e) {
      if (!mounted) return;

      if (e is ApiException && e.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired. Please login again.';
        });
        await ErrorMessageHelper.showSessionExpiredDialog(
          context,
          message: ErrorMessageHelper.auth(e),
          loginRoute: '/login',
        );
        return;
      }

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _promptRatingIfNeeded() {
    if (!mounted || _isRatingDialogVisible) {
      return;
    }

    BookingModel? target;
    for (final booking in completedBookings) {
      if (!booking.isRated && !_promptedRatingBookingIds.contains(booking.id)) {
        target = booking;
        break;
      }
    }

    if (target == null) {
      return;
    }

    final targetBooking = target;
    _isRatingDialogVisible = true;
    _promptedRatingBookingIds.add(targetBooking.id);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await _showRatingDialog(targetBooking);

      if (!mounted) {
        return;
      }

      _isRatingDialogVisible = false;

      if (result == null) {
        _promptedRatingBookingIds.remove(targetBooking.id);
        return;
      }

      if (result.skip) {
        _promptedRatingBookingIds.remove(targetBooking.id);
        return;
      }

      try {
        if (mounted) {
          setState(() => _isSubmittingRating = true);
        }

        await _bookingService.rateBooking(
          bookingId: targetBooking.id,
          rating: result.rating!,
          comment: result.comment,
        );

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your feedback!')),
        );

        await _fetchBookings();
      } catch (e) {
        _promptedRatingBookingIds.remove(targetBooking.id);

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      } finally {
        if (mounted) {
          setState(() => _isSubmittingRating = false);
        }
      }
    });
  }

  Future<_RatingDialogResult?> _showRatingDialog(BookingModel booking) {
    int? selectedRating;
    final commentController = TextEditingController();

    return showDialog<_RatingDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rate Your Service',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const _RatingDialogResult(skip: true)),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.workerName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.serviceType,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'How was your service experience?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isActive =
                            selectedRating != null &&
                            starValue <= selectedRating!;

                        return IconButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = starValue;
                            });
                          },
                          icon: Icon(
                            isActive
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: isActive
                                ? Colors.amber
                                : Colors.grey.shade400,
                            size: 30,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        hintText: 'Optional comment',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(const _RatingDialogResult(skip: true));
                  },
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedRating == null
                      ? null
                      : () {
                          Navigator.of(context).pop(
                            _RatingDialogResult(
                              skip: false,
                              rating: selectedRating,
                              comment: commentController.text,
                            ),
                          );
                        },
                  child: Text(
                    'Submit',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() => commentController.dispose());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Column(
            children: [
              ResponsiveContent(
                maxWidth: 1100,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
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
              ),
              Expanded(child: _buildContent(width)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(double width) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isSubmittingRating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.red.shade600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchBookings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTabContent(ongoingBookings, width),
        _buildTabContent(completedBookings, width),
      ],
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
            if (widget.onBack != null) {
              widget.onBack!();
              return;
            }
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

  Widget _buildTabContent(List<BookingModel> bookings, double width) {
    if (bookings.isEmpty) {
      return _buildEmptyState(AppBreakpoints.isMobile(width));
    }

    final isWide = width >= 980;

    return ResponsiveContent(
      maxWidth: 1100,
      child: isWide
          ? GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: bookings.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.28,
              ),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return BookingCard(
                  booking: booking,
                  onCancel: booking.status == BookingStatus.pending
                      ? () => _cancelBooking(booking.id)
                      : null,
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BookingCard(
                    booking: booking,
                    onCancel: booking.status == BookingStatus.pending
                        ? () => _cancelBooking(booking.id)
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _cancelBooking(String id) async {
    try {
      await _bookingService.cancelBooking(id);
      await _fetchBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_selectedTabIndex == 0)
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                  return;
                }

                Navigator.pushReplacementNamed(context, '/home');
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

class _RatingDialogResult {
  final bool skip;
  final int? rating;
  final String? comment;

  const _RatingDialogResult({required this.skip, this.rating, this.comment});
}
