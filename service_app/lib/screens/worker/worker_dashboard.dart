import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_exception.dart';
import '../../models/booking_model.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../services/api_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/worker_location_sync_service.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final _api = WorkerApiService();
  final _locationSync = WorkerLocationSyncService();
  WorkerSession? _session;
  bool _didInitLoad = false;
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  List<WorkerBooking> _bookings = <WorkerBooking>[];

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socket = SocketService().socket;
    if (socket != null) {
      socket.on('new_booking', (data) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have a new booking request!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadDashboard(forceRefresh: true);
      });

      socket.on('booking_status_updated', (data) {
        if (!mounted) return;
        _loadDashboard(forceRefresh: true);
      });
    }
  }

  @override
  void dispose() {
    _locationSync.stop();
    super.dispose();
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

    _loadDashboard();
  }

  Future<void> _loadDashboard({bool forceRefresh = false}) async {
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

      await _locationSync.start();

      final bookings = await _api.getWorkerBookings(
        session: session,
        forceRefresh: forceRefresh,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = bookings;
        _isError = false;
        _errorMessage = null;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.statusCode == 401) {
        setState(() {
          _bookings = <WorkerBooking>[];
          _isError = true;
          _errorMessage = ErrorMessageHelper.auth(error);
          _isLoading = false;
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
          _isError = false;
          _errorMessage = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _bookings = <WorkerBooking>[];
          _isError = true;
          _errorMessage = ErrorMessageHelper.generic(error);
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = <WorkerBooking>[];
        _isError = true;
        _errorMessage = ErrorMessageHelper.generic(error);
        _isLoading = false;
      });
    }
  }

  void _openProfile() {
    Navigator.pushNamed(context, '/worker/profile');
  }

  void _openBookings() {
    if (_session == null) {
      return;
    }
    Navigator.pushNamed(
      context,
      '/worker/bookings',
      arguments: _session,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Worker Dashboard',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError) {
      return _ErrorState(
        message: _errorMessage ?? ErrorMessageHelper.genericApiFailure,
        onRetry: () => _loadDashboard(forceRefresh: true),
      );
    }

    final total = _bookings.length;
    final pending = _bookings
        .where((b) => b.status == WorkerBookingStatus.pending)
        .length;
    final confirmed = _bookings
        .where((b) => b.status == WorkerBookingStatus.confirmed)
        .length;
    final completed = _bookings
        .where((b) => b.status == WorkerBookingStatus.completed)
        .length;
    final activeBooking = _bookings.cast<WorkerBooking?>().firstWhere(
        (b) =>
          b != null &&
          (b.status == WorkerBookingStatus.pending ||
            b.status == WorkerBookingStatus.confirmed ||
            b.status == WorkerBookingStatus.inProgress),
        orElse: () => null,
      );

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(forceRefresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = AppBreakpoints.gridColumns(
            width,
            mobile: 1,
            tablet: 2,
            desktop: 4,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ResponsiveContent(
                maxWidth: 760,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today overview',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your assigned jobs and keep delivery on schedule.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1F2937),
                          fontSize: 18,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (activeBooking != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm_on_rounded, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${activeBooking.customerName} • ${activeBooking.date} ${activeBooking.time}',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1F2937),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ResponsiveContent(
                maxWidth: 760,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  childAspectRatio: columns == 1 ? 2.5 : 1.7,
                  children: [
                    _StatCard(
                      title: 'Total Bookings',
                      value: total.toString(),
                      icon: Icons.assignment_outlined,
                      color: const Color(0xFF111827),
                    ),
                    _StatCard(
                      title: 'Pending',
                      value: pending.toString(),
                      icon: Icons.schedule,
                      color: const Color(0xFFF59E0B),
                    ),
                    _StatCard(
                      title: 'Confirmed',
                      value: confirmed.toString(),
                      icon: Icons.verified,
                      color: const Color(0xFF2563EB),
                    ),
                    _StatCard(
                      title: 'Completed',
                      value: completed.toString(),
                      icon: Icons.task_alt,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ResponsiveContent(
                maxWidth: 760,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick actions',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Open your bookings to accept, start, or complete work updates.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openBookings,
                          icon: const Icon(Icons.list_alt),
                          label: const Text('View Bookings'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openProfile,
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: const Text('Open Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 30, color: Colors.grey),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
