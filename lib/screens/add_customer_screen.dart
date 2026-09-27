import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_phone_validator.dart';
import '../utils/date_formatter.dart';

class AddCustomerScreen extends StatefulWidget {
  final AuthService authService;

  const AddCustomerScreen({super.key, required this.authService});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;

  // Search by Name or Mobile
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final token = widget.authService.token;
    if (token == null) return;

    final customers = await ApiService.getCustomers(token);
    if (mounted) {
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    }
  }

  List<Customer> get _filteredCustomers {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers.where((c) {
      final nameMatch = c.customerName.toLowerCase().contains(q);
      final phoneMatch = c.primaryPhone.toLowerCase().contains(q);
      final villageMatch = c.villageLocation.toLowerCase().contains(q);
      return nameMatch || phoneMatch || villageMatch;
    }).toList();
  }

  double _parseNum(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  // Format decimal hours to X hrs Y mins
  String _formatDuration(dynamic rawHours) {
    if (rawHours == null) return '';
    final double hours = _parseNum(rawHours);
    if (hours <= 0) return '';
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '$h hrs $m mins';
    if (h > 0) return '$h hrs';
    return '$m mins';
  }

  // On-Page Pay Dues Modal (Stays on the same page with 0 screen redirection!)
  void _openPayDuesOnSamePageModal(Customer customer, double currentDueBalance) {
    final formKey = GlobalKey<FormState>();
    final amountPaidController = TextEditingController(text: currentDueBalance > 0 ? currentDueBalance.toStringAsFixed(0) : '');
    final referenceController = TextEditingController();
    String paymentMode = 'Cash';
    DateTime selectedPaymentDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('💳 Pay Dues: ${customer.customerName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Outstanding Due: ₹${currentDueBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // 1. Amount Paid Field
                  TextFormField(
                    controller: amountPaidController,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter Paid Amount';
                      final amt = double.tryParse(val.trim());
                      if (amt == null || amt <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: '1. Amount Paid (₹) *',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Payment Mode Dropdown
                  DropdownButtonFormField<String>(
                    value: paymentMode,
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('💵 Cash Receipt')),
                      DropdownMenuItem(value: 'UPI / GPay / PhonePe', child: Text('📱 UPI / GPay / PhonePe')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('🏦 Bank Transfer / NEFT')),
                      DropdownMenuItem(value: 'Cheque', child: Text('📄 Cheque')),
                      DropdownMenuItem(value: 'Other', child: Text('📦 Other Payment Mode')),
                    ],
                    onChanged: (val) => setModalState(() => paymentMode = val ?? 'Cash'),
                    decoration: InputDecoration(
                      labelText: '2. Payment Mode *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Reference Number (Optional)
                  TextFormField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      labelText: '3. Reference / Transaction # (Optional)',
                      hintText: 'e.g. UPI Ref #904812 / Cheque #1042',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Payment Date Selection
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedPaymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(), // Max date locked to today!
                      );
                      if (picked != null) {
                        setModalState(() => selectedPaymentDate = picked);
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
                            '📅 Date: ${selectedPaymentDate.day}/${selectedPaymentDate.month}/${selectedPaymentDate.year}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Text('(Max: Today)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Payment Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final token = widget.authService.token;
                        if (token == null) return;

                        final amountPaid = double.tryParse(amountPaidController.text.trim()) ?? 0.0;
                        final refNum = referenceController.text.trim();

                        final success = await ApiService.createPayment(
                          token,
                          customer.customerId,
                          amountPaid,
                          paymentMode,
                          refNum,
                        );

                        if (success) {
                          Navigator.pop(modalCtx); // Close pay modal
                          await _loadCustomers(); // Refresh farmer directory & balances on the SAME PAGE!
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('💳 Payment receipt of ₹${amountPaid.toStringAsFixed(0)} logged for ${customer.customerName}!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Record Payment & Update Dues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  // Popup Modal showing Bill History and Pay History Tables + Pay Dues Button
  void _openClientHistoryModal(Customer customer) {
    final token = widget.authService.token;
    if (token == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FutureBuilder<Map<String, dynamic>?>(
        future: ApiService.getCustomerLedger(token, customer.customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.tealPrimary),
                    SizedBox(height: 12),
                    Text('Loading Farmer Ledger & Dues...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    const Text('Unable to load ledger history.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                  ],
                ),
              ),
            );
          }

          final ledgerData = snapshot.data!;
          final List rawLedger = ledgerData['ledger'] ?? [];
          final double currentBal = (ledgerData['current_balance'] ?? 0).toDouble();

          final billHistory = rawLedger.where((item) => item['type'] == 'WORK_BILL' || item['type'] == 'OPENING_BALANCE').toList();
          final payHistory = rawLedger.where((item) => item['type'] == 'PAYMENT').toList();

          double totalDecimalHours = 0.0;
          double subTotalBillAmount = 0.0;
          for (final item in billHistory) {
            final details = item['details'] as Map<String, dynamic>?;
            final hrs = _parseNum(item['actual_hours'] ?? details?['actual_hours']);
            totalDecimalHours += hrs;

            final amt = _parseNum(item['amount'] ?? item['charge_amount'] ?? details?['net_payable'] ?? details?['total_amount']);
            subTotalBillAmount += amt;
          }
          final totalHoursStr = _formatDuration(totalDecimalHours);

          double totalPaidAmount = 0.0;
          for (final item in payHistory) {
            final details = item['details'] as Map<String, dynamic>?;
            final amt = _parseNum(item['amount'] ?? item['payment_amount'] ?? details?['amount_paid']);
            totalPaidAmount += amt;
          }

          final double grandTotalRemaining = currentBal;

          return DefaultTabController(
            length: 2,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(16),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('📞 ${customer.primaryPhone} • 📍 ${customer.villageLocation}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),

              // Outstanding Dues Banner with Direct On-Page Pay Dues Modal Button!
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: currentBal > 0 ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentBal > 0 ? Colors.red.shade200 : Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentBal > 0 ? 'Total Due Balance' : 'Account Balance Cleared',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentBal > 0 ? Colors.red.shade900 : Colors.green.shade900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${currentBal.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: currentBal > 0 ? Colors.red.shade700 : Colors.green.shade700),
                        ),
                      ],
                    ),
                    if (currentBal > 0)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('💳 Pay Dues Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(ctx); // Close ledger modal
                          _openPayDuesOnSamePageModal(customer, currentBal); // Open Pay Dues Modal ON THE SAME PAGE!
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // TAB BAR
              const TabBar(
                labelColor: AppColors.tealPrimary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.tealPrimary,
                tabs: [
                  Tab(text: '⚡ Work Bills History'),
                  Tab(text: '💳 Pay Receipts History'),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: TabBarView(
                  children: [
                    // TAB 1: WORK BILLS TABLE & SUMMARY TOTAL CARD
                    billHistory.isEmpty
                        ? const Center(child: Text('No work bills recorded for this farmer.', style: TextStyle(color: Colors.grey)))
                        : Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 10,
                                      horizontalMargin: 8,
                                      headingRowHeight: 38,
                                      dataRowMinHeight: 36,
                                      dataRowMaxHeight: 44,
                                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                      columns: const [
                                        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                        DataColumn(label: Text('Type/Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                        DataColumn(label: Text('Tractor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                        DataColumn(label: Text('Hours/Loads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                        DataColumn(label: Text('Bill Amt (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      ],
                                      rows: billHistory.map((item) {
                                        final isOB = item['type'] == 'OPENING_BALANCE';
                                        final details = item['details'] as Map<String, dynamic>?;
                                        final serviceName = item['service_name'] ?? details?['service_name'] ?? (isOB ? 'Opening Balance' : 'Field Work');
                                        final tractorReg = item['tractor_reg'] ?? details?['tractor_name'] ?? details?['tractor_registration'] ?? '-';
                                        final actualHrs = item['actual_hours'] ?? details?['actual_hours'];
                                        final loadCnt = item['load_count'] ?? details?['load_count'];
                                        final durationStr = isOB ? '-' : _formatDuration(actualHrs);
                                        final double amtVal = _parseNum(item['amount'] ?? item['charge_amount'] ?? details?['net_payable'] ?? details?['total_amount']);

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                item['date'] != null ? DateFormatter.formatDDMMYYYY(item['date']) : '-',
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            ),
                                            DataCell(Text(
                                              serviceName,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isOB ? Colors.orange.shade800 : Colors.black),
                                            )),
                                            DataCell(Text(tractorReg.toString(), style: const TextStyle(fontSize: 10))),
                                            DataCell(Text(
                                              durationStr.isNotEmpty && durationStr != '-' ? durationStr : (loadCnt != null && loadCnt > 0 ? '$loadCnt loads' : '-'),
                                              style: const TextStyle(fontSize: 10),
                                            )),
                                            DataCell(Text('₹${amtVal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // LEDGER SUMMARY TOTALS CARD BELOW TABLE
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('⏱️ Total Work Hours:', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                        Text(totalHoursStr.isNotEmpty && totalHoursStr != '-' ? totalHoursStr : '0 hrs', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('📋 Sub Total Amount (Bills):', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                        Text('₹${subTotalBillAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('💳 Paid Amount (Total):', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                        Text('- ₹${totalPaidAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                      ],
                                    ),
                                    const Divider(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('GRAND TOTAL (REMAINING DUE):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                        Text(
                                          '₹${grandTotalRemaining.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: grandTotalRemaining > 0 ? Colors.red : AppColors.tealPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                    // TAB 2: PAY RECEIPTS TABLE (REFERENCE NO REMOVED, TIGHT COLUMNS)
                    payHistory.isEmpty
                        ? const Center(child: Text('No payment receipts recorded for this farmer.', style: TextStyle(color: Colors.grey)))
                        : SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 24,
                                headingRowHeight: 38,
                                dataRowMinHeight: 36,
                                dataRowMaxHeight: 44,
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                columns: const [
                                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  DataColumn(label: Text('Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                  DataColumn(label: Text('Paid Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                ],
                                rows: payHistory.map((item) {
                                  final details = item['details'] as Map<String, dynamic>?;
                                  final payMode = item['payment_mode'] ?? details?['payment_mode'] ?? 'Cash';
                                  final double amtVal = _parseNum(item['amount'] ?? item['payment_amount'] ?? details?['amount_paid']);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          item['date'] != null ? DateFormatter.formatDDMMYYYY(item['date']) : '-',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      DataCell(Text(payMode.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                                      DataCell(Text('₹${amtVal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)))),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
);
  }

  void _openCustomerModal({Customer? customer}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = customer != null;

    final nameController = TextEditingController(text: customer?.customerName ?? '');
    final phoneController = TextEditingController(text: customer?.primaryPhone ?? '');
    final villageController = TextEditingController(text: customer?.villageLocation ?? '');
    final pincodeController = TextEditingController(text: customer?.pincode ?? '');
    final balanceController = TextEditingController(text: customer?.openingBalance.toString() ?? '0');

    String selectedGender = customer?.gender ?? 'Male';
    String status = customer?.status ?? 'Active';

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
                      Text(isEditing ? '✏️ Edit Farmer Account' : '👨‍🌾 Add New Farmer Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      IconButton(icon: const Icon(Icons.close, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  const Text('Farmer Full Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter Farmer Name' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. Periyasamy M',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Primary Phone Number (10 Digits) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: IndianPhoneValidator.validate,
                    decoration: InputDecoration(
                      hintText: 'e.g. 9842100000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Village / Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: villageController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Vadagarai Village',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: selectedGender,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                              dropdownColor: Colors.white,
                              items: const [
                                DropdownMenuItem(value: 'Male', child: Text('Male', style: TextStyle(color: Color(0xFF0F172A)))),
                                DropdownMenuItem(value: 'Female', child: Text('Female', style: TextStyle(color: Color(0xFF0F172A)))),
                                DropdownMenuItem(value: 'Other', child: Text('Other', style: TextStyle(color: Color(0xFF0F172A)))),
                              ],
                              onChanged: (val) => setModalState(() => selectedGender = val ?? 'Male'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pincode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: pincodeController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text('Account Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: status,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active', style: TextStyle(color: Color(0xFF0F172A)))),
                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive', style: TextStyle(color: Color(0xFF0F172A)))),
                    ],
                    onChanged: (val) => setModalState(() => status = val ?? 'Active'),
                    decoration: InputDecoration(
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

                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        final village = villageController.text.trim();
                        final pincode = pincodeController.text.trim();
                        final bal = isEditing ? (customer?.openingBalance ?? 0.0) : 0.0;

                        bool success;
                        if (isEditing && customer != null) {
                          success = await ApiService.updateCustomer(
                            token,
                            customer.customerId,
                            name,
                            phone,
                            village,
                            selectedGender,
                            pincode,
                            bal,
                            status,
                          );
                        } else {
                          final newCust = await ApiService.createCustomer(
                            token,
                            name,
                            phone,
                            village,
                            selectedGender,
                            pincode,
                            bal,
                            status,
                          );
                          success = newCust != null;
                        }

                        if (success) {
                          Navigator.pop(ctx);
                          _loadCustomers();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('👨‍🌾 Farmer "$name" saved!'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEditing ? 'Update Farmer Account' : 'Save Farmer Account', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _deleteCustomer(int customerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Farmer'),
        content: const Text('Are you sure you want to delete this farmer account?'),
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
      final success = await ApiService.deleteCustomer(token, customerId);
      if (success) _loadCustomers();
    }
  }

  Future<void> _toggleStatus(Customer customer) async {
    final token = widget.authService.token;
    if (token == null) return;

    final nextStatus = customer.status == 'Active' ? 'Inactive' : 'Active';
    final success = await ApiService.updateCustomer(
      token,
      customer.customerId,
      customer.customerName,
      customer.primaryPhone,
      customer.villageLocation,
      customer.gender,
      customer.pincode,
      customer.openingBalance,
      nextStatus,
    );

    if (success) _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCustomers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍🌾 Farmers Directory & Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.person_add), onPressed: () => _openCustomerModal()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCustomerModal(),
        backgroundColor: AppColors.tealPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Farmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCustomers,
              child: Column(
                children: [
                  // SEARCH BAR FOR FARMER NAME OR MOBILE NUMBER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Farmer Name or Mobile Number...',
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
                            'Showing ${filtered.length} farmer(s) matching "$_searchQuery"',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tealPrimary),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_search, size: 54, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty ? 'No farmers matching "$_searchQuery"' : 'No farmers added yet.',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final c = filtered[index];
                              final hasAmount = c.currentBalance > 0;
                              final amountDisplay = hasAmount ? '₹${c.currentBalance.toStringAsFixed(0)}' : 'Nill';

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
                                          Text(c.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          
                                          // Status Active Badge Toggle
                                          InkWell(
                                            onTap: () => _toggleStatus(c),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: c.status == 'Active' ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: c.status == 'Active' ? Colors.green : Colors.red),
                                              ),
                                              child: Text(
                                                'Status: ${c.status}',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c.status == 'Active' ? Colors.green.shade900 : Colors.red.shade900),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('📞 Phone: ${c.primaryPhone}', style: const TextStyle(
      fontSize: 13,
      color: Colors.black,
      height: 1.5,
    ),),
                                              Text('📍 Village: ${c.villageLocation.isNotEmpty ? c.villageLocation : "N/A"}', style: const TextStyle(
      fontSize: 12,
      color: Colors.black,
      height: 1.5,
    ),),
                                            ],
                                          ),

                                          // Outstanding Balance Badge with Clickable Ledger / Pay Dues Modal Button!
                                          InkWell(
                                            onTap: () => _openClientHistoryModal(c),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: hasAmount ? Colors.red.shade50 : Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: hasAmount ? Colors.red.shade300 : Colors.green.shade300),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'Outstanding Balance',
                                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: hasAmount ? Colors.red.shade800 : Colors.green.shade800),
                                                  ),
                                                  Text(
                                                    amountDisplay,
                                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: hasAmount ? Colors.red : Colors.green),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),

                                      // Footer Actions: Open Full Ledger, Direct Pay Dues On Same Page, Edit, Delete
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.tealPrimary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            icon: const Icon(Icons.receipt_long, size: 16),
                                            label: const Text('View Ledger', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            onPressed: () => _openClientHistoryModal(c),
                                          ),
                                          if (c.currentBalance > 0) ...[
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green.shade700,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              icon: const Icon(Icons.payment, size: 16),
                                              label: const Text('Pay Dues', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              onPressed: () => _openPayDuesOnSamePageModal(c, c.currentBalance),
                                            ),
                                          ],
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18, color: AppColors.tealPrimary),
                                                onPressed: () => _openCustomerModal(customer: c),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                onPressed: () => _deleteCustomer(c.customerId),
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
