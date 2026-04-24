import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/api_exception.dart';
import '../../core/utils/error_message_helper.dart';
import '../../models/booking_model.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../services/api_service.dart';

class WorkerBookingDetailArgs {
  final WorkerBooking booking;
  final WorkerSession session;

  const WorkerBookingDetailArgs({required this.booking, required this.session});
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

  Future<void> _performStatusUpdate(
    String status,
    String successMessage,
  ) async {
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      if (e is ApiException && e.statusCode == 401) {
        await ErrorMessageHelper.showSessionExpiredDialog(
          context,
          message: ErrorMessageHelper.auth(e),
          loginRoute: '/worker/login',
        );
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
    await _performStatusUpdate(
      nextStatus,
      'Booking status updated successfully',
    );
  }

  Future<void> _rejectBooking() async {
    await _performStatusUpdate('rejected', 'Booking rejected successfully');
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
        title: const Text('Booking Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ResponsiveContent(
            maxWidth: 900,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job details',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(label: 'Customer', value: _booking.customerName),
                  _DetailRow(label: 'Contact', value: _booking.customerContact),
                  _DetailRow(label: 'Address', value: _booking.address),
                  _DetailRow(label: 'Date', value: _booking.date),
                  _DetailRow(label: 'Time', value: _booking.time),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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
          const SizedBox(height: 14),
          if (_actionLabel != null)
            ResponsiveContent(
              maxWidth: 900,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _updateStatus,
                      icon: const Icon(Icons.task_alt),
                      label: _isProcessing
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
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _rejectBooking,
                        icon: const Icon(Icons.cancel_outlined),
                        label: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Reject Booking'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.trim().isEmpty ? 'Not available' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            normalizedValue,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
