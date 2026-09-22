import 'dart:convert';
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/quick_bill_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_customer_screen.dart';
import 'screens/add_tractor_screen.dart';
import 'screens/master_works_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/paybill_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/reports_screen.dart';

void main() {
  runApp(const TracktorMobileApp());
}

class TracktorMobileApp extends StatefulWidget {
  const TracktorMobileApp({super.key});

  @override
  State<TracktorMobileApp> createState() => _TracktorMobileAppState();
}

class _TracktorMobileAppState extends State<TracktorMobileApp> {
  final AuthService _authService = AuthService();
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _authService.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KisanDrive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: _showSplash
          ? SplashScreen(
              authService: _authService,
              onSplashComplete: () => setState(() => _showSplash = false),
            )
          : _authService.isLoggedIn
              ? MainNavigationWrapper(authService: _authService)
              : LoginScreen(
                  authService: _authService,
                  onLoginSuccess: () => setState(() {}),
                ),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  final AuthService authService;

  const MainNavigationWrapper({super.key, required this.authService});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  String _getTwoInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'TU';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final f = parts[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final s = parts[1].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      if (f.isNotEmpty && s.isNotEmpty) {
        return (f[0] + s[0]).toUpperCase();
      }
    }
    final clean = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.length >= 2) {
      return clean.substring(0, 2).toUpperCase();
    }
    return clean.isNotEmpty ? clean[0].toUpperCase() : 'TU';
  }

  ImageProvider? _getAvatarImageProvider(String? img) {
    if (img == null || img.trim().isEmpty) return null;
    final clean = img.trim();
    if (clean.startsWith('data:image')) {
      try {
        final base64Str = clean.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return NetworkImage(clean);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final isSuperAdmin = user?.role == 'Super Admin';
    final avatarProvider = _getAvatarImageProvider(user?.profileImage);

    final List<Widget> bottomScreens = [
      DashboardScreen(
        key: ValueKey('dash_$_currentIndex'),
        authService: widget.authService,
        onNavigate: (idx) => setState(() => _currentIndex = idx),
      ),
      QuickBillScreen(
        key: ValueKey('quickbill_$_currentIndex'),
        authService: widget.authService,
        onNavigate: (idx) => setState(() => _currentIndex = idx),
      ),
      PaybillScreen(
        key: ValueKey('paybill_$_currentIndex'),
        authService: widget.authService,
        onNavigate: (idx) => setState(() => _currentIndex = idx),
      ),
      ExpensesScreen(
        key: ValueKey('expense_$_currentIndex'),
        authService: widget.authService,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                children: [
                  TextSpan(text: 'Kisan', style: TextStyle(color: Color(0xFF22C55E))),
                  TextSpan(text: 'Drive ', style: TextStyle(color: Color(0xFFFACC15))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tealPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.tealPrimary),
              ),
              child: const Text('ERP', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: AppColors.tealPrimary)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => widget.authService.logout(),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.tealDark, AppColors.tealPrimary]),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.fullName ?? 'Tenant User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mobile: ${user?.mobileNumber ?? "N/A"}',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Role: ${user?.role ?? "Tractor Owner"}',
                          style: const TextStyle(fontSize: 10, color: AppColors.goldPrimary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen(authService: widget.authService)),
                      );
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.goldPrimary,
                      backgroundImage: avatarProvider,
                      child: avatarProvider != null
                          ? null
                          : Text(
                              _getTwoInitials(user?.fullName),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person, color: AppColors.tealPrimary),
              title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(authService: widget.authService),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.precision_manufacturing, color: AppColors.tealPrimary),
              title: const Text('Tractors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddTractorScreen(authService: widget.authService)));
              },
            ),

            ListTile(
              leading: const Icon(Icons.people, color: AppColors.tealPrimary),
              title: const Text('Farmers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddCustomerScreen(authService: widget.authService)));
              },
            ),

            ListTile(
              leading: const Icon(Icons.bolt, color: AppColors.goldPrimary),
              title: const Text('Quick Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),

            ListTile(
              leading: const Icon(Icons.payment, color: AppColors.goldPrimary),
              title: const Text('PayBill (Clear Dues)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),

            ListTile(
              leading: const Icon(Icons.build, color: AppColors.tealPrimary),
              title: const Text('Master Works', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => MasterWorksScreen(authService: widget.authService)));
              },
            ),

            ListTile(
              leading: const Icon(Icons.local_gas_station, color: Colors.red),
              title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),

            ListTile(
              leading: const Icon(Icons.bar_chart, color: AppColors.tealPrimary),
              title: const Text('Year-Wise Reports & P&L', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen(authService: widget.authService)));
              },
            ),

            ListTile(
              leading: const Icon(Icons.card_membership, color: AppColors.goldPrimary),
              title: const Text('Subscriptions & Plans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionsScreen(authService: widget.authService)));
              },
            ),

            if (isSuperAdmin) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                title: const Text('👑 Super Admin Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(authService: widget.authService)));
                },
              ),
            ],

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                widget.authService.logout();
              },
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: _currentIndex < bottomScreens.length ? _currentIndex : 0,
        children: bottomScreens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < bottomScreens.length ? _currentIndex : 0,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: AppColors.tealPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Quick Bill'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'PayBills'),
          BottomNavigationBarItem(icon: Icon(Icons.local_gas_station), label: 'Expenses'),
        ],
      ),
    );
  }
}
