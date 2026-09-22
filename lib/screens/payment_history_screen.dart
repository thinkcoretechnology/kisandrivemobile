import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kisan_loader.dart';
import '../utils/date_formatter.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final AuthService authService;

  const PaymentHistoryScreen({super.key, required this.authService});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<CustomerPayment> _allPayments = [];
  List<CustomerPayment> _filteredPayments = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final token = widget.authService.token;
    if (token == null) return;

    final payments = await ApiService.getPayments(token);
    if (mounted) {
      setState(() {
        _allPayments = payments;
        _filteredPayments = payments;
        _isLoading = false;
      });
    }
  }

  void _filterPayments(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredPayments = _allPayments;
      } else {
        final q = query.trim().toLowerCase();
        _filteredPayments = _allPayments.where((p) {
          final nameMatch = (p.customerName ?? '').toLowerCase().contains(q);
          final modeMatch = p.paymentMode.toLowerCase().contains(q);
          final refMatch = (p.referenceNumber ?? '').toLowerCase().contains(q);
          return nameMatch || modeMatch || refMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Customer Pay History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: KisanLoader(isSpinning: true, message: 'Loading Pay Receipts...'))
          : RefreshIndicator(
              onRefresh: _loadPayments,
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterPayments,
                      decoration: InputDecoration(
                        hintText: 'Search farmer name, payment mode, or UPI ref ID...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  // Entries Count Summary Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payment Receipts: ${_filteredPayments.length}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Payment Receipts List
                  Expanded(
                    child: _filteredPayments.isEmpty
                        ? const Center(
                            child: Text('No payment receipts found.', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _filteredPayments.length,
                            itemBuilder: (context, index) {
                              final p = _filteredPayments[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p.customerName ?? 'Farmer Customer',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '-₹${p.amountPaid.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Date: ${DateFormatter.formatDDMMYYYY(p.paymentDate)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.tealPrimary.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.tealPrimary.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              p.paymentMode,
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tealPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Ref ID: ${p.referenceNumber?.isNotEmpty == true ? p.referenceNumber : "N/A"}',
                                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                          ),
                                          Text(
                                            'Balance After Pay: ₹${p.balanceAfterPayment.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
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
