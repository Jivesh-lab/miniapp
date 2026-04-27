import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/models/worker_model.dart';
import '../../core/utils/error_message_helper.dart';
import '../../core/services/location_service.dart';
import '../../core/services/worker_service.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/worker_card.dart';
import 'worker_detail_screen.dart';

class WorkerListScreen extends StatefulWidget {
  final String? serviceId;
  final String? serviceName;

  const WorkerListScreen({Key? key, this.serviceId, this.serviceName})
    : super(key: key);

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  String _selectedSort = 'nearest';
  String _searchQuery = '';
  double _minRating = 0;
  RangeValues _priceRange = const RangeValues(100, 500);
  final WorkerService _workerService = WorkerService();
  bool _isLoading = true;
  String? _errorMessage;
  double? _userLatitude;
  double? _userLongitude;
  Timer? _refreshTimer;

  List<WorkerModel> _workers = [];

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted || _isLoading) {
        return;
      }
      _fetchWorkers();
    });
    _loadLocationAndWorkers();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocationAndWorkers() async {
    final location = await LocationService.getUserLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      _userLatitude = location?.latitude;
      _userLongitude = location?.longitude;
    });

    await _fetchWorkers();
  }

  bool _isFallback = false;

  Future<void> _fetchWorkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFallback = false;
    });

    try {
      final sort = _selectedSort == 'rating' || _selectedSort == 'price'
          ? _selectedSort
          : null;

      final response = await _workerService.getWorkers(
        serviceId: (widget.serviceId ?? '').trim(),
        sort: sort,
        q: _searchQuery,
        rating: _minRating > 0 ? _minRating : null,
        minPrice: _priceRange.start.round(),
        maxPrice: _priceRange.end.round(),
        page: 1,
        limit: 1000,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
      );

      if (!mounted) return;
      setState(() {
        _workers = response.workers;
        _isFallback = response.isFallback;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ErrorMessageHelper.showSnackBar(
        context,
        ErrorMessageHelper.workerList(e),
      );
      setState(() {
        _errorMessage = ErrorMessageHelper.workerList(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Column(
            children: [
              ResponsiveContent(
                maxWidth: 1160,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SearchBarWidget(
                            hintText: 'Search workers or skills',
                            onChanged: (value) {
                              _searchQuery = value;
                              _fetchWorkers();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _openFilterModal,
                          icon: const Icon(Icons.tune),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSortChip('Nearest', 'nearest'),
                            const SizedBox(width: 8),
                            _buildSortChip('Rating', 'rating'),
                            const SizedBox(width: 8),
                            _buildSortChip('Price', 'price'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBodyContent(width)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBodyContent(double width) {
    final isWide = width >= 980;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.red.shade600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchWorkers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_workers.isEmpty) {
      return const Center(
        child: Text('No workers available'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isFallback)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              "Showing all matching workers sorted by nearest distance",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchWorkers,
            child: ResponsiveContent(
              maxWidth: 1160,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: isWide
                  ? GridView.builder(
                      itemCount: _workers.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.55,
                      ),
                      itemBuilder: (context, index) {
                        return WorkerCard(
                          worker: _workers[index],
                          onTap: () =>
                              _navigateToWorkerDetail(context, _workers[index]),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: _workers.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: WorkerCard(
                            worker: _workers[index],
                            onTap: () =>
                                _navigateToWorkerDetail(context, _workers[index]),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSize _buildAppBar() {
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
          '${widget.serviceName ?? 'Service'} Workers',
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

  Widget _buildSortChip(String label, String value) {
    final isSelected = _selectedSort == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSort = value;
        });
        _fetchWorkers();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  void _navigateToWorkerDetail(BuildContext context, WorkerModel worker) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return WorkerDetailScreen(workerId: worker.id);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  void _openFilterModal() {
    RangeValues tempRange = _priceRange;
    double tempRating = _minRating;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Minimum Rating: ${tempRating.toStringAsFixed(1)}'),
                    Slider(
                      value: tempRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      onChanged: (value) {
                        setModalState(() => tempRating = value);
                      },
                    ),
                    Text(
                      'Price Range: ₹${tempRange.start.round()} - ₹${tempRange.end.round()}',
                    ),
                    RangeSlider(
                      values: tempRange,
                      min: 100,
                      max: 1000,
                      divisions: 18,
                      onChanged: (value) {
                        setModalState(() => tempRange = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _minRating = tempRating;
                            _priceRange = tempRange;
                          });
                          Navigator.pop(context);
                          _fetchWorkers();
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
