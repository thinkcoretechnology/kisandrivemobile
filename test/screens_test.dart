import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisandrive_mobile/main.dart';
import 'package:kisandrive_mobile/services/auth_service.dart';
import 'package:kisandrive_mobile/theme/app_theme.dart';
import 'package:kisandrive_mobile/screens/login_screen.dart';
import 'package:kisandrive_mobile/screens/dashboard_screen.dart';
import 'package:kisandrive_mobile/screens/quick_bill_screen.dart';
import 'package:kisandrive_mobile/screens/paybill_screen.dart';
import 'package:kisandrive_mobile/screens/expenses_screen.dart';
import 'package:kisandrive_mobile/screens/add_customer_screen.dart';
import 'package:kisandrive_mobile/screens/add_tractor_screen.dart';
import 'package:kisandrive_mobile/screens/master_works_screen.dart';
import 'package:kisandrive_mobile/screens/billing_history_screen.dart';
import 'package:kisandrive_mobile/screens/payment_history_screen.dart';
import 'package:kisandrive_mobile/screens/expense_history_screen.dart';
import 'package:kisandrive_mobile/screens/reports_screen.dart';
import 'package:kisandrive_mobile/screens/subscriptions_screen.dart';
import 'package:kisandrive_mobile/screens/profile_screen.dart';
import 'package:kisandrive_mobile/screens/admin_screen.dart';

Widget createWidgetForTesting({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.lightTheme,
    themeMode: ThemeMode.light,
    home: child,
  );
}

void main() {
  final testAuthService = AuthService();

  group('📱 KisanDrive Mobile All Screens Automated Test Suite', () {
    testWidgets('1. App Root Loads TracktorMobileApp Widget', (WidgetTester tester) async {
      await tester.pumpWidget(const TracktorMobileApp());
      expect(find.byType(TracktorMobileApp), findsOneWidget);
    });

    testWidgets('2. LoginScreen Renders Brand Header & Inputs', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: LoginScreen(
          authService: testAuthService,
          onLoginSuccess: () {},
        ),
      ));

      expect(find.text('Kisan'), findsOneWidget);
      expect(find.text('Sign In to Account'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(0)); // Standard TextFields used
      expect(find.text('Mobile Number (10 Digits) *'), findsOneWidget);
      expect(find.text('Password *'), findsOneWidget);
    });

    testWidgets('3. DashboardScreen Renders Financial Bar Chart Header & Action Shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: DashboardScreen(
          authService: testAuthService,
          onNavigate: (index) {},
        ),
      ));

      expect(find.text('Quick Bill\n(<30s)'), findsOneWidget);
      expect(find.text('Pay Bills'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
    });

    testWidgets('4. QuickBillScreen Renders Field Entry Forms', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: QuickBillScreen(
          authService: testAuthService,
          onNavigate: (index) {},
        ),
      ));

      expect(find.text('⚡ Billing & Field Entry'), findsOneWidget);
      expect(find.text('1. Billing Date (Max: Today) *'), findsOneWidget);
      expect(find.text('2. Select Tractor Machine *'), findsOneWidget);
    });

    testWidgets('5. PaybillScreen Renders Payment Receipt Entry Forms', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: PaybillScreen(
          authService: testAuthService,
          onNavigate: (index) {},
        ),
      ));

      expect(find.text('💳 Record Customer PayBill'), findsOneWidget);
      expect(find.text('1. Select Farmer / Customer *'), findsOneWidget);
      expect(find.text('2. Select Payment Option'), findsOneWidget);
    });

    testWidgets('6. ExpensesScreen Renders Fleet Expense Management Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: ExpensesScreen(authService: testAuthService),
      ));

      expect(find.text('⛽ Fleet Expense Management'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('7. AddCustomerScreen Renders Farmers Directory Header & Search Bar', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: AddCustomerScreen(authService: testAuthService),
      ));

      expect(find.text('👨‍🌾 Farmers Directory & Ledger'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('8. AddTractorScreen Renders Tractor Fleet Registry Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: AddTractorScreen(authService: testAuthService),
      ));

      expect(find.text('🚜 Tractor Fleet Registry'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('9. MasterWorksScreen Renders Master Work Services Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: MasterWorksScreen(authService: testAuthService),
      ));

      expect(find.text('🛠️ Master Work Services & Rates'), findsOneWidget);
    });

    testWidgets('10. BillingHistoryScreen Renders Field Billing History Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: BillingHistoryScreen(authService: testAuthService),
      ));

      expect(find.text('⚡ Field Billing History'), findsOneWidget);
    });

    testWidgets('11. PaymentHistoryScreen Renders Customer Pay History Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: PaymentHistoryScreen(authService: testAuthService),
      ));

      expect(find.text('💳 Customer Pay History'), findsOneWidget);
    });

    testWidgets('12. ExpenseHistoryScreen Renders Fleet Expense History Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: ExpenseHistoryScreen(authService: testAuthService),
      ));

      expect(find.text('⛽ Fleet Expense History'), findsOneWidget);
    });

    testWidgets('13. ReportsScreen Renders Year-Wise Reports & Financials Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: ReportsScreen(authService: testAuthService),
      ));

      expect(find.text('📊 Year-Wise Reports & Financials'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('14. SubscriptionsScreen Renders SaaS Packages Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: SubscriptionsScreen(authService: testAuthService),
      ));

      expect(find.text('💳 Subscriptions & ERP Plans'), findsOneWidget);
    });

    testWidgets('15. ProfileScreen Renders Profile & Settings Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: ProfileScreen(authService: testAuthService),
      ));

      expect(find.text('👤 Profile & Settings'), findsOneWidget);
    });

    testWidgets('16. AdminScreen Renders Super Admin Control Center Header', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(
        child: AdminScreen(authService: testAuthService),
      ));

      expect(find.text('👑 Super Admin Control Center'), findsOneWidget);
    });
  });
}
