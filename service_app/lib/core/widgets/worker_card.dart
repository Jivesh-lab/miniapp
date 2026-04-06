import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/worker_model.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback? onTap;

  const WorkerCard({
    Key? key,
    required this.worker,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  worker.avatar,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
                const SizedBox(width: 12),
                // Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name
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
                      // Rating Row
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
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
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${worker.distance} km away',
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
                      const SizedBox(height: 6),
                      // Price and Availability Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                          ),
                          const SizedBox(width: 8),
                          if (worker.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Available',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow Icon
                Container(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}