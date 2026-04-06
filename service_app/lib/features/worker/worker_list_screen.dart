import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/worker_model.dart';
import '../../core/widgets/worker_card.dart';
import 'worker_detail_screen.dart';

class WorkerListScreen extends StatefulWidget {
  final String? serviceType;

  const WorkerListScreen({
    Key? key,
    this.serviceType,
  }) : super(key: key);

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  String _selectedSort = 'nearest';

  final List<WorkerModel> workers = [
    WorkerModel(
      id: '1',
      name: 'Rajesh Kumar',
      rating: 4.8,
      reviews: 156,
      distance: 1.2,
      pricePerHour: 200,
      experience: 3,
      avatar: 'RK',
      isAvailable: true,
      skills: ['General Plumbing', 'Pipe Installation', 'Leak Repair'],
      profileDescription: 'Experienced plumber with 3 years of professional experience.',
      aboutReviews: [
        {
          'name': 'Amit Sharma',
          'rating': 5,
          'comment': 'Very professional and timely service. Highly recommended!',
          'date': '2 weeks ago',
        },
        {
          'name': 'Priya Desai',
          'rating': 4,
          'comment': 'Good work quality. Took slightly longer than expected.',
          'date': '1 month ago',
        },
      ],
    ),
    WorkerModel(
      id: '2',
      name: 'Vikram Singh',
      rating: 4.6,
      reviews: 89,
      distance: 2.5,
      pricePerHour: 180,
      experience: 5,
      avatar: 'VS',
      isAvailable: true,
      skills: ['Plumbing', 'Maintenance', 'Emergency Repair'],
      profileDescription: 'Senior plumber with expertise in all plumbing services.',
      aboutReviews: [
        {
          'name': 'Rohit Patel',
          'rating': 5,
          'comment': 'Excellent service quality. Very knowledgeable.',
          'date': '3 weeks ago',
        },
      ],
    ),
    WorkerModel(
      id: '3',
      name: 'Suresh Nair',
      rating: 4.9,
      reviews: 203,
      distance: 3.1,
      pricePerHour: 220,
      experience: 7,
      avatar: 'SN',
      isAvailable: true,
      skills: ['Complex Plumbing', 'Pipe Works', 'Installation'],
      profileDescription: 'Master plumber with extensive experience in residential and commercial plumbing.',
      aboutReviews: [
        {
          'name': 'Anjali Singh',
          'rating': 5,
          'comment': 'Outstanding work! Finished ahead of schedule.',
          'date': '1 week ago',
        },
      ],
    ),
    WorkerModel(
      id: '4',
      name: 'Mohan Das',
      rating: 4.5,
      reviews: 67,
      distance: 4.2,
      pricePerHour: 160,
      experience: 2,
      avatar: 'MD',
      isAvailable: true,
      skills: ['Basic Plumbing', 'Repairs'],
      profileDescription: 'Skilled plumber specializing in residential repairs.',
      aboutReviews: [
        {
          'name': 'Neha Verma',
          'rating': 4,
          'comment': 'Good service at reasonable price.',
          'date': '2 months ago',
        },
      ],
    ),
  ];

  late List<WorkerModel> _serviceWorkers;
  late List<WorkerModel> _filteredWorkers;

  @override
  void initState() {
    super.initState();
    _serviceWorkers = _workersForService(widget.serviceType);
    _filteredWorkers = _sortWorkers(_serviceWorkers);
  }

  List<WorkerModel> _workersForService(String? serviceType) {
    if (serviceType == null || serviceType.trim().isEmpty) {
      return workers;
    }

    final loweredType = serviceType.toLowerCase();
    final matched = workers
        .where(
          (worker) => worker.skills.any(
            (skill) => skill.toLowerCase().contains(loweredType),
          ),
        )
        .toList();

    return matched.isEmpty ? workers : matched;
  }

  List<WorkerModel> _sortWorkers(List<WorkerModel> workersList) {
    switch (_selectedSort) {
      case 'nearest':
        return List.from(workersList)
          ..sort((a, b) => a.distance.compareTo(b.distance));
      case 'rating':
        return List.from(workersList)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      case 'price':
        return List.from(workersList)
          ..sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
      default:
        return workersList;
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
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 8,
              ),
              itemCount: _filteredWorkers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WorkerCard(
                    worker: _filteredWorkers[index],
                    onTap: () => _navigateToWorkerDetail(
                      context,
                      _filteredWorkers[index],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
          '${widget.serviceType ?? 'Service'} Workers',
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
          _filteredWorkers = _sortWorkers(_serviceWorkers);
        });
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
          return WorkerDetailScreen(worker: worker);
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
}