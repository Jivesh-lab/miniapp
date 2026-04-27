import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/worker_model.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback? onTap;

  const WorkerCard({Key? key, required this.worker, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
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
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: isCompact ? _buildCompactContent() : _buildWideContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar({double size = 70}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size / 5),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
      ),
      child: Center(
        child: Text(
          worker.avatar,
          style: GoogleFonts.inter(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMetaText() {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          '${worker.rating}',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${worker.reviews})',
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPriceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '₹${worker.pricePerHour}',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildAvailabilityChip() {
    final isOnline = worker.isOnline;
    final backgroundColor = isOnline ? Colors.green.shade50 : Colors.grey.shade100;
    final textColor = isOnline ? Colors.green.shade700 : Colors.grey.shade700;
    final label = isOnline ? 'Online' : 'Offline';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _distanceLabel() {
    final formatted = worker.distanceFormatted?.trim();
    if (formatted != null && formatted.isNotEmpty) {
      return '$formatted away';
    }

    final distance = worker.distance;
    if (distance == null) {
      return 'Location unavailable';
    }

    if (distance < 1) {
      final meters = (distance * 1000).round();
      return '$meters m away';
    }

    return '${distance.toStringAsFixed(distance % 1 == 0 ? 0 : 1)} km away';
  }

  String? _lastSeenLabel() {
    if (worker.isOnline || worker.lastLocationUpdate == null) {
      return null;
    }

    final difference = DateTime.now().difference(worker.lastLocationUpdate!);
    if (difference.inMinutes < 1) {
      return 'last seen just now';
    }
    if (difference.inHours < 1) {
      return 'last seen ${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return 'last seen ${difference.inHours} hr ago';
    }
    return 'last seen ${difference.inDays} d ago';
  }

  Widget _buildArrowIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.arrow_forward_ios,
        color: AppColors.primary,
        size: 16,
      ),
    );
  }

  Widget _buildWideContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                worker.name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildMetaText(),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _distanceLabel(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_lastSeenLabel() != null) ...[
                const SizedBox(height: 4),
                Text(
                  _lastSeenLabel()!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [_buildPriceChip(), _buildAvailabilityChip()],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildArrowIcon(),
      ],
    );
  }

  Widget _buildCompactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAvatar(size: 58),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildMetaText(),
                ],
              ),
            ),
            _buildArrowIcon(),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _distanceLabel(),
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
        ),
        if (_lastSeenLabel() != null) ...[
          const SizedBox(height: 4),
          Text(
            _lastSeenLabel()!,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [_buildPriceChip(), _buildAvailabilityChip()],
        ),
      ],
    );
  }
}
