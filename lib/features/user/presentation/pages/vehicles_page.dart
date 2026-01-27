import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/vehicle_model.dart';
import '../../../../core/services/api_service.dart';
import 'widgets/add_vehicle_dialog.dart';

class VehiclesPage extends StatefulWidget {
  final UserModel user;

  const VehiclesPage({super.key, required this.user});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final ApiService _apiService = ApiService();
  List<VehicleModel> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    try {
      final response = await _apiService.getVehicles();
      if (mounted && response['success'] == true) {
        final list = response['vehicles'] as List? ?? [];
        setState(() {
          _vehicles = list
              .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddVehicleDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => const AddVehicleDialog(),
    );
    if (added == true && mounted) {
      _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddVehicleDialog,
            tooltip: 'Add vehicle',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 80,
                        color: AppTheme.textColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No vehicles added yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddVehicleDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add your first vehicle'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: vehicle.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: vehicle.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.directions_car,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.directions_car,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                        ),
                        title: Text(
                          vehicle.vehicleNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          vehicle.displayType,
                          style: TextStyle(
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
