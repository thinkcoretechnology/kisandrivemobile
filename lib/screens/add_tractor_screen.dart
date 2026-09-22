import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AddTractorScreen extends StatefulWidget {
  final AuthService authService;

  const AddTractorScreen({super.key, required this.authService});

  @override
  State<AddTractorScreen> createState() => _AddTractorScreenState();
}

class _AddTractorScreenState extends State<AddTractorScreen> {
  List<Tractor> _tractors = [];
  bool _isLoading = true;

  final List<String> _predefinedBrands = [
    'Mahindra',
    'John Deere',
    'Sonalika',
    'TAFE',
    'Swaraj',
    'Eicher',
    'New Holland',
    'Kubota',
    'Force Motors',
  ];

  final List<String> _fuelTypes = [
    'Diesel',
    'Electric',
    'Hybrid',
    'CNG',
  ];

  @override
  void initState() {
    super.initState();
    _loadTractors();
  }

  Future<void> _loadTractors() async {
    final token = widget.authService.token;
    if (token == null) return;

    final tractors = await ApiService.getTractors(token);
    if (mounted) {
      setState(() {
        _tractors = tractors;
        _isLoading = false;
      });
    }
  }

  void _openTractorModal({Tractor? tractor}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = tractor != null;

    final tractorNameController = TextEditingController(text: tractor?.tractorName ?? '');
    String selectedBrand = tractor?.brand ?? 'Mahindra';
    final modelController = TextEditingController(text: tractor?.modelName ?? '');
    final yearController = TextEditingController(text: tractor?.manufacturingYear.toString() ?? DateTime.now().year.toString());
    final hpController = TextEditingController(text: tractor?.hp.toString() ?? '45');
    DateTime purchaseDate = DateTime.now();
    String selectedFuelType = tractor?.fuelType ?? 'Diesel';
    final regNumController = TextEditingController(text: tractor?.registrationNumber ?? '');
    final insuranceController = TextEditingController(text: tractor?.insuranceDetails ?? 'Active Policy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                      Text(isEditing ? '✏️ Edit Tractor Details' : '🚜 Add New Tractor Fleet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      IconButton(icon: const Icon(Icons.close, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // 1. Tractor Name
                  const Text('1. Tractor Name (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: tractorNameController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Auto-filled from Brand & Model if empty',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Brand
                  const Text('2. Brand *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedBrand,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    dropdownColor: Colors.white,
                    items: _predefinedBrands.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(color: Color(0xFF0F172A))))).toList(),
                    onChanged: (val) => setModalState(() => selectedBrand = val!),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Model
                  const Text('3. Model *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: modelController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter Model specification' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. 575 DI / 5050D / 744 FE',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Manufacturing Year
                  const Text('4. Manufacturing Year *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter Manufacturing Year';
                      final year = int.tryParse(val.trim());
                      final currentYear = DateTime.now().year;
                      if (year == null || year < 1990 || year > currentYear) {
                        return 'Enter valid year between 1990 and $currentYear';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. 2026',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. HP (Horsepower)
                  const Text('5. Horsepower (HP) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: hpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter Horsepower (HP)';
                      final hpVal = int.tryParse(val.trim());
                      if (hpVal == null || hpVal <= 0) return 'HP must be greater than 0';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. 45',
                      suffixText: 'HP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6. Purchase Date
                  const Text('6. Purchase Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: purchaseDate,
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => purchaseDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: const Icon(Icons.calendar_today, color: AppColors.tealPrimary),
                      ),
                      child: Text(
                        '${purchaseDate.day}/${purchaseDate.month}/${purchaseDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 7. Fuel Type Dropdown
                  const Text('7. Fuel Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedFuelType,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    dropdownColor: Colors.white,
                    items: _fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(color: Color(0xFF0F172A))))).toList(),
                    onChanged: (val) => setModalState(() => selectedFuelType = val!),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 8. Registration Number
                  const Text('8. Registration Number *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: regNumController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter Registration Number' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. TN-65-AB-1234',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Insurance Details
                  const Text('Insurance Policy Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: insuranceController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Active - Policy #INS-90128',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final token = widget.authService.token;
                        if (token == null) return;

                        final tName = tractorNameController.text.trim().isNotEmpty
                            ? tractorNameController.text.trim()
                            : '$selectedBrand ${modelController.text.trim()}'.trim();

                        final payload = {
                          'tractor_name': tName,
                          'brand': selectedBrand,
                          'model_name': modelController.text.trim(),
                          'manufacturing_year': int.tryParse(yearController.text.trim()) ?? DateTime.now().year,
                          'hp': int.tryParse(hpController.text.trim()) ?? 45,
                          'purchase_date': purchaseDate.toIso8601String().substring(0, 10),
                          'fuel_type': selectedFuelType,
                          'registration_number': regNumController.text.trim().toUpperCase(),
                          'insurance_details': insuranceController.text.trim().isNotEmpty ? insuranceController.text.trim() : 'Active Policy',
                          'current_status': tractor?.currentStatus ?? 'Active',
                        };

                        bool success;
                        if (isEditing) {
                          success = await ApiService.updateTractor(token, tractor.tractorId, payload);
                        } else {
                          success = await ApiService.createTractor(token, payload);
                        }

                        if (success) {
                          Navigator.pop(ctx);
                          _loadTractors();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🚜 Tractor "${payload['tractor_name']}" saved to fleet!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save tractor. Please check inputs and try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(isEditing ? 'Update Tractor Record' : 'Save Tractor Record', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Future<void> _deleteTractor(int tractorId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tractor'),
        content: const Text('Are you sure you want to delete this machine from your fleet?'),
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
      final success = await ApiService.deleteTractor(token, tractorId);
      if (success) _loadTractors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚜 Tractor Fleet Registry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _openTractorModal()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTractorModal(),
        backgroundColor: AppColors.tealPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Tractor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTractors,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _tractors.length,
                itemBuilder: (context, index) {
                  final t = _tractors[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.tealPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.tealPrimary.withOpacity(0.3)),
                                ),
                                child: Text(t.registrationNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(t.currentStatus, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'edit') _openTractorModal(tractor: t);
                                      if (val == 'delete') _deleteTractor(t.tractorId);
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 6), Text('Edit')])),
                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 6), Text('Delete', style: TextStyle(color: Colors.red))])),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${t.brand} ${t.modelName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Tractor Name: ${t.tractorName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('${t.hp} HP • Year: ${t.manufacturingYear} • Fuel: ${t.fuelType}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Insurance: ${t.insuranceDetails}', style: const TextStyle(fontSize: 11, color: AppColors.goldPrimary)),
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
