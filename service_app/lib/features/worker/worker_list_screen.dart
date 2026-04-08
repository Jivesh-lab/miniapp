import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/worker_model.dart';
import '../../core/services/worker_service.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../core/widgets/worker_card.dart';
import 'worker_detail_screen.dart';

class WorkerListScreen extends StatefulWidget {
  final String? serviceId;
  final String? serviceName;

  const WorkerListScreen({
    Key? key,
    this.serviceId,
    this.serviceName,
  }) : super(key: key);

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

  List<WorkerModel> _workers = [];

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sort = _selectedSort == 'rating' || _selectedSort == 'price'
          ? _selectedSort
          : null;

      final workers = await _workerService.getWorkers(
        serviceId: (widget.serviceId ?? '').trim(),
        sort: sort,
        q: _searchQuery,
        rating: _minRating > 0 ? _minRating : null,
        minPrice: _priceRange.start.round(),
        maxPrice: _priceRange.end.round(),
        page: 1,
        limit: 20,
      );

      if (!mounted) return;
      setState(() {
        _workers = workers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isMobile),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 12, isMobile ? 16 : 24, 0),
            child: Row(
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
          ),
          // Filter/Sort Section
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSortChip('Nearest', 'nearest', isMobile),
                        const SizedBox(width: 8),
                        _buildSortChip('Rating', 'rating', isMobile),
                        const SizedBox(width: 8),
                        _buildSortChip('Price', 'price', isMobile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Worker List
          Expanded(child: _buildBodyContent(isMobile)),
        ],
      ),
    );
  }

  Widget _buildBodyContent(bool isMobile) {
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
      return const Center(child: Text('No workers found'));
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 8,
      ),
      itemCount: _workers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WorkerCard(
            worker: _workers[index],
            onTap: () => _navigateToWorkerDetail(
              context,
              _workers[index],
            ),
          ),
        );
      },
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

  Widget _buildSortChip(String label, String value, bool isMobile) {
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
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
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
                  Text('Price Range: ₹${tempRange.start.round()} - ₹${tempRange.end.round()}'),
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
            );
          },
        );
      },
    );
  }
}