import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kisan_loader.dart';

class PaybillScreen extends StatefulWidget {
  final AuthService authService;
  final Customer? initialCustomer;
  final Function(int)? onNavigate;

  const PaybillScreen({
    super.key,
    required this.authService,
    this.initialCustomer,
    this.onNavigate,
  });

  @override
  State<PaybillScreen> createState() => _PaybillScreenState();
}

class _PaybillScreenState extends State<PaybillScreen> {
  List<Customer> _customers = [];
  Customer? _selectedCustomer;

  bool _isFullPay = false; // Toggle: Full Pay vs Partial Pay
  final _amountPaidController = TextEditingController(text: '0');
  final _referenceController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'Cash';

  double _totalDues = 0.0;
  double _amountPaid = 0.0;
  double _remainingBalance = 0.0;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _exceedErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final token = widget.authService.token;
    if (token == null) return;

    final customers = await ApiService.getCustomers(token);
    if (mounted) {
      setState(() {
        _customers = customers;

        if (widget.initialCustomer != null) {
          _selectedCustomer = customers.firstWhere(
            (c) => c.customerId == widget.initialCustomer!.customerId,
            orElse: () => customers.first,
          );
        } else if (customers.isNotEmpty) {
          _selectedCustomer = customers.first;
        }

        if (_selectedCustomer != null) {
          _onCustomerChanged(_selectedCustomer);
        }

        _isLoading = false;
      });
    }
  }

  Future<void> _onCustomerChanged(Customer? customer) async {
    if (customer == null) return;
    setState(() => _selectedCustomer = customer);

    final token = widget.authService.token;
    double currentBal = customer.currentBalance;

    if (token != null) {
      final ledger = await ApiService.getCustomerLedger(token, customer.customerId);
      if (ledger != null && ledger['current_balance'] != null) {
        currentBal = (ledger['current_balance'] as num).toDouble();
      }
    }

    if (mounted) {
      setState(() {
        _totalDues = currentBal;
        if (_isFullPay) {
          _amountPaid = _totalDues;
          _amountPaidController.text = _totalDues.toStringAsFixed(0);
        } else {
          _amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
        }
        _calculateMath();
      });
    }
  }

  void _calculateMath() {
    _amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    setState(() {
      _remainingBalance = _totalDues - _amountPaid;
      if (_amountPaid > _totalDues && _totalDues > 0) {
        _exceedErrorMessage = '⚠️ Payment amount (₹${_amountPaid.toStringAsFixed(0)}) cannot exceed total due balance (₹${_totalDues.toStringAsFixed(0)})';
      } else {
        _exceedErrorMessage = null;
      }
    });
  }

  void _togglePaymentOption(bool isFull) {
    setState(() {
      _isFullPay = isFull;
      if (_isFullPay) {
        _amountPaid = _totalDues;
        _amountPaidController.text = _totalDues.toStringAsFixed(0);
      } else {
        _amountPaid = 0.0;
        _amountPaidController.text = '0';
      }
      _calculateMath();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _submitPaybill() async {
    if (_selectedCustomer == null || _amountPaid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer and enter a valid payment amount')),
      );
      return;
    }

    if (_amountPaid > _totalDues && _totalDues > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Payment amount (₹${_amountPaid.toStringAsFixed(0)}) cannot exceed total due balance (₹${_totalDues.toStringAsFixed(0)})'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final token = widget.authService.token!;

    final success = await ApiService.createPayment(
      token,
      _selectedCustomer!.customerId,
      _amountPaid,
      _paymentMode,
      _referenceController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '💳 PayBill Recorded! Paid: ₹${_amountPaid.toStringAsFixed(0)} | Remaining Due: ₹${_remainingBalance.toStringAsFixed(0)}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      _amountPaidController.text = '0';
      _referenceController.clear();
      _isFullPay = false;
      await _loadCustomers();
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else if (widget.onNavigate != null) {
        widget.onNavigate!(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Record Customer PayBill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Select Customer / Farmer
                  const Text('1. Select Farmer / Customer *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    items: _customers
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.customerName} (Due: ₹${c.currentBalance.toStringAsFixed(0)})', style: const TextStyle(color: Color(0xFF0F172A))),
                            ))
                        .toList(),
                    onChanged: _onCustomerChanged,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),

                  // Total Dues Live Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.goldPrimary.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL CURRENT DUES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.goldPrimary)),
                            Text('Outstanding bill balance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        Text(
                          '₹${_totalDues.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.goldPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Options: Full Pay vs Partial Pay
                  const Text('2. Select Payment Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Full Pay Option
                      Expanded(
                        child: InkWell(
                          onTap: () => _togglePaymentOption(true),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _isFullPay ? AppColors.tealPrimary.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isFullPay ? AppColors.tealPrimary : Colors.grey.withOpacity(0.4),
                                width: _isFullPay ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: _isFullPay,
                                  onChanged: (_) => _togglePaymentOption(true),
                                  activeColor: AppColors.tealPrimary,
                                ),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Full Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Clear 100% due', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Partial Pay Option
                      Expanded(
                        child: InkWell(
                          onTap: () => _togglePaymentOption(false),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: !_isFullPay ? AppColors.tealPrimary.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !_isFullPay ? AppColors.tealPrimary : Colors.grey.withOpacity(0.4),
                                width: !_isFullPay ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<bool>(
                                  value: false,
                                  groupValue: _isFullPay,
                                  onChanged: (_) => _togglePaymentOption(false),
                                  activeColor: AppColors.tealPrimary,
                                ),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Partial Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Pay custom part', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Amount Paid Input
                  Text(
                    _isFullPay ? 'Amount to Pay (Full Due)' : 'Enter Partial Amount to Pay (₹)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountPaidController,
                    keyboardType: TextInputType.number,
                    enabled: !_isFullPay,
                    onChanged: (_) => _calculateMath(),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  // Exceed Amount Red Error Banner
                  if (_exceedErrorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _exceedErrorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Live Math Calculation Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.tealPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.tealPrimary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LIVE DUE CALCULATION MATH:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Current Total Dues: ₹${_totalDues.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('- Paying: ₹${_amountPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Remaining Due Balance:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              '₹${_remainingBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _remainingBalance < 0 ? Colors.red : AppColors.tealPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Payment Mode Selection
                  const Text('3. Payment Mode & Reference Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _paymentMode,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('💵 Cash', style: TextStyle(color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'UPI / GPay', child: Text('📲 UPI / GPay', style: TextStyle(color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Bank Transfer', child: Text('🏦 Bank', style: TextStyle(color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Cheque', child: Text('📝 Cheque', style: TextStyle(color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) => setState(() => _paymentMode = val ?? 'Cash'),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: TextField(
                          controller: _referenceController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Ref / Txn No.',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _exceedErrorMessage != null ? null : _submitPaybill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Record Payment Receipt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
