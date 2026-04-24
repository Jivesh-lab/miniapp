import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/api_exception.dart';
import '../../models/booking_model.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../services/api_service.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final _api = WorkerApiService();
  WorkerSession? _session;
  bool _didInitLoad = false;
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
          loginRoute: '/worker/login',
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

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/worker/login',
      (route) => false,
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Worker Dashboard'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
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
                maxWidth: 1120,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today overview',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track your assigned jobs and keep delivery on schedule.',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ResponsiveContent(
                maxWidth: 1120,
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
                maxWidth: 1120,
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
                          onPressed: _session == null
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    '/worker/bookings',
                                    arguments: _session,
                                  );
                                },
                          icon: const Icon(Icons.list_alt),
                          label: const Text('View Bookings'),
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
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
