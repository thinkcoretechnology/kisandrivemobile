import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/saas_models.dart';

class ApiService {
  static String customHostUrl = '';
  static String? _resolvedBaseUrl;

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Public getter for dynamic API Base URL
  static Future<String> getBaseUrl() async {
    return _getBaseUrl();
  }

  // Fast Auto-Prober: Finds the working host in <1s (localhost vs 10.0.2.2)
  static Future<String> _getBaseUrl() async {
    if (customHostUrl.isNotEmpty) {
      return customHostUrl.endsWith('/api') ? customHostUrl : '$customHostUrl/api';
    }
    if (_resolvedBaseUrl != null) {
      return _resolvedBaseUrl!;
    }

    final candidates = [
      'https://kisandrive.thinkcoretechnology.com/api',
      'http://kisandrive.thinkcoretechnology.com/api',
      'http://127.0.0.1:5005/api',
      'http://localhost:5005/api',
      'http://10.0.2.2:5005/api',
      'http://192.168.31.125:5005/api',
    ];

    for (final host in candidates) {
      try {
        final res = await http.get(Uri.parse('$host/health')).timeout(const Duration(milliseconds: 1200));
        if (res.statusCode == 200) {
          _resolvedBaseUrl = host;
          print('⚡ KisanDrive Connected to API Host: $host');
          return host;
        }
      } catch (_) {}
    }

    // Default Production API Base URL
    return 'https://kisandrive.thinkcoretechnology.com/api';
  }

  // Smart Request Helper
  static Future<http.Response> _get(String path, String? token) async {
    final host = await _getBaseUrl();
    try {
      return await http.get(Uri.parse('$host$path'), headers: _headers(token)).timeout(const Duration(seconds: 5));
    } catch (e) {
      _resolvedBaseUrl = null; // Reset on failure to re-probe
      rethrow;
    }
  }

  static Future<http.Response> _post(String path, String? token, dynamic body) async {
    final host = await _getBaseUrl();
    final jsonStr = jsonEncode(body);
    try {
      return await http.post(Uri.parse('$host$path'), headers: _headers(token), body: jsonStr).timeout(const Duration(seconds: 5));
    } catch (e) {
      _resolvedBaseUrl = null;
      rethrow;
    }
  }

  static Future<http.Response> _put(String path, String? token, dynamic body) async {
    final host = await _getBaseUrl();
    final jsonStr = jsonEncode(body);
    try {
      return await http.put(Uri.parse('$host$path'), headers: _headers(token), body: jsonStr).timeout(const Duration(seconds: 5));
    } catch (e) {
      _resolvedBaseUrl = null;
      rethrow;
    }
  }

  static Future<http.Response> _delete(String path, String? token) async {
    final host = await _getBaseUrl();
    try {
      return await http.delete(Uri.parse('$host$path'), headers: _headers(token)).timeout(const Duration(seconds: 5));
    } catch (e) {
      _resolvedBaseUrl = null;
      rethrow;
    }
  }

  // Dashboard KPIs
  static Future<DashboardKPIs?> getDashboardKPIs(String token) async {
    try {
      final res = await _get('/reports/dashboard-summary', token);
      if (res.statusCode == 200) {
        return DashboardKPIs.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('API Error [getDashboardKPIs]: $e');
    }
    return null;
  }

  // Profile & User
  static Future<User?> getProfile(String token) async {
    try {
      final res = await _get('/auth/me', token);
      if (res.statusCode == 200) {
        return User.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('API Error [getProfile]: $e');
    }
    return null;
  }

  static Future<User?> updateProfile(String token, Map<String, dynamic> data) async {
    try {
      final res = await _put('/auth/profile', token, data);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return User.fromJson(body['user']);
      }
    } catch (e) {
      print('API Error [updateProfile]: $e');
    }
    return null;
  }

  // Tractors
  static Future<List<Tractor>> getTractors(String token) async {
    try {
      final res = await _get('/tractors', token);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => Tractor.fromJson(e)).toList();
      }
    } catch (e) {
      print('API Error [getTractors]: $e');
    }
    return [];
  }

  static Future<bool> createTractor(String token, Map<String, dynamic> data) async {
    try {
      final res = await _post('/tractors', token, data);
      return res.statusCode == 201;
    } catch (e) {
      print('API Error [createTractor]: $e');
      return false;
    }
  }

  static Future<bool> updateTractor(String token, int tractorId, Map<String, dynamic> data) async {
    try {
      final res = await _put('/tractors/$tractorId', token, data);
      return res.statusCode == 200;
    } catch (e) {
      print('API Error [updateTractor]: $e');
      return false;
    }
  }

  static Future<bool> deleteTractor(String token, int tractorId) async {
    try {
      final res = await _delete('/tractors/$tractorId', token);
      return res.statusCode == 200;
    } catch (e) {
      print('API Error [deleteTractor]: $e');
      return false;
    }
  }

  // Customers
  static Future<List<Customer>> getCustomers(String token) async {
    try {
      final res = await _get('/customers', token);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => Customer.fromJson(e)).toList();
      }
    } catch (e) {
      print('API Error [getCustomers]: $e');
    }
    return [];
  }

  static Future<Customer?> createCustomer(String token, String name, String phone, String village, String gender, String pincode, double openingBal, String status) async {
    try {
      final res = await _post(
        '/customers',
        token,
        {
          'customer_name': name,
          'primary_phone': phone,
          'village_location': village,
          'gender': gender,
          'pincode': pincode,
          'opening_balance': openingBal,
          'status': status,
        },
      );
      if (res.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        return Customer.fromJson(data);
      }
    } catch (e) {
      print('API Error [createCustomer]: $e');
    }
    return null;
  }

  static Future<bool> updateCustomer(String token, int customerId, String name, String phone, String village, String gender, String pincode, double openingBal, String status) async {
    try {
      final res = await _put(
        '/customers/$customerId',
        token,
        {
          'customer_name': name,
          'primary_phone': phone,
          'village_location': village,
          'gender': gender,
          'pincode': pincode,
          'opening_balance': openingBal,
          'status': status,
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      print('API Error [updateCustomer]: $e');
      return false;
    }
  }

  static Future<bool> deleteCustomer(String token, int customerId) async {
    try {
      final res = await _delete('/customers/$customerId', token);
      return res.statusCode == 200;
    } catch (e) {
      print('API Error [deleteCustomer]: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCustomerLedger(String token, int customerId) async {
    try {
      final res = await _get('/customers/$customerId/ledger', token);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('API Error [getCustomerLedger]: $e');
    }
    return null;
  }

  // Work Services
  static Future<List<WorkService>> getWorkServices(String token) async {
    try {
      final res = await _get('/work-services', token);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => WorkService.fromJson(e)).toList();
      }
    } catch (e) {
      print('API Error [getWorkServices]: $e');
    }
    return [];
  }

  static Future<bool> createWorkService(String token, dynamic p1, [dynamic p2, dynamic p3]) async {
    try {
      Map<String, dynamic> body;
      if (p1 is Map<String, dynamic>) {
        body = p1;
      } else {
        body = {
          'service_name': p1.toString(),
          'billing_unit': p2.toString(),
          'default_rate': p3 is num ? p3.toDouble() : double.tryParse(p3.toString()) ?? 0.0,
        };
      }
      final res = await _post('/work-services', token, body);
      return res.statusCode == 201;
    } catch (e) {
      print('API Error [createWorkService]: $e');
      return false;
    }
  }

  static Future<bool> updateWorkService(String token, int serviceId, dynamic p1, [dynamic p2, dynamic p3]) async {
    try {
      Map<String, dynamic> body;
      if (p1 is Map<String, dynamic>) {
        body = p1;
      } else {
        body = {
          'service_name': p1.toString(),
          'billing_unit': p2.toString(),
          'default_rate': p3 is num ? p3.toDouble() : double.tryParse(p3.toString()) ?? 0.0,
        };
      }
      final res = await _put('/work-services/$serviceId', token, body);
      return res.statusCode == 200;
    } catch (e) {
      print('API Error [updateWorkService]: $e');
      return false;
    }
  }

  static Future<bool> deleteWorkService(String token, int serviceId) async {
    try {
      final res = await _delete('/work-services/$serviceId', token);
      return res.statusCode == 200;
    } catch (e) {
      print('API Error [deleteWorkService]: $e');
      return false;
    }
  }

  // Field Work Entries
  static Future<List<FieldWorkEntry>> getFieldWorkEntries(String token) async {
    try {
      final res = await _get('/field-work', token);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => FieldWorkEntry.fromJson(e)).toList();
      }
    } catch (e) {
      print('API Error [getFieldWorkEntries]: $e');
    }
    return [];
  }

  static Future<bool> createFieldWorkEntry(
    String token,
    dynamic p1, [
    dynamic p2,
    dynamic p3,
    dynamic p4,
    dynamic p5,
    dynamic p6,
    dynamic p7,
    dynamic p8,
    dynamic p9,
  ]) async {
    try {
      Map<String, dynamic> data;
      if (p1 is Map<String, dynamic>) {
        data = p1;
      } else {
        data = {
          'entry_date': p1?.toString(),
          'tractor_id': p2,
          'customer_id': p3,
          'service_id': p4,
          'actual_hours': p5,
          'load_count': p6,
          'rate_applied': p7,
          'applied_rate': p7,
          'one_time_manual_billing_time_adjustment': p8,
          'manual_bill_amount': p8,
          'adjustment_remarks': p9,
          'remarks': p9,
        };
      }
      final res = await _post('/field-work', token, data);
      return res.statusCode == 201;
    } catch (e) {
      print('API Error [createFieldWorkEntry]: $e');
      return false;
    }
  }

  // Payments
  static Future<List<CustomerPayment>> getPayments(String token) async {
    try {
      final res = await _get('/payments', token);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => CustomerPayment.fromJson(e)).toList();
      }
    } catch (e) {
      print('API Error [getPayments]: $e');
    }
    return [];
  }

  static Future<bool> createPayment(String token, int customerId, double amountPaid, String paymentMode, String referenceNumber) async {
    try {
      final res = await _post(
        '/payments',
        token,
        {
          'customer_id': customerId,
          'amount_paid': amountPaid,
          'payment_mode': paymentMode,
          'reference_number': referenceNumber,
        },
      );
      return res.statusCode == 201;
    } catch (e) {
      print('API Error [createPayment]: $e');
      return false;
    }
  }

  // Expenses
  static Future<List<Expense>> getExpenses(String token) async {
    try {
      final res = await _get('/expenses', token);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => Expense.fromJson(e)).toList();
      }
    } catch (e) {
      print('API Error [getExpenses]: $e');
    }
    return [];
  }

  static Future<bool> createExpense(String token, String category, double amount, int? tractorId, String notes) async {
    try {
      final res = await _post(
        '/expenses',
        token,
        {
          'expense_category': category,
          'amount': amount,
          'tractor_id': tractorId,
          'notes_or_bill_number': notes,
        },
      );
      return res.statusCode == 201;
    } catch (e) {
      print('API Error [createExpense]: $e');
      return false;
    }
  }

  static Future<bool> updateExpense(String token, int expenseId, String category, double amount, int? tractorId, String notes) async {
    try {
      final res = await _put(
        '/expenses/$expenseId',
        token,
        {
          'expense_category': category,
          'amount': amount,
          'tractor_id': tractorId,
          'notes_or_bill_number': notes,
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      print('API Error [updateExpense]: $e');
      return false;
    }
  }

  static Future<bool> deleteExpense(String token, int expenseId) async {
    try {
      final res = await _delete('/expenses/$expenseId', token);
      return res.statusCode == 200;
    } catch (e) {
      print('API Error [deleteExpense]: $e');
      return false;
    }
  }

  // Subscriptions
  static Future<List<SubscriptionPlan>> getSubscriptionPlans(String token) async {
    try {
      final res = await _get('/subscriptions/plans', token);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => SubscriptionPlan.fromJson(e)).toList();
      }
    } catch (e) {
      print('API Error [getSubscriptionPlans]: $e');
    }
    return [];
  }

  static Future<SubscriptionRecord?> getMySubscription(String token) async {
    try {
      final res = await _get('/subscriptions/my-subscription', token);
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        if (data['subscription_id'] == null && data['plan_name'] == null) {
          return null;
        }
        return SubscriptionRecord.fromJson(data);
      }
    } catch (e) {
      print('API Error [getMySubscription]: $e');
    }
    return null;
  }

  static Future<bool> subscribePlan(String token, dynamic planId) async {
    try {
      final res = await _post('/subscriptions/subscribe', token, {'plan_id': planId});
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('API Error [subscribePlan]: $e');
      return false;
    }
  }

  // Admin
  static Future<List<User>> getAdminUsers(String token) async {
    try {
      final res = await _get('/admin/users', token);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => User.fromJson(e)).toList();
      }
    } catch (e) {
      print('API Error [getAdminUsers]: $e');
    }
    return [];
  }

  static Future<List<SubscriptionRecord>> getAllSubscriptions(String token) async {
    try {
      final res = await _get('/admin/subscriptions', token);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => SubscriptionRecord.fromJson(e)).toList();
      }
    } catch (e) {
      print('API Error [getAllSubscriptions]: $e');
    }
    return [];
  }
}
