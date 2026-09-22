import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_phone_validator.dart';
import '../utils/date_formatter.dart';
import 'subscriptions_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final AuthService authService;

  const ExpensesScreen({super.key, required this.authService});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  List<Tractor> _tractors = [];
  bool _isLoading = true;

  // Search Bar for 5+ Expenses
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  SubscriptionRecord? _mySub;

  bool get _isSubscriptionLocked {
    if (_mySub == null || _mySub!.endDate.isEmpty) return false;
    try {
      final endDate = DateTime.parse(_mySub!.endDate);
      final differenceInDays = endDate.difference(DateTime.now()).inDays;
      return differenceInDays < -7;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = widget.authService.token;
    if (token == null) return;

    final expenses = await ApiService.getExpenses(token);
    final tractors = await ApiService.getTractors(token);
    final mySub = await ApiService.getMySubscription(token);

    if (mounted) {
      setState(() {
        _mySub = mySub;
        _expenses = expenses;
        _tractors = tractors;
        _isLoading = false;
      });
    }
  }

  List<Expense> get _filteredExpenses {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _expenses;
    return _expenses.where((ex) {
      final catMatch = ex.expenseCategory.toLowerCase().contains(q);
      final tractorMatch = (ex.tractorRegistration ?? '').toLowerCase().contains(q);
      final notesMatch = (ex.notesOrBillNumber ?? '').toLowerCase().contains(q);
      final dateMatch = ex.expenseDate.toLowerCase().contains(q);
      final amountMatch = ex.amount.toString().contains(q);
      return catMatch || tractorMatch || notesMatch || dateMatch || amountMatch;
    }).toList();
  }

  void _openExpenseModal({Expense? expense}) {
    if (_isSubscriptionLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⛔ Subscription & Grace Period expired! Renew plan to log new expenses.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Renew',
            textColor: Colors.yellow,
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionsScreen(authService: widget.authService)));
              _loadData();
            },
          ),
        ),
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final isEditing = expense != null;

    Tractor? selectedTractor = _tractors.isNotEmpty
        ? _tractors.firstWhere((t) => t.tractorId == expense?.tractorId, orElse: () => _tractors.first)
        : null;

    DateTime selectedExpenseDate = DateTime.now();
    String category = expense?.expenseCategory ?? 'Fuel';

    final amountController = TextEditingController(text: expense?.amount.toString() ?? '');
    final notesController = TextEditingController(text: expense?.notesOrBillNumber ?? '');

    // Driver Specific Controllers
    final driverNameController = TextEditingController();
    final driverPhoneController = TextEditingController();

    // Parse existing driver info if present
    if (expense?.notesOrBillNumber != null && expense!.notesOrBillNumber!.contains('Driver:')) {
      try {
        final parts = expense.notesOrBillNumber!.split('|');
        for (final p in parts) {
          if (p.trim().startsWith('Driver:')) {
            final dInfo = p.trim().replaceAll('Driver:', '').trim();
            final namePhone = dInfo.split('(');
            driverNameController.text = namePhone[0].trim();
            if (namePhone.length > 1) {
              driverPhoneController.text = namePhone[1].replaceAll(')', '').trim();
            }
          }
        }
      } catch (_) {}
    }

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
                      Text(isEditing ? '✏️ Edit Expense Log' : '⛽ Log Fleet Expense', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      IconButton(icon: const Icon(Icons.close, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // 1. Expense Category Selection (General, Fuel, Driver Betta, Maintenance, Other)
                  const Text('1. Select Expense Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    items: const [
                      DropdownMenuItem(value: 'Fuel', child: Text('⛽ Fuel / Diesel', style: TextStyle(color: Color(0xFF0F172A)))),
                      DropdownMenuItem(value: 'General', child: Text('🛠️ General Maintenance', style: TextStyle(color: Color(0xFF0F172A)))),
                      DropdownMenuItem(value: 'Driver Betta', child: Text('👨‍✈️ Driver Betta (Allowance)', style: TextStyle(color: Color(0xFF0F172A)))),
                      DropdownMenuItem(value: 'Maintenance', child: Text('🔧 Spare Parts & Repairs', style: TextStyle(color: Color(0xFF0F172A)))),
                      DropdownMenuItem(value: 'Other', child: Text('📦 Other Fleet Expense', style: TextStyle(color: Color(0xFF0F172A)))),
                    ],
                    onChanged: (val) => setModalState(() => category = val!),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // IF DRIVER BETTA IS SELECTED -> SHOW DRIVER NAME & DRIVER PHONE NUMBER INPUTS!
                  if (category == 'Driver Betta') ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('👨‍✈️ DRIVER DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: driverNameController,
                            validator: (val) {
                              if (category == 'Driver Betta' && (val == null || val.trim().isEmpty)) {
                                return 'Please enter Driver Name';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Driver Name *',
                              hintText: 'e.g. Ramesh Kumar',
                              prefixIcon: const Icon(Icons.person, color: Color(0xFF0284C7)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: driverPhoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (val) {
                              if (category == 'Driver Betta') {
                                return IndianPhoneValidator.validate(val);
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Driver Phone Number (10 Digits) *',
                              hintText: 'e.g. 9876543210',
                              prefixIcon: const Icon(Icons.phone, color: Color(0xFF0284C7)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 2. Amount Input
                  const Text('2. Expense Amount (₹) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter Amount';
                      final amt = double.tryParse(val.trim());
                      if (amt == null || amt <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: 'e.g. 1500.00',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Expense Date Selection
                  const Text('3. Expense Date (Max: Today) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedExpenseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(), // Max date locked to today!
                      );
                      if (picked != null) {
                        setModalState(() => selectedExpenseDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '📅 Date: ${selectedExpenseDate.day}/${selectedExpenseDate.month}/${selectedExpenseDate.year}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Text('(Max: Today)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Select Mapped Tractor
                  const Text('4. Select Mapped Tractor Machine (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Tractor>(
                    value: selectedTractor,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    hint: const Text('Select Mapped Tractor...', style: TextStyle(color: Color(0xFF94A3B8))),
                    items: _tractors.map((t) => DropdownMenuItem(value: t, child: Text('${t.registrationNumber} (${t.modelName})', style: const TextStyle(color: Color(0xFF0F172A))))).toList(),
                    onChanged: (val) => setModalState(() => selectedTractor = val),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Notes / Receipt Number
                  const Text('5. Additional Notes / Bill Receipt Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Fuel bill #904 / spare part receipt',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final token = widget.authService.token;
                        if (token == null) return;

                        final amount = double.tryParse(amountController.text) ?? 0.0;
                        String combinedNotes = notesController.text.trim();

                        if (category == 'Driver Betta') {
                          final dName = driverNameController.text.trim();
                          final dPhone = driverPhoneController.text.trim();
                          final dInfo = 'Driver: $dName ($dPhone)';
                          combinedNotes = combinedNotes.isNotEmpty ? '$dInfo | $combinedNotes' : dInfo;
                        }

                        bool success;
                        if (isEditing && expense != null && expense.expenseId != null) {
                          success = await ApiService.updateExpense(
                            token,
                            expense.expenseId!,
                            category,
                            amount,
                            selectedTractor?.tractorId,
                            combinedNotes,
                          );
                        } else {
                          success = await ApiService.createExpense(
                            token,
                            category,
                            amount,
                            selectedTractor?.tractorId,
                            combinedNotes,
                          );
                        }

                        if (success) {
                          Navigator.pop(ctx);
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⛽ Expense Log Saved! Category: $category | Amount: ₹${amount.toStringAsFixed(0)}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEditing ? 'Update Expense Log' : 'Save Expense Log', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete Expense'),
        content: Text('Are you sure you want to delete expense "${expense.expenseCategory}" (₹${expense.amount.toStringAsFixed(0)})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && expense.expenseId != null) {
      final token = widget.authService.token;
      if (token != null) {
        final ok = await ApiService.deleteExpense(token, expense.expenseId!);
        if (ok) {
          _loadData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('⛽ Fleet Expense Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseModal(),
        backgroundColor: AppColors.tealPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Expense', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_gas_station, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No expense logs recorded yet', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openExpenseModal(),
                        icon: const Icon(Icons.add),
                        label: const Text('Log First Expense'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      // SEARCH BAR SHOWS AUTOMATICALLY WHEN THERE ARE 5 OR MORE EXPENSES!
                      if (_expenses.length >= 5) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search category, tractor, notes, amount...',
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  'Showing ${filtered.length} expense(s) matching "$_searchQuery"',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tealPrimary),
                                ),
                              ],
                            ),
                          ),
                      ],

                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text('No expense logs matching "$_searchQuery"', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (ctx, i) {
                                  final ex = filtered[i];
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade50,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.local_gas_station, color: Colors.red, size: 20),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(ex.expenseCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                                                      Text('📅 Date: ${DateFormatter.formatDDMMYYYY(ex.expenseDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '₹${ex.amount.toStringAsFixed(2)}',
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.red),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('🚜 Machine: ${ex.tractorRegistration ?? "General Fleet"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                    if (ex.notesOrBillNumber?.isNotEmpty == true)
                                                      Text('📝 Notes: ${ex.notesOrBillNumber}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, size: 18, color: AppColors.tealPrimary),
                                                    onPressed: () => _openExpenseModal(expense: ex),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                    onPressed: () => _deleteExpense(ex),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
