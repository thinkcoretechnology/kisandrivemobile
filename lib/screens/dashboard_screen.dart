import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/network_service.dart';
import '../theme/app_theme.dart';
import 'paybill_screen.dart';
import 'billing_history_screen.dart';
import 'payment_history_screen.dart';
import 'expense_history_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import '../utils/date_formatter.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;
  final Function(int) onNavigate;

  const DashboardScreen({
    super.key,
    required this.authService,
    required this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardKPIs? _kpis;
  SubscriptionRecord? _mySub;
  List<FieldWorkEntry> _allEntries = [];
  List<CustomerPayment> _allPayments = [];
  List<Expense> _allExpenses = [];

  List<FieldWorkEntry> _recentBilling = [];
  List<CustomerPayment> _recentPayments = [];
  List<Expense> _recentExpenses = [];
  bool _isLoading = true;
  bool _hasCheckedSubscriptionPopup = false;

  // Period Filter Selection (This Week, Last Month, 3 Months, 6 Months, All Time)
  String _selectedPeriod = 'This Week';
  final List<String> _periods = ['This Week', 'Last Month', '3 Months', '6 Months', 'All Time'];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  bool _isOffline = false;

  Future<void> _loadDashboardData() async {
    final token = widget.authService.token;
    if (token == null) return;

    final hasNet = await NetworkService.isNetworkAvailable();
    if (!hasNet) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
        NetworkService.showNoInternetSnackbar(context);
      }
      return;
    }

    final kpis = await ApiService.getDashboardKPIs(token);
    final entries = await ApiService.getFieldWorkEntries(token);
    final payments = await ApiService.getPayments(token);
    final expenses = await ApiService.getExpenses(token);
    final mySub = await ApiService.getMySubscription(token);

    if (mounted) {
      setState(() {
        _isOffline = false;
        _kpis = kpis;
        _mySub = mySub;
        _allEntries = entries;
        _allPayments = payments;
        _allExpenses = expenses;

        _recentBilling = entries.take(10).toList();
        _recentPayments = payments.take(10).toList();
        _recentExpenses = expenses.take(5).toList();
        _isLoading = false;
      });

      // Post-Login check: If no active subscription, popup plan selection modal!
      if (!_hasCheckedSubscriptionPopup) {
        _hasCheckedSubscriptionPopup = true;
        if (mySub == null || mySub.status == 'No Subscription') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openSubscriptionModal();
          });
        }
      }
    }
  }

  Future<void> _openSubscriptionModal() async {
    final token = widget.authService.token;
    if (token == null) return;

    final plans = await ApiService.getSubscriptionPlans(token);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.card_membership, color: AppColors.goldPrimary, size: 24),
                    SizedBox(width: 8),
                    Text('🏷️ Select Subscription Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Text(
              'Choose a plan to activate fleet management features & update profile start/end dates',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final plan = plans[idx];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.tealPrimary)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.goldPrimary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('₹${plan.finalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${plan.days} Days Access | ${plan.description}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary, foregroundColor: Colors.white),
                              onPressed: () async {
                                final success = await ApiService.subscribePlan(token, plan.id);
                                if (success) {
                                  Navigator.pop(ctx);
                                  await _loadDashboardData();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('🎉 Subscribed to ${plan.name}! Profile start & end dates updated.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Subscribe & Update Profile Dates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
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

  Widget _buildSubscriptionNoticeBanner() {
    if (_mySub == null || _mySub!.endDate.isEmpty) return const SizedBox.shrink();

    try {
      final endDate = DateTime.parse(_mySub!.endDate);
      final now = DateTime.now();
      final differenceInDays = endDate.difference(now).inDays;

      // 3.1: 1 Week Before Expiry Warning Banner (0 to 7 days remaining)
      if (differenceInDays >= 0 && differenceInDays <= 7) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.shade300, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Subscription Expiring Soon (${differenceInDays == 0 ? "Today" : "$differenceInDays Days Left"})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB45309)),
                    ),
                    Text(
                      'Plan (${_mySub!.planName}) expires on ${_mySub!.endDate}. Renew now.',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF78350F)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openSubscriptionModal,
                child: const Text('Renew', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontSize: 12)),
              ),
            ],
          ),
        );
      }

      // 3.2: 1 Week Grace Period Banner (-1 to -7 days past expiry)
      if (differenceInDays < 0) {
        final daysOverdue = differenceInDays.abs();
        if (daysOverdue <= 7) {
          final graceDaysRemaining = 7 - daysOverdue;
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade300, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, color: Colors.red, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⏰ 1-Week Grace Period Active ($graceDaysRemaining Days Left)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                      ),
                      Text(
                        'Expired on ${_mySub!.endDate}. Features active during grace period.',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF7F1D1D)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _openSubscriptionModal,
                  child: const Text('Renew', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                ),
              ],
            ),
          );
        } else {
          // Grace Period Over (> 7 Days overdue) -> New entries locked!
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade400, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.block, color: Colors.red, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⛔ Grace Period Expired - Entries Locked',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                      ),
                      Text(
                        'Subscription expired on ${_mySub!.endDate}. Pay subscription plan to unlock entry creation.',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF7F1D1D)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _openSubscriptionModal,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Renew Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {}

    return const SizedBox.shrink();
  }

  bool _isWithinRange(String dateStr) {
    if (_selectedPeriod == 'All Time') return true;
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt).inDays;
      if (_selectedPeriod == 'This Week') return diff <= 7;
      if (_selectedPeriod == 'Last Month') return diff <= 30;
      if (_selectedPeriod == '3 Months') return diff <= 90;
      if (_selectedPeriod == '6 Months') return diff <= 180;
      return true;
    } catch (_) {
      return true;
    }
  }

  double get _periodTotalBills {
    return _allEntries.where((e) => _isWithinRange(e.entryDate)).fold(0.0, (sum, e) => sum + e.totalAmount);
  }

  double get _periodReceivedAmount {
    return _allPayments.where((p) => _isWithinRange(p.paymentDate)).fold(0.0, (sum, p) => sum + p.amountPaid);
  }

  double get _periodBalanceAmount {
    if (_selectedPeriod == 'All Time') {
      return _kpis?.totalOutstandingDues ?? (_periodTotalBills - _periodReceivedAmount);
    }
    final bal = _periodTotalBills - _periodReceivedAmount;
    return bal > 0 ? bal : 0.0;
  }

  double get _periodExpenses {
    return _allExpenses.where((ex) => _isWithinRange(ex.expenseDate)).fold(0.0, (sum, ex) => sum + ex.amount);
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

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return NetworkService.buildOfflineWidget(
        onRetry: () {
          setState(() {
            _isLoading = true;
            _isOffline = false;
          });
          _loadDashboardData();
        },
      );
    }

    final user = widget.authService.currentUser;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.tealDark, AppColors.tealPrimary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.tealPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome, ${user?.fullName ?? "Tractor Owner"}',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user?.role ?? 'Tenant',
                          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mobile: ${user?.mobileNumber ?? "N/A"} | KisanDrive SaaS ERP Dashboard',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1-WEEK EXPIRY WARNING BANNER / 1-WEEK GRACE PERIOD BANNER
            _buildSubscriptionNoticeBanner(),

            // Quick Actions Launcher: Quick Bill, Pay Bills & Reports
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onNavigate(1),
                    icon: const Text('⚡'),
                    label: const Text('Quick Bill (<30s)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onNavigate(2),
                    icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                    label: const Text('Pay Bills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen(authService: widget.authService)));
                    },
                    icon: const Icon(Icons.bar_chart, size: 16, color: Colors.white),
                    label: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // INTERACTIVE FINANCIAL PERFORMANCE BAR CHART (WITH PERIOD SELECTOR: This Week, Last Month, 3 Months, 6 Months)
            if (!_isLoading) ...[
              _buildPeriodBarChartCard(),
              const SizedBox(height: 16),
            ],

            // 5 STYLISH EXECUTIVE KPI CARDS
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStylishKpiCard('Expenses', '₹${_kpis?.totalExpenses.toStringAsFixed(0) ?? "0"}', Icons.local_gas_station, Colors.red, const Color(0xFFFFF5F5), const Color(0xFFFEB2B2)),
                  _buildStylishKpiCard('Received Credit', '₹${_kpis?.totalCollections.toStringAsFixed(0) ?? "0"}', Icons.payments, Colors.teal, const Color(0xFFF0FDF4), const Color(0xFF99F6E4)),
                  _buildStylishKpiCard('Total Debt', '₹${_kpis?.totalOutstandingDues.toStringAsFixed(0) ?? "0"}', Icons.account_balance_wallet, Colors.amber.shade900, const Color(0xFFFFFBEB), const Color(0xFFFDE68A)),
                  _buildStylishKpiCard('Customer Count', '${_kpis?.totalCustomers ?? "0"} Farmers', Icons.people, Colors.blue.shade800, const Color(0xFFEFF6FF), const Color(0xFFBFDBFE)),
                ],
              ),
              const SizedBox(height: 12),

              _buildStylishKpiCard('Net Profit', '₹${_kpis?.netProfit.toStringAsFixed(0) ?? "0"}', Icons.trending_up, AppColors.tealPrimary, const Color(0xFFECFDF5), const Color(0xFFA7F3D0)),
              const SizedBox(height: 24),

              // SECTION 1: LAST 10 BILLING HISTORY LOGS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('⚡ Last 10 Billing History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BillingHistoryScreen(authService: widget.authService))),
                    child: const Text('View All', style: TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_recentBilling.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No field billing entries recorded yet.')))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentBilling.length,
                  itemBuilder: (ctx, i) {
                    final item = _recentBilling[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.tealPrimary.withOpacity(0.15),
                          child: const Text('🚜', style: TextStyle(fontSize: 18)),
                        ),
                        title: Text('${item.customerName ?? "Farmer"} - ₹${(item.netPayable > 0 ? item.netPayable : item.totalAmount).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          '📅 ${DateFormatter.formatDDMMYYYY(item.entryDate)} | ⏱️ ${_formatDuration(item.actualHours)} (${item.serviceName ?? "Work"})',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${(item.rateApplied > 0 ? item.rateApplied : (item.actualHours > 0 ? item.totalAmount / item.actualHours : item.totalAmount)).toStringAsFixed(0)}/hr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(item.tractorRegistration ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // SECTION 2: LAST 10 CUSTOMER PAY HISTORY LOGS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💳 Last 10 Customer Pay History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentHistoryScreen(authService: widget.authService))),
                    child: const Text('View All', style: TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_recentPayments.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No customer payments recorded yet.')))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentPayments.length,
                  itemBuilder: (ctx, i) {
                    final item = _recentPayments[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.15),
                          child: const Text('💰', style: TextStyle(fontSize: 18)),
                        ),
                        title: Text('${item.customerName} - ₹${item.amountPaid.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                        subtitle: Text(
                          '📅 ${DateFormatter.formatDDMMYYYY(item.paymentDate)} | 💳 ${item.paymentMode}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: Text(
                          (item.referenceNumber?.isNotEmpty == true) ? 'Ref: ${item.referenceNumber}' : 'Cash Receipt',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // SECTION 3: LAST 5 EXPENSE LOGS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('⛽ Last 5 Expense Logs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseHistoryScreen(authService: widget.authService))),
                    child: const Text('View All', style: TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_recentExpenses.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No expense logs recorded yet.')))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentExpenses.length,
                  itemBuilder: (ctx, i) {
                    final item = _recentExpenses[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.15),
                          child: const Text('⛽', style: TextStyle(fontSize: 18)),
                        ),
                        title: Text('${item.expenseCategory} - ₹${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                        subtitle: Text(
                          '📅 ${item.expenseDate} | 🚜 ${item.tractorRegistration ?? "General Fleet"}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: Text(
                          (item.notesOrBillNumber?.isNotEmpty == true) ? item.notesOrBillNumber! : 'Log',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Visual Bar Chart Comparison Card for Selected Range
  Widget _buildPeriodBarChartCard() {
    final bills = _periodTotalBills;
    final received = _periodReceivedAmount;
    final balance = _periodBalanceAmount;
    final expenses = _periodExpenses;

    final maxVal = [bills, received, balance, expenses, 1.0].reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 Financial Bar Chart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('Bills vs Received vs Dues vs Expenses', style: TextStyle(fontSize: 10, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 11),
                      items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPeriod = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bar 1: Total Bills Amount
            _buildSingleBarItem('⚡ Total Bills Amount', '₹${bills.toStringAsFixed(0)}', bills / maxVal, const Color(0xFF16A34A)),

            const SizedBox(height: 12),
            // Bar 2: Received Amount
            _buildSingleBarItem('💳 Received Amount', '₹${received.toStringAsFixed(0)}', received / maxVal, const Color(0xFF0284C7)),

            const SizedBox(height: 12),
            // Bar 3: Outstanding Dues / Balance Amount
            _buildSingleBarItem('💰 Outstanding Dues', '₹${balance.toStringAsFixed(0)}', balance / maxVal, const Color(0xFFD97706)),

            const SizedBox(height: 12),
            // Bar 4: Fleet Expenses
            _buildSingleBarItem('⛽ Fleet Expenses', '₹${expenses.toStringAsFixed(0)}', expenses / maxVal, const Color(0xFFDC2626)),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleBarItem(String label, String valueText, double ratio, Color barColor) {
    final clampedRatio = ratio.clamp(0.04, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            Text(valueText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: barColor)),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: clampedRatio,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(color: barColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStylishKpiCard(String title, String value, IconData icon, Color color, Color bgLight, Color borderColor) {
    final isCompact = MediaQuery.of(context).size.width <= 360;
    final titleFontSize = isCompact ? 10.0 : 11.0;
    final valueFontSize = isCompact ? 14.0 : 15.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isCompact ? 18 : 20),
          ),
          SizedBox(width: isCompact ? 6 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w900, color: color), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
