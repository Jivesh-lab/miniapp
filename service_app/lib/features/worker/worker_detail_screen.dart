import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/worker_model.dart';

class WorkerDetailScreen extends StatefulWidget {
  final WorkerModel worker;

  const WorkerDetailScreen({
    Key? key,
    required this.worker,
  }) : super(key: key);

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final padding = isMobile ? 16.0 : 24.0;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(isMobile),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                padding,
                0,
                padding,
                100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Profile Section
                  _buildProfileSection(isMobile),
                  const SizedBox(height: 24),

                  // Info Cards
                  _buildInfoCards(isMobile, padding),
                  const SizedBox(height: 24),

                  // Skills Section
                  _buildSkillsSection(isMobile, padding),
                  const SizedBox(height: 24),

                  // Reviews Section
                  _buildReviewsSection(isMobile, padding),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Sticky Book Now Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBookingButton(isMobile, padding),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildAppBar(bool isMobile) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() => _isFavorite = !_isFavorite);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isMobile) {
    return Center(
      child: Column(
        children: [
          // Avatar
          Container(
            width: isMobile ? 80 : 100,
            height: isMobile ? 80 : 100,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                widget.worker.avatar,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 32 : 40,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            widget.worker.name,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 22 : 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          // Rating Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.worker.rating}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${widget.worker.reviews} reviews)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Experience Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.worker.experience} years experience',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              widget.worker.profileDescription,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(bool isMobile, double padding) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Distance',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.worker.distance} km',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.currency_rupee,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Per Hour',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.worker.pricePerHour}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(bool isMobile, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills & Expertise',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.worker.skills
              .map(
                (skill) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(bool isMobile, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Reviews',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            Text(
              'See all',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.worker.aboutReviews
            .map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            review['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.star_rounded,
                                color: index < (review['rating'] as int)
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        review['comment'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        review['date'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildBookingButton(bool isMobile, double padding) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.all(padding).copyWith(
        top: 12,
        bottom: 12,
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/booking',
                    arguments: widget.worker,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Book Now',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingConfirmation() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Booking Confirmation',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              _buildConfirmationItem(
                'Service Provider',
                widget.worker.name,
              ),
              const SizedBox(height: 12),
              _buildConfirmationItem(
                'Service Price',
                '₹${widget.worker.pricePerHour}',
              ),
              const SizedBox(height: 12),
              _buildConfirmationItem(
                'Rating',
                '${widget.worker.rating} ⭐',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Booking request sent to ${widget.worker.name}!',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Confirm Booking',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}