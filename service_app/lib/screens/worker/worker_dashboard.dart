import 'package:flutter/material.dart';

import '../../core/services/api_exception.dart';
import '../../models/booking_model.dart';
import '../../core/utils/error_message_helper.dart';
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
    Navigator.pushNamedAndRemoveUntil(context, '/worker/login', (route) => false);
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Worker Dashboard'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
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
    final pending = _bookings.where((b) => b.status == WorkerBookingStatus.pending).length;
    final completed = _bookings.where((b) => b.status == WorkerBookingStatus.completed).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(title: 'Total Bookings', value: total.toString(), color: Colors.black87),
        const SizedBox(height: 12),
        _StatCard(title: 'Pending', value: pending.toString(), color: Colors.orange),
        const SizedBox(height: 12),
        _StatCard(title: 'Completed', value: completed.toString(), color: Colors.green),
        const SizedBox(height: 20),
        ElevatedButton.icon(
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
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: color),
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

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
