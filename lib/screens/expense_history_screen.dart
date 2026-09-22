import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kisan_loader.dart';
import '../utils/date_formatter.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  final AuthService authService;

  const ExpenseHistoryScreen({super.key, required this.authService});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final token = widget.authService.token;
    if (token == null) return;

    final expenses = await ApiService.getExpenses(token);
    if (mounted) {
      setState(() {
        _allExpenses = expenses;
        _filteredExpenses = expenses;
        _isLoading = false;
      });
    }
  }

  void _filterExpenses(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredExpenses = _allExpenses;
      } else {
        final q = query.trim().toLowerCase();
        _filteredExpenses = _allExpenses.where((e) {
          final catMatch = e.expenseCategory.toLowerCase().contains(q);
          final regMatch = (e.tractorRegistration ?? '').toLowerCase().contains(q);
          final notesMatch = (e.notesOrBillNumber ?? '').toLowerCase().contains(q);
          return catMatch || regMatch || notesMatch;
        }).toList();
      }
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Diesel':
        return Colors.amber.shade800;
      case 'Driver Betta':
        return Colors.blue.shade700;
      case 'Maintenance':
        return Colors.red.shade700;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⛽ Fleet Expense History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: KisanLoader(isSpinning: true, message: 'Loading Expense Logs...'))
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              child: Column(
                children: [
                  // Top Search Box (Above Expense Cards)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterExpenses,
                      decoration: InputDecoration(
                        hintText: 'Search category (Diesel/Betta), tractor, or notes...',
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
                          'Total Expense Logs: ${_filteredExpenses.length}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Expense Records List
                  Expanded(
                    child: _filteredExpenses.isEmpty
                        ? const Center(
                            child: Text('No expense records found.', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _filteredExpenses.length,
                            itemBuilder: (context, index) {
                              final e = _filteredExpenses[index];
                              final color = _getCategoryColor(e.expenseCategory);

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
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: color.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              e.expenseCategory,
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                                            ),
                                          ),
                                          Text(
                                            '₹${e.amount.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Tractor: ${e.tractorRegistration ?? "General Fleet"}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Date: ${DateFormatter.formatDDMMYYYY(e.expenseDate)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Notes/Bill: ${e.notesOrBillNumber?.isNotEmpty == true ? e.notesOrBillNumber : "N/A"}',
                                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
