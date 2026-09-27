import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kisan_loader.dart';
import '../utils/date_formatter.dart';

class BillingHistoryScreen extends StatefulWidget {
  final AuthService authService;

  const BillingHistoryScreen({super.key, required this.authService});

  @override
  State<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends State<BillingHistoryScreen> {
  List<FieldWorkEntry> _allEntries = [];
  List<FieldWorkEntry> _filteredEntries = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final token = widget.authService.token;
    if (token == null) return;

    final entries = await ApiService.getFieldWorkEntries(token);
    if (mounted) {
      setState(() {
        _allEntries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });
    }
  }

  void _filterEntries(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredEntries = _allEntries;
      } else {
        final q = query.trim().toLowerCase();
        _filteredEntries = _allEntries.where((e) {
          final nameMatch = (e.customerName ?? '').toLowerCase().contains(q);
          final regMatch = (e.tractorRegistration ?? '').toLowerCase().contains(q);
          final serviceMatch = (e.serviceName ?? '').toLowerCase().contains(q);
          return nameMatch || regMatch || serviceMatch;
        }).toList();
      }
    });
  }

  String _formatDuration(double? hours) {
    if (hours == null || hours <= 0) return '-';
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '$h hrs $m mins';
    if (h > 0) return '$h hrs';
    return '$m mins';
  }

  void _showReceiptDialog(FieldWorkEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('🧾 Billing Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farmer: ${entry.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text('Tractor: ${entry.tractorRegistration} (${entry.tractorModel})', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
            const SizedBox(height: 4),
            Text('Service: ${entry.serviceName}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
            const SizedBox(height: 4),
            Text('Date: ${DateFormatter.formatDDMMYYYY(entry.entryDate)}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Payable Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                Text(
                  '₹${(entry.netPayable > 0 ? entry.netPayable : entry.totalAmount).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.tealPrimary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Field Billing History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: KisanLoader(isSpinning: true, message: 'Loading Billing History...'))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterEntries,
                      decoration: InputDecoration(
                        hintText: 'Search farmer, tractor registration, or work...',
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
                          'Total Billing Records: ${_filteredEntries.length}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Billing Entries List
                  Expanded(
                    child: _filteredEntries.isEmpty
                        ? const Center(
                            child: Text('No billing records found.', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _filteredEntries.length,
                            itemBuilder: (context, index) {
                              final b = _filteredEntries[index];
                              final duration = _formatDuration(b.actualHours);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${b.customerName ?? "Farmer"} (${b.tractorRegistration ?? "Fleet"})',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '₹${(b.netPayable > 0 ? b.netPayable : b.totalAmount).toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.tealPrimary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${b.serviceName ?? "Work"} • Date: ${DateFormatter.formatDDMMYYYY(b.entryDate)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          if (duration != '-')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.goldPrimary.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '⏱️ $duration',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.goldPrimary),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Rate: ₹${b.rateApplied.toStringAsFixed(0)} / ${b.billingUnit ?? "Unit"}',
                                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _showReceiptDialog(b),
                                            icon: const Icon(Icons.receipt, size: 14, color: AppColors.tealPrimary),
                                            label: const Text('Receipt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
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
