import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';

class ReportsScreen extends StatefulWidget {
  final AuthService authService;

  const ReportsScreen({super.key, required this.authService});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _selectedYear = DateTime.now().year; // Default = 2026
  final List<int> _years = [2026, 2025, 2024, 2023];

  List<FieldWorkEntry> _allEntries = [];
  List<CustomerPayment> _allPayments = [];
  List<Expense> _allExpenses = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    final token = widget.authService.token;
    if (token == null) return;

    final entries = await ApiService.getFieldWorkEntries(token);
    final payments = await ApiService.getPayments(token);
    final expenses = await ApiService.getExpenses(token);

    if (mounted) {
      setState(() {
        _allEntries = entries;
        _allPayments = payments;
        _allExpenses = expenses;
        _isLoading = false;
      });
    }
  }

  // Filtered lists for selected year
  List<FieldWorkEntry> get _filteredEntries {
    return _allEntries.where((e) {
      try {
        final dt = DateTime.parse(e.entryDate);
        return dt.year == _selectedYear;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<CustomerPayment> get _filteredPayments {
    return _allPayments.where((p) {
      try {
        final dt = DateTime.parse(p.paymentDate);
        return dt.year == _selectedYear;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<Expense> get _filteredExpenses {
    return _allExpenses.where((ex) {
      try {
        final dt = DateTime.parse(ex.expenseDate);
        return dt.year == _selectedYear;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // Year Financial Totals
  double get _yearBillingIncome {
    return _filteredEntries.fold(0.0, (sum, e) => sum + e.totalAmount);
  }

  double get _yearPaymentsReceived {
    return _filteredPayments.fold(0.0, (sum, p) => sum + p.amountPaid);
  }

  double get _yearTotalExpenses {
    return _filteredExpenses.fold(0.0, (sum, ex) => sum + ex.amount);
  }

  double get _yearNetProfit {
    return _yearBillingIncome - _yearTotalExpenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Year-Wise Reports & Financials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.tealPrimary),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
                items: _years
                    .map((y) => DropdownMenuItem(value: y, child: Text('📅 Year $y')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedYear = val);
                },
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.tealPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.tealPrimary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '⚡ Billing History'),
            Tab(text: '💳 PayBills Received'),
            Tab(text: '⛽ Expense Logs'),
            Tab(text: '📈 Profit & Loss'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Financial Overview Cards for Selected Year
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFF8FAFC),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildReportKPICard(
                            'BILLING INCOME ($_selectedYear)',
                            '₹${_yearBillingIncome.toStringAsFixed(0)}',
                            '${_filteredEntries.length} bills generated',
                            const Color(0xFF16A34A),
                            Colors.green.shade50,
                          ),
                          const SizedBox(width: 10),
                          _buildReportKPICard(
                            'PAYBILLS RECEIVED ($_selectedYear)',
                            '₹${_yearPaymentsReceived.toStringAsFixed(0)}',
                            '${_filteredPayments.length} cash receipts',
                            const Color(0xFF0284C7),
                            Colors.lightBlue.shade50,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildReportKPICard(
                            'FLEET EXPENSES ($_selectedYear)',
                            '₹${_yearTotalExpenses.toStringAsFixed(0)}',
                            '${_filteredExpenses.length} expense logs',
                            const Color(0xFFDC2626),
                            Colors.red.shade50,
                          ),
                          const SizedBox(width: 10),
                          _buildReportKPICard(
                            'NET PROFIT / LOSS ($_selectedYear)',
                            '₹${_yearNetProfit.toStringAsFixed(0)}',
                            _yearNetProfit >= 0 ? '🟢 Profit Margins' : '🔴 Net Deficit',
                            _yearNetProfit >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            _yearNetProfit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBillingTab(),
                      _buildPayBillsTab(),
                      _buildExpensesTab(),
                      _buildProfitLossTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReportKPICard(String title, String value, String sub, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
            Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  // TAB 1: Billing History
  Widget _buildBillingTab() {
    final list = _filteredEntries;
    if (list.isEmpty) {
      return Center(
        child: Text('No billing entries found for Year $_selectedYear.', style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final e = list[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(Icons.bolt, color: Color(0xFF16A34A), size: 20),
            ),
            title: Text('${e.customerName} - ₹${e.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('📅 ${DateFormatter.formatDDMMYYYY(e.entryDate)} | 🚜 ${e.tractorRegistration} | 🛠️ ${e.serviceName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rate: ₹${e.rateApplied.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(e.actualHours > 0 ? '${e.actualHours.toStringAsFixed(1)} hrs' : '${e.loadCount} loads', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 2: PayBills Received
  Widget _buildPayBillsTab() {
    final list = _filteredPayments;
    if (list.isEmpty) {
      return Center(
        child: Text('No payment receipts found for Year $_selectedYear.', style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final p = list[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2FE),
              child: Icon(Icons.payment, color: Color(0xFF0284C7), size: 20),
            ),
            title: Text('${p.customerName} - ₹${p.amountPaid.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('📅 ${DateFormatter.formatDDMMYYYY(p.paymentDate)} | 💳 Mode: ${p.paymentMode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Text(
              (p.referenceNumber?.isNotEmpty == true) ? 'Ref: ${p.referenceNumber}' : 'Cash Receipt',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
            ),
          ),
        );
      },
    );
  }

  // TAB 3: Expense Logs
  Widget _buildExpensesTab() {
    final list = _filteredExpenses;
    if (list.isEmpty) {
      return Center(
        child: Text('No expense logs found for Year $_selectedYear.', style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final ex = list[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.local_gas_station, color: Color(0xFFDC2626), size: 20),
            ),
            title: Text('${ex.expenseCategory} - ₹${ex.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('📅 ${DateFormatter.formatDDMMYYYY(ex.expenseDate)} | 🚜 ${ex.tractorRegistration ?? "General Fleet"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: Text(
              (ex.notesOrBillNumber?.isNotEmpty == true) ? ex.notesOrBillNumber! : 'Log',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  // TAB 4: Profit & Loss Month-by-Month Table
  Widget _buildProfitLossTab() {
    final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📈 Month-by-Month P&L Statement ($_selectedYear)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Table(
                border: TableBorder.all(color: Colors.grey.shade200, width: 1),
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: const [
                      Padding(padding: EdgeInsets.all(8), child: Text('Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Income (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Expense (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Net (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                  for (int m = 1; m <= 12; m++) ...[
                    _buildMonthTableRow(m, monthNames[m - 1]),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildMonthTableRow(int month, String monthName) {
    double mIncome = 0.0;
    double mExpense = 0.0;

    for (final e in _filteredEntries) {
      try {
        if (DateTime.parse(e.entryDate).month == month) mIncome += e.totalAmount;
      } catch (_) {}
    }

    for (final ex in _filteredExpenses) {
      try {
        if (DateTime.parse(ex.expenseDate).month == month) mExpense += ex.amount;
      } catch (_) {}
    }

    final net = mIncome - mExpense;

    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8), child: Text('₹${mIncome.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A)))),
        Padding(padding: const EdgeInsets.all(8), child: Text('₹${mExpense.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '₹${net.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: net >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
          ),
        ),
      ],
    );
  }
}
