import 'package:flutter/material.dart';
import '../models/saas_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatter.dart';

class SubscriptionsScreen extends StatefulWidget {
  final AuthService authService;

  const SubscriptionsScreen({super.key, required this.authService});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<SubscriptionPlan> _plans = [];
  SubscriptionRecord? _mySub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final token = widget.authService.token;
    if (token == null) return;

    final plans = await ApiService.getSubscriptionPlans(token);
    final mySub = await ApiService.getMySubscription(token);

    if (mounted) {
      setState(() {
        _plans = plans;
        _mySub = mySub;
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Subscribe to ${plan.name}'),
        content: Text('Confirm subscription for ₹${plan.finalPrice.toStringAsFixed(0)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final token = widget.authService.token;
      if (token == null) return;

      final success = await ApiService.subscribePlan(token, plan.id);
      if (success) {
        widget.authService.notifyListeners();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Successfully subscribed to ${plan.name}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadData();
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Subscriptions & Plans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Active Subscription Banner
                  if (_mySub != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.tealPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.tealPrimary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR ACTIVE SUBSCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
                          const SizedBox(height: 4),
                          Text(_mySub!.planName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Valid until: ${DateFormatter.formatDDMMYYYY(_mySub!.endDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text('Available Subscription Packages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  ..._plans.map((plan) {
                    final isActive = _mySub?.planName == plan.name;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isActive ? AppColors.goldPrimary : Colors.transparent, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(plan.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                if (plan.discountPercentage > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldPrimary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${plan.discountPercentage.toStringAsFixed(0)}% OFF',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(plan.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan.finalPrice == 0 ? 'FREE' : '₹${plan.finalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.tealPrimary),
                                    ),
                                    if (plan.discountPercentage > 0)
                                      Text('₹${plan.originalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: isActive ? null : () => _subscribe(plan),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isActive ? Colors.grey : AppColors.tealPrimary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(isActive ? 'Active Plan' : 'Subscribe'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
