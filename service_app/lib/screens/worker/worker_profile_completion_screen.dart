import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/location_service.dart';
import '../../core/services/service_service.dart';
import '../../core/utils/error_message_helper.dart';
import '../../services/api_service.dart';

class WorkerProfileCompletionScreen extends StatefulWidget {
  const WorkerProfileCompletionScreen({super.key});

  @override
  State<WorkerProfileCompletionScreen> createState() =>
      _WorkerProfileCompletionScreenState();
}

class _WorkerProfileCompletionScreenState
    extends State<WorkerProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _skillsController = TextEditingController();

  final _workerApi = WorkerApiService();
  final _serviceService = ServiceService();

  List<ServiceItem> _services = <ServiceItem>[];
  String? _selectedServiceId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    List<ServiceItem> services = <ServiceItem>[];
    Map<String, dynamic> profile = <String, dynamic>{};
    String? loadError;

    try {
      services = await _serviceService.getServices();
    } catch (e) {
      loadError = ErrorMessageHelper.generic(e);
    }

    try {
      profile = await _workerApi.getWorkerProfile();
    } catch (e) {
      loadError ??= ErrorMessageHelper.generic(e);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _services = services;
      _selectedServiceId = (profile['serviceId'] ?? '').toString().isEmpty
          ? (_services.isNotEmpty ? _services.first.id : null)
          : (profile['serviceId'] is Map<String, dynamic>
                ? (profile['serviceId']['_id'] ??
                          profile['serviceId']['id'] ??
                          '')
                      .toString()
                : profile['serviceId'].toString());
      _priceController.text = (profile['price'] ?? '').toString();
      _locationController.text = (profile['location'] ?? '').toString();
      _skillsController.text = (profile['skills'] is List)
          ? (profile['skills'] as List<dynamic>)
                .map((skill) => skill.toString())
                .join(', ')
          : '';
      _loadError = loadError;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final serviceId = _selectedServiceId;
    if (serviceId == null || serviceId.isEmpty) {
      ErrorMessageHelper.showSnackBar(context, 'Please select a service');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final normalizedLocation = _locationController.text.trim().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      final parsedPrice = num.parse(_priceController.text.trim());
      final normalizedSkills = _skillsController.text
          .split(',')
          .map((skill) => skill.trim().replaceAll(RegExp(r'\s+'), ' '))
          .where((skill) => skill.isNotEmpty)
          .toSet()
          .toList();

      await _workerApi.updateWorkerProfile(
        serviceId: serviceId,
        price: parsedPrice,
        location: normalizedLocation,
        skills: normalizedSkills,
      );

      final liveLocation = await LocationService.getUserLocation();
      if (liveLocation != null) {
        try {
          await _workerApi.updateWorkerLocation(
            latitude: liveLocation.latitude,
            longitude: liveLocation.longitude,
            isOnline: true,
          );
        } catch (_) {
          // Profile update succeeded; location can be updated again later.
        }
      }

      final session = await _workerApi.getSavedSession();
      if (session != null) {
        try {
          await _workerApi.getWorkerBookings(
            session: session,
            forceRefresh: true,
          );
        } catch (_) {
          // Dashboard will still load and handle this gracefully.
        }
      }

      if (!mounted) {
        return;
      }

      ErrorMessageHelper.showSnackBar(
        context,
        'Profile completed successfully',
      );
      Navigator.pushReplacementNamed(
        context,
        '/worker/dashboard',
        arguments: session,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ErrorMessageHelper.showSnackBar(context, ErrorMessageHelper.generic(e));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(title: const Text('Complete Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete your worker profile',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add service, pricing, location, and skills so customers can discover and book you quickly.',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_loadError != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    _loadError!,
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              DropdownButtonFormField<String>(
                                initialValue: _selectedServiceId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Service',
                                  prefixIcon: Icon(Icons.work_outline),
                                ),
                                items: _services
                                    .map(
                                      (service) => DropdownMenuItem<String>(
                                        value: service.id,
                                        child: Text(service.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedServiceId = value;
                                  });
                                },
                                disabledHint: const Text(
                                  'No services available',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Service is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  prefixIcon: Icon(Icons.currency_rupee),
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Price is required';
                                  }
                                  if (num.tryParse(text) == null) {
                                    return 'Enter a valid price';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Location is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _skillsController,
                                decoration: const InputDecoration(
                                  labelText: 'Skills (comma separated)',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: (_isSaving || _services.isEmpty)
                                      ? null
                                      : _save,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _services.isEmpty
                                        ? 'Load services first'
                                        : 'Save Profile',
                                  ),
                                ),
                              ),
                            ],
                          ),
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
