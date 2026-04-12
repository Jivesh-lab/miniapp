import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/worker_model.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/worker_service.dart';
import '../../core/utils/error_message_helper.dart';

class BookingScreen extends StatefulWidget {
  final WorkerModel worker;

  const BookingScreen({
    super.key,
    required this.worker,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _selectedDate;
  String? _selectedTimeSlot;
  late TextEditingController _addressController;
  final BookingService _bookingService = BookingService();
  final WorkerService _workerService = WorkerService();
  bool _isSubmitting = false;
  bool _isLoadingSlots = true;
  String? _slotError;
  bool _isAddressReady = false;
  List<String> _allSlots = [];
  List<String> _availableSlots = [];
  List<String> _bookedSlots = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _addressController = TextEditingController();
    _addressController.addListener(_handleAddressChange);
    _loadSlotsForDate();
  }

  @override
  void dispose() {
    _addressController.removeListener(_handleAddressChange);
    _addressController.dispose();
    super.dispose();
  }

  void _handleAddressChange() {
    final hasAddress = _addressController.text.trim().isNotEmpty;
    if (hasAddress != _isAddressReady && mounted) {
      setState(() => _isAddressReady = hasAddress);
    }
  }

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
                16,
                padding,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Worker Summary Card
                  _buildWorkerSummaryCard(isMobile, padding),
                  const SizedBox(height: 24),

                  // Date Selection Section
                  _buildDateSection(isMobile, padding),
                  const SizedBox(height: 24),

                  // Time Slots Section
                  _buildTimeSlotsSection(isMobile, padding),
                  const SizedBox(height: 24),

                  // Address Input Section
                  _buildAddressSection(isMobile, padding),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Sticky Confirm Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildConfirmButton(isMobile, padding),
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
          'Book Service',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: false,
      ),
    );
  }

  Widget _buildWorkerSummaryCard(bool isMobile, double padding) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.worker.avatar,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.worker.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.worker.rating}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        '₹${widget.worker.pricePerHour}/hr',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(bool isMobile, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedDate.day} ${_getMonthName(_selectedDate.month)}, ${_selectedDate.year}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotsSection(bool isMobile, double padding) {
    if (_isLoadingSlots) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_slotError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _slotError!,
            style: GoogleFonts.inter(color: Colors.red.shade600),
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _loadSlotsForDate, child: const Text('Retry')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        if (_allSlots.isEmpty)
          Text(
            'No slots available for selected date',
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allSlots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final slot = _allSlots[index];
              final isBooked = _bookedSlots.contains(slot);
              final isSelected = _selectedTimeSlot == slot;

              return GestureDetector(
                onTap: isBooked
                    ? null
                    : () {
                        setState(() => _selectedTimeSlot = slot);
                      },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isBooked
                        ? Colors.grey.shade200
                        : isSelected
                            ? AppColors.primary
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBooked
                          ? Colors.grey.shade300
                          : isSelected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    slot,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isBooked
                          ? Colors.grey.shade500
                          : isSelected
                              ? Colors.white
                              : const Color(0xFF1F2937),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAddressSection(bool isMobile, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Address',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _addressController,
            maxLines: 3,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter service address...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            cursorColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(bool isMobile, double padding) {
    final isFormValid = _selectedTimeSlot != null && _isAddressReady;

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
      padding: EdgeInsets.all(padding).copyWith(top: 12, bottom: 12),
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
                onTap: isFormValid && !_isSubmitting ? _confirmBooking : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.check_circle_outline,
                              color: Colors.white.withOpacity(isFormValid ? 1 : 0.5),
                              size: 20,
                            ),
                      const SizedBox(width: 8),
                      Text(
                        _isSubmitting ? 'Booking...' : 'Confirm Booking',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(isFormValid ? 1 : 0.5),
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

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year, now.month + 2, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
      _loadSlotsForDate();
    }
  }

  Future<void> _loadSlotsForDate() async {
    setState(() {
      _isLoadingSlots = true;
      _slotError = null;
    });

    try {
      final date = _selectedDate.toIso8601String().split('T').first;
      final slots = await _workerService.getWorkerSlots(
        workerId: widget.worker.id,
        date: date,
      );

      if (!mounted) return;

      setState(() {
        _allSlots = List<String>.from(
          (slots['allSlots'] ?? slots['availableSlots'] ?? <dynamic>[]) as List<dynamic>,
        );
        _availableSlots = List<String>.from((slots['availableSlots'] ?? <dynamic>[]) as List<dynamic>);
        _bookedSlots = List<String>.from((slots['bookedSlots'] ?? <dynamic>[]) as List<dynamic>);

        // Ensure stale selections cannot be submitted.
        if (_selectedTimeSlot != null && _bookedSlots.contains(_selectedTimeSlot)) {
          _selectedTimeSlot = null;
        }
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = ErrorMessageHelper.booking(e);
      setState(() {
        _slotError = message;
        _isLoadingSlots = false;
      });
      ErrorMessageHelper.showSnackBar(context, message);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedTimeSlot == null || _addressController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _bookingService.createBooking({
        'userId': 'demo-user-1',
        'workerId': widget.worker.id,
        'date': _selectedDate.toIso8601String().split('T').first,
        'time': _selectedTimeSlot,
        'address': _addressController.text.trim(),
      });

      if (!mounted) return;

      await _loadSlotsForDate();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking confirmed!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pushNamed(context, '/my-bookings');
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ErrorMessageHelper.booking(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getMonthName(int month) {
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
    return months[month - 1];
  }
}