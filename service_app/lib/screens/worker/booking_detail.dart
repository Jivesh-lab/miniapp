import 'package:flutter/material.dart';

import '../../core/services/api_exception.dart';
import '../../core/utils/error_message_helper.dart';
import '../../models/booking_model.dart';
import '../../services/api_service.dart';

class WorkerBookingDetailArgs {
  final WorkerBooking booking;
  final WorkerSession session;

  const WorkerBookingDetailArgs({
    required this.booking,
    required this.session,
  });
}

class BookingDetailScreen extends StatefulWidget {
  final WorkerBooking booking;
  final WorkerSession session;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.session,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _api = WorkerApiService();

  late WorkerBooking _booking;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  String? get _nextStatus {
    switch (_booking.status) {
      case WorkerBookingStatus.pending:
        return 'confirmed';
      case WorkerBookingStatus.confirmed:
        return 'in-progress';
      case WorkerBookingStatus.inProgress:
        return 'completed';
      case WorkerBookingStatus.completed:
      case WorkerBookingStatus.cancelled:
        return null;
    }
  }

  String? get _actionLabel {
    switch (_booking.status) {
      case WorkerBookingStatus.pending:
        return 'Accept';
      case WorkerBookingStatus.confirmed:
        return 'Start Work';
      case WorkerBookingStatus.inProgress:
        return 'Complete';
      case WorkerBookingStatus.completed:
      case WorkerBookingStatus.cancelled:
        return null;
    }
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(context, '/worker/bookings');
  }

  Future<void> _performStatusUpdate(String status, String successMessage) async {
    if (_isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final updated = await _api.updateBookingStatus(
        session: widget.session,
        bookingId: _booking.id,
        status: status,
      );

      await _api.getWorkerBookings(session: widget.session, forceRefresh: true);

      if (!mounted) {
        return;
      }

      setState(() {
        _booking = _booking.copyWith(status: updated.status);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      if (e is ApiException && e.statusCode == 401) {
        return;
      }

      ErrorMessageHelper.showSnackBar(context, ErrorMessageHelper.booking(e));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _updateStatus() async {
    final nextStatus = _nextStatus;
    if (nextStatus == null) {
      return;
    }
    await _performStatusUpdate(nextStatus, 'Booking status updated successfully');
  }

  Future<void> _rejectBooking() async {
    await _performStatusUpdate('rejected', 'Booking rejected successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Booking Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Customer', value: _booking.customerName),
                  _DetailRow(label: 'Contact', value: _booking.customerContact),
                  _DetailRow(label: 'Address', value: _booking.address),
                  _DetailRow(label: 'Date', value: _booking.date),
                  _DetailRow(label: 'Time', value: _booking.time),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _booking.statusColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _booking.statusLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _booking.statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_actionLabel != null) ...[
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _updateStatus,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_actionLabel ?? 'Update'),
              ),
            ),
            if (_booking.status == WorkerBookingStatus.pending) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _rejectBooking,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reject'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.trim().isEmpty ? 'Not available' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(normalizedValue)),
        ],
      ),
    );
  }
}
