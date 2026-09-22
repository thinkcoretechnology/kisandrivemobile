import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class MasterWorksScreen extends StatefulWidget {
  final AuthService authService;

  const MasterWorksScreen({super.key, required this.authService});

  @override
  State<MasterWorksScreen> createState() => _MasterWorksScreenState();
}

class _MasterWorksScreenState extends State<MasterWorksScreen> {
  List<WorkService> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final token = widget.authService.token;
    if (token == null) return;

    final services = await ApiService.getWorkServices(token);
    if (mounted) {
      setState(() {
        _services = services;
        _isLoading = false;
      });
    }
  }

  void _openWorkModal({WorkService? service, int? index}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = service != null;

    final nameController = TextEditingController(text: service?.serviceName ?? '');
    final priceController = TextEditingController(text: service?.defaultRate.toString() ?? '');
    String billingUnit = service?.billingUnit ?? 'Hours';
    final autoSku = 'SKU-${((index ?? _services.length) + 1).toString().padLeft(3, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEditing ? '✏️ Edit Master Work Service' : '🛠️ Create Master Work Service', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Automatic SKU ID Field
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tealPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.tealPrimary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AUTOMATIC SKU ID:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                        Text(autoSku, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Service Name Validation
                  TextFormField(
                    controller: nameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter Work / Service Name' : null,
                    decoration: InputDecoration(
                      labelText: 'Service / Work Name *',
                      hintText: 'e.g. Pulling Work (Puzudhi)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: billingUnit,
                    items: const [
                      DropdownMenuItem(value: 'Hours', child: Text('Hours (Time calculated)')),
                      DropdownMenuItem(value: 'Per Load', child: Text('Per Load (Trip based)')),
                      DropdownMenuItem(value: 'Fixed / Hours', child: Text('Fixed / Hours')),
                      DropdownMenuItem(value: 'Manual Amount', child: Text('Manual Amount Override')),
                    ],
                    onChanged: (val) => setModalState(() => billingUnit = val!),
                    decoration: InputDecoration(
                      labelText: 'Billing Unit *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price Validation
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter Per Hour Price / Rate';
                      final price = double.tryParse(val.trim());
                      if (price == null || price < 0) return 'Enter a valid price';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Default Rate / Per Hour Price (₹) *',
                      hintText: 'e.g. 900.00',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final token = widget.authService.token;
                        if (token == null) return;

                        final price = double.tryParse(priceController.text) ?? 0.0;
                        bool success;
                        if (isEditing) {
                          success = await ApiService.updateWorkService(
                            token,
                            service.serviceId,
                            nameController.text.trim(),
                            billingUnit,
                            price,
                          );
                        } else {
                          success = await ApiService.createWorkService(
                            token,
                            nameController.text.trim(),
                            billingUnit,
                            price,
                          );
                        }

                        if (success) {
                          Navigator.pop(ctx);
                          _loadServices();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEditing ? 'Update Master Work' : 'Save Master Work', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteService(int serviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Master Work'),
        content: const Text('Are you sure you want to delete this work service?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final token = widget.authService.token;
      if (token == null) return;
      final success = await ApiService.deleteWorkService(token, serviceId);
      if (success) _loadServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Master Works & Price List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _openWorkModal()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWorkModal(),
        backgroundColor: AppColors.tealPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Work', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadServices,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final s = _services[index];
                  final skuId = 'SKU-${(index + 1).toString().padLeft(3, '0')}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tealPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.tealPrimary.withOpacity(0.3)),
                        ),
                        child: Text(skuId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                      ),
                      title: Text(s.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${s.billingUnit} • Rate: ₹${s.defaultRate.toStringAsFixed(0)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${s.defaultRate.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.goldPrimary),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') _openWorkModal(service: s, index: index);
                              if (val == 'delete') _deleteService(s.serviceId);
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 6), Text('Edit')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 6), Text('Delete', style: TextStyle(color: Colors.red))])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
