import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;

  const BookingCard({
    Key? key,
    required this.booking,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Worker Name and Status
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.workerName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.serviceType,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(),
                ],
              ),
            ),
            // Divider
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatDate(booking.date)} at ${booking.timeSlot}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.address,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Footer with Booking ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking ID: ${booking.id}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isCompleted = booking.status == BookingStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isCompleted ? 'Completed' : 'Pending',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == tomorrow) {
      return 'Tomorrow';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    }
  }
}