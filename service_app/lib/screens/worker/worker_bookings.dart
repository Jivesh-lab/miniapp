import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/api_exception.dart';
import '../../models/booking_model.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../services/api_service.dart';
import 'booking_detail.dart';

class WorkerBookingsScreen extends StatefulWidget {
  const WorkerBookingsScreen({super.key});

  @override
  State<WorkerBookingsScreen> createState() => _WorkerBookingsScreenState();
}

class _WorkerBookingsScreenState extends State<WorkerBookingsScreen> {
  final _api = WorkerApiService();

  WorkerSession? _session;
  Timer? _autoRefreshTimer;
  bool _didInitLoad = false;
  String _selectedFilter = 'all';
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  List<WorkerBooking> _bookings = <WorkerBooking>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitLoad) {
      return;
    }
    _didInitLoad = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is WorkerSession) {
      _session = args;
    }

    _loadBookings();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _isLoading) {
        return;
      }
      _loadBookingsQuietly();
    });
  }

  Future<void> _loadBookingsQuietly() async {
    try {
      _session ??= await _api.getSavedSession();
      final session = _session;
      if (session == null) {
        return;
      }

      final bookings = await _api.getWorkerBookings(
        session: session,
        forceRefresh: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = bookings;
        _isError = false;
        _errorMessage = null;
      });
    } catch (_) {
      // Silent auto-refresh failure; keep existing UI state.
    }
  }

  Future<void> _loadBookings({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      _session ??= await _api.getSavedSession();
      final session = _session;

      if (session == null) {
        throw Exception('Please login again');
      }

      final bookings = await _api.getWorkerBookings(
        session: session,
        forceRefresh: forceRefresh,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.statusCode == 401) {
        setState(() {
          _bookings = <WorkerBooking>[];
          _isLoading = false;
          _isError = true;
          _errorMessage = ErrorMessageHelper.auth(error);
        });
        await ErrorMessageHelper.showSessionExpiredDialog(
          context,
          message: ErrorMessageHelper.auth(error),
          loginRoute: '/login',
        );
        return;
      }

      if (error.statusCode == 404) {
        setState(() {
          _bookings = <WorkerBooking>[];
          _isLoading = false;
          _isError = false;
          _errorMessage = null;
        });
        return;
      }

      setState(() {
        _bookings = <WorkerBooking>[];
        _isLoading = false;
        _isError = true;
        _errorMessage = ErrorMessageHelper.generic(error);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = <WorkerBooking>[];
        _isLoading = false;
        _isError = true;
        _errorMessage = ErrorMessageHelper.generic(error);
      });
    }
  }

  List<WorkerBooking> _applyFilter(List<WorkerBooking> bookings) {
    if (_selectedFilter == 'all') {
      return bookings;
    }

    return bookings
        .where((booking) => booking.statusValue == _selectedFilter)
        .toList();
  }

  Future<void> _refresh() async {
    await _loadBookings(forceRefresh: true);
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    ConnectivityService.ensureConnectedOrShow(context).then((ok) {
      if (ok) Navigator.pushReplacementNamed(context, '/worker/dashboard');
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: Text(
          'Assigned Bookings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              if (!await ConnectivityService.ensureConnectedOrShow(context)) {
                return;
              }
              Navigator.pushNamed(context, '/worker/profile');
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          ResponsiveContent(
            maxWidth: 1120,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _SummaryStrip(bookings: _bookings),
          ),
          ResponsiveContent(
            maxWidth: 1120,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _FilterBar(
              selectedFilter: _selectedFilter,
              onChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError) {
      return _ErrorView(
        message: _errorMessage ?? ErrorMessageHelper.genericApiFailure,
        onRetry: _refresh,
      );
    }

    final bookings = _applyFilter(_bookings);
    if (bookings.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            'No bookings found for this filter',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ResponsiveContent(
        maxWidth: 1120,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BookingCard(
                booking: booking,
                onTap: () async {
                  final session = _session;
                  if (session == null) {
                    ErrorMessageHelper.showSnackBar(
                      context,
                      'Please login again',
                    );
                    return;
                  }

                  final updated = await Navigator.pushNamed(
                    context,
                    '/worker/booking-detail',
                    arguments: WorkerBookingDetailArgs(
                      booking: booking,
                      session: session,
                    ),
                  );

                  if (updated == true) {
                    await _refresh();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selectedFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const filters = ['all', 'pending', 'confirmed', 'completed'];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final active = selectedFilter == filter;

          return ChoiceChip(
            label: Text(
              _label(filter),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            selected: active,
            onSelected: (_) => onChanged(filter),
            showCheckmark: false,
            side: BorderSide(
              color: active ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
            ),
            selectedColor: const Color(0xFFDBEAFE),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  String _label(String filter) {
    if (filter == 'all') {
      return 'All';
    }
    if (filter == 'pending') {
      return 'Pending';
    }
    if (filter == 'confirmed') {
      return 'Confirmed';
    }
    if (filter == 'completed') {
      return 'Completed';
    }
    return filter;
  }
}

class _SummaryStrip extends StatelessWidget {
  final List<WorkerBooking> bookings;

  const _SummaryStrip({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final total = bookings.length;
    final pending = bookings
        .where((booking) => booking.status == WorkerBookingStatus.pending)
        .length;
    final inProgress = bookings
        .where((booking) => booking.status == WorkerBookingStatus.inProgress)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _MiniStat(label: 'Total', value: total.toString()),
          _DividerLine(),
          _MiniStat(label: 'Pending', value: pending.toString()),
          _DividerLine(),
          _MiniStat(label: 'In Progress', value: inProgress.toString()),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 1,
      height: 36,
      color: const Color(0xFFE5E7EB),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF374151)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final WorkerBooking booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.customerName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: booking.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.statusLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: booking.statusColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${booking.date} at ${booking.time}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
