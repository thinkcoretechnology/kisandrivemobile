import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';

class AdminScreen extends StatefulWidget {
  final AuthService authService;

  const AdminScreen({super.key, required this.authService});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _users = [];
  List<SubscriptionRecord> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final token = widget.authService.token;
    if (token == null) return;

    final users = await ApiService.getAdminUsers(token);
    final subs = await ApiService.getAllSubscriptions(token);

    if (mounted) {
      setState(() {
        _users = users;
        _subscriptions = subs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👑 Super Admin Control Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldPrimary,
          tabs: const [
            Tab(text: 'Registered Users'),
            Tab(text: 'Subscriptions Master'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Registered Users Tab
                RefreshIndicator(
                  onRefresh: _loadAdminData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.tealPrimary,
                            child: Text('#${u.userId}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${u.mobileNumber} • ${u.role} • Plan: ${u.currentPlan ?? "None"}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: u.status == 'Active' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(u.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: u.status == 'Active' ? Colors.green : Colors.red)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Subscriptions Master Table Tab
                RefreshIndicator(
                  onRefresh: _loadAdminData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _subscriptions.length,
                    itemBuilder: (context, index) {
                      final s = _subscriptions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${s.userName} (#${s.userId})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('₹${s.subscriptionAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.tealPrimary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Plan: ${s.planName} • Mobile: ${s.mobileNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('Subscribe Dates: ${DateFormatter.formatDDMMYYYY(s.startDate)} to ${DateFormatter.formatDDMMYYYY(s.endDate)}', style: const TextStyle(fontSize: 11, color: AppColors.goldPrimary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
