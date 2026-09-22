import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_phone_validator.dart';
import 'subscriptions_screen.dart';

class QuickBillScreen extends StatefulWidget {
  final AuthService authService;
  final Function(int)? onNavigate;

  const QuickBillScreen({
    super.key,
    required this.authService,
    this.onNavigate,
  });

  @override
  State<QuickBillScreen> createState() => _QuickBillScreenState();
}

class _QuickBillScreenState extends State<QuickBillScreen> {
  List<Tractor> _tractors = [];
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  List<WorkService> _allServices = [];
  List<WorkService> _filteredServices = [];

  Tractor? _selectedTractor;
  Customer? _selectedCustomer;
  WorkService? _selectedService;

  DateTime _entryDate = DateTime.now(); // Future dates disabled!
  TimeOfDay _startTime = const TimeOfDay(hour: 15, minute: 5); // Default 3:05 PM
  TimeOfDay _endTime = const TimeOfDay(hour: 16, minute: 45); // Default 4:45 PM

  final _searchFarmerController = TextEditingController();
  final _searchWorkController = TextEditingController();
  final _quantityController = TextEditingController(); // Empty by default
  final _manualAmountController = TextEditingController(); // Empty by default
  final _remarksController = TextEditingController();

  String _durationFormattedText = '-';
  double _calculatedDecimalHours = 0.0;

  double _newWorkAmount = 0.0;
  double _existingBalance = 0.0;
  double _cumulativeTotalAmount = 0.0;

  bool _isLoading = true;
  bool _isSubmitting = false;

  SubscriptionRecord? _mySub;

  bool get _isSubscriptionLocked {
    if (_mySub == null || _mySub!.endDate.isEmpty) return false;
    try {
      final endDate = DateTime.parse(_mySub!.endDate);
      final differenceInDays = endDate.difference(DateTime.now()).inDays;
      return differenceInDays < -7; // Lock entries 7 days after grace period!
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  @override
  void didUpdateWidget(covariant QuickBillScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadMasters();
  }

  Future<void> _loadMasters([int? selectCustomerId]) async {
    final token = widget.authService.token;
    if (token == null) return;

    final tractors = await ApiService.getTractors(token);
    final customers = await ApiService.getCustomers(token);
    final services = await ApiService.getWorkServices(token);
    final mySub = await ApiService.getMySubscription(token);

    if (mounted) {
      setState(() {
        _mySub = mySub;
        _tractors = tractors;
        _allCustomers = customers;
        _filteredCustomers = customers;
        _allServices = services;
        _filteredServices = services;

        // Reset to empty selection by default for a clean new bill entry!
        if (selectCustomerId != null) {
          final found = customers.firstWhere((c) => c.customerId == selectCustomerId, orElse: () => customers.first);
          _selectedCustomer = found;
          _existingBalance = found.currentBalance;
        } else {
          _selectedTractor = null;
          _selectedCustomer = null;
          _selectedService = null;
          _existingBalance = 0.0;
        }

        _recalculateTimesAndAmounts();
        _isLoading = false;
      });
    }
  }

  bool get _isHoursWork {
    if (_selectedService == null) return true; // Default to hours if unselected
    final u = _selectedService!.billingUnit.toLowerCase();
    return u.contains('hour') || u.contains('hr');
  }

  bool get _isManualWork {
    if (_selectedService == null) return false;
    final u = _selectedService!.billingUnit.toLowerCase();
    return u.contains('manual');
  }

  void _filterFarmers(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers = _allCustomers.where((c) {
          return c.customerName.toLowerCase().contains(q) || c.primaryPhone.contains(q);
        }).toList();
      }
    });
  }

  void _filterWorkServices(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredServices = _allServices;
      } else {
        _filteredServices = _allServices.where((s) {
          return s.serviceName.toLowerCase().contains(q) || s.defaultRate.toString().contains(q);
        }).toList();
      }
    });
  }

  void _recalculateTimesAndAmounts() {
    if (_selectedService == null) {
      _durationFormattedText = '-';
      _calculatedDecimalHours = 0.0;
      _newWorkAmount = 0.0;
      _cumulativeTotalAmount = _existingBalance;
      return;
    }

    final rate = _selectedService!.defaultRate;

    if (_isManualWork) {
      _newWorkAmount = double.tryParse(_manualAmountController.text.trim()) ?? 0.0;
      _durationFormattedText = 'Manual Entry';
      _calculatedDecimalHours = 0.0;
    } else if (_isHoursWork) {
      // Calculate precise time difference for Per Hour
      final startMin = _startTime.hour * 60 + _startTime.minute;
      final endMin = _endTime.hour * 60 + _endTime.minute;

      int diffMin = endMin - startMin;
      if (diffMin < 0) {
        diffMin += 24 * 60; // Crosses midnight handle
      }

      final h = diffMin ~/ 60;
      final m = diffMin % 60;
      if (h > 0 && m > 0) {
        _durationFormattedText = '$h hrs $m mins';
      } else if (h > 0) {
        _durationFormattedText = '$h hrs';
      } else {
        _durationFormattedText = '$m mins';
      }

      _calculatedDecimalHours = diffMin / 60.0;
      _newWorkAmount = _calculatedDecimalHours * rate;
    } else {
      // Non-Hours Mode (Per Load / Per Acre) -> Quantity * Rate
      final qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;
      _newWorkAmount = qty * rate;
      _durationFormattedText = '${qty.toStringAsFixed(0)} ${_selectedService!.billingUnit}';
      _calculatedDecimalHours = 0.0;
    }

    _cumulativeTotalAmount = _existingBalance + _newWorkAmount;
  }

  void _openQuickAddFarmerModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final villageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('➕ Quick Add Farmer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Farmer Name *')),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(labelText: 'Mobile Number (10 Digits) *'),
            ),
            const SizedBox(height: 8),
            TextField(controller: villageCtrl, decoration: const InputDecoration(labelText: 'Village Location')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter Farmer Name and Mobile Number')),
                );
                return;
              }

              final phoneErr = IndianPhoneValidator.validate(phone);
              if (phoneErr != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(phoneErr), backgroundColor: Colors.red),
                );
                return;
              }

              final token = widget.authService.token!;
              final createdCustomer = await ApiService.createCustomer(
                token,
                name,
                phone,
                villageCtrl.text.trim(),
                'Male',
                '',
                0.0,
                'Active',
              );

              if (createdCustomer != null) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('👨‍🌾 Farmer $name added & selected!'), backgroundColor: Colors.green),
                );
                await _loadMasters(createdCustomer.customerId);
              }
            },
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectEntryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Future dates disabled!
    );
    if (picked != null) {
      setState(() {
        _entryDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _recalculateTimesAndAmounts();
      });
    }
  }

  Future<void> _submitQuickBill() async {
    if (_isSubscriptionLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⛔ Subscription & Grace period expired! Please renew plan to create new field work bills.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Renew',
            textColor: Colors.yellow,
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionsScreen(authService: widget.authService)));
              _loadMasters();
            },
          ),
        ),
      );
      return;
    }

    if (_selectedTractor == null || _selectedCustomer == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Tractor Machine, Farmer, and Work Service')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final token = widget.authService.token!;

    final loadCnt = !_isHoursWork && !_isManualWork ? (int.tryParse(_quantityController.text.trim()) ?? 1) : 0;
    final manualAmt = _isManualWork ? (double.tryParse(_manualAmountController.text.trim()) ?? 0.0) : 0.0;
    final actualHrs = _isHoursWork ? _calculatedDecimalHours : 0.0;

    final success = await ApiService.createFieldWorkEntry(
      token,
      _entryDate.toIso8601String().split('T').first,
      _selectedTractor!.tractorId,
      _selectedCustomer!.customerId,
      _selectedService!.serviceId,
      actualHrs,
      loadCnt,
      _selectedService!.defaultRate,
      _manualAmountController.text.trim(),
      _remarksController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚡ Cumulative Bill Generated! New Bill: ₹${_newWorkAmount.toStringAsFixed(0)} | Total Dues: ₹${_cumulativeTotalAmount.toStringAsFixed(0)}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      // Reset form to clean empty state!
      setState(() {
        _selectedTractor = null;
        _selectedCustomer = null;
        _selectedService = null;
        _searchFarmerController.clear();
        _searchWorkController.clear();
        _remarksController.clear();
        _manualAmountController.clear();
        _quantityController.clear();
        _durationFormattedText = '-';
        _newWorkAmount = 0.0;
        _existingBalance = 0.0;
        _cumulativeTotalAmount = 0.0;
      });

      // Redirect to Dashboard (Index 0) to view updated KPIs & dues!
      if (widget.onNavigate != null) {
        widget.onNavigate!(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Billing & Field Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Master Works List',
            onPressed: () {
              _loadMasters();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔄 Master works & farmers list reloaded!'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSubscriptionLocked) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade300, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.red, size: 24),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⛔ Entries Locked (Grace Period Over)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                                Text('7-day grace period ended. Pay subscription to unlock entry creation.', style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D))),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionsScreen(authService: widget.authService)));
                              _loadMasters();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text('Renew Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. Entry Date (Future dates disabled)
                  const Text('1. Billing Date (Max: Today) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _selectEntryDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('📅 Date: ${_entryDate.day}/${_entryDate.month}/${_entryDate.year}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Select Tractor
                  const Text('2. Select Tractor Machine *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Tractor>(
                    value: _selectedTractor,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    hint: const Text('Select Tractor Machine...', style: TextStyle(color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                    items: _tractors
                        .map((t) => DropdownMenuItem(value: t, child: Text('${t.registrationNumber} (${t.modelName})', style: const TextStyle(color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (t) => setState(() => _selectedTractor = t),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),

                  // 3. Select Farmer & Search Below
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('3. Select Farmer *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)), overflow: TextOverflow.ellipsis),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        onPressed: _openQuickAddFarmerModal,
                        icon: const Icon(Icons.person_add, size: 14, color: AppColors.tealPrimary),
                        label: const Text('➕ Add Farmer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    hint: const Text('Select Farmer / Customer...', style: TextStyle(color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                    items: _filteredCustomers
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.customerName} (${c.primaryPhone}) - Due: ₹${c.currentBalance.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (c) {
                      setState(() {
                        _selectedCustomer = c;
                        _existingBalance = c?.currentBalance ?? 0.0;
                        _recalculateTimesAndAmounts();
                      });
                    },
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _searchFarmerController,
                    onChanged: _filterFarmers,
                    decoration: InputDecoration(
                      hintText: 'Search farmer name or mobile to filter list above...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Select Work Service & Search Below
                  const Text('4. Select Work Service (Master Works) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<WorkService>(
                    value: _selectedService,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    hint: const Text('Select Work Service...', style: TextStyle(color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                    items: _filteredServices
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('${s.serviceName} (₹${s.defaultRate.toStringAsFixed(0)}/${s.billingUnit})', style: const TextStyle(color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (s) {
                      setState(() {
                        _selectedService = s;
                        _recalculateTimesAndAmounts();
                      });
                    },
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _searchWorkController,
                    onChanged: _filterWorkServices,
                    decoration: InputDecoration(
                      hintText: 'Search work service name or rate to filter list above...',
                      prefixIcon: const Icon(Icons.build_circle, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // IF MANUAL WORKS IS SELECTED -> SHOW MANUAL BILL AMOUNT INPUT!
                  if (_isManualWork) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📝 MANUAL AMOUNT WORK BILLING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                          const Text('Time calculation fields are hidden for manual works.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _manualAmountController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _recalculateTimesAndAmounts(),
                            decoration: InputDecoration(
                              labelText: 'Enter Manual Work Bill Amount (₹) *',
                              hintText: 'e.g. 3000',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]
                  // IF HOURS WORK IS CHOSEN -> SHOW START & END TIME PICKERS + DURATION
                  else if (_isHoursWork) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectTime(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_startTime.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      const Icon(Icons.access_time, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectTime(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_endTime.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      const Icon(Icons.access_time, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Formatted Duration Banner (e.g. 1 hrs 40 mins)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.goldPrimary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('CALCULATED WORK DURATION:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(
                            _durationFormattedText == '-'
                                ? '-'
                                : '⏱️ $_durationFormattedText (${_calculatedDecimalHours.toStringAsFixed(2)} hrs)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.goldPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]
                  // IF NON-HOURS WORK (PER LOAD / PER ACRE) -> HIDE TIME PICKERS COMPLETELY! SHOW QUANTITY INPUT!
                  else ...[
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalculateTimesAndAmounts(),
                      decoration: InputDecoration(
                        labelText: 'Total Quantity / Count (${_selectedService?.billingUnit ?? "Units"}) *',
                        hintText: 'e.g. 5',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _remarksController,
                    decoration: InputDecoration(
                      labelText: 'Remarks / Soil Notes',
                      hintText: 'e.g. Hard dry soil / wet mud land',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CUMULATIVE DUES PREVIEW CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Work Bill Amount:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('₹${_newWorkAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Previous Farmer Dues:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('₹${_existingBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('NET CUMULATIVE DUES:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('₹${_cumulativeTotalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.tealPrimary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _isSubscriptionLocked ? null : _submitQuickBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '⚡ Save & Generate Cumulative Bill',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
