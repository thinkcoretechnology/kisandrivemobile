import 'package:flutter_test/flutter_test.dart';
import 'package:kisandrive_mobile/models/saas_models.dart';
import 'package:kisandrive_mobile/utils/date_formatter.dart';

void main() {
  group('KisanDrive Mobile Unit Tests', () {
    test('DateFormatter formats ISO date strings to dd/MM/yyyy', () {
      expect(DateFormatter.formatDDMMYYYY('2026-07-20T18:30:00.000Z'), '20/07/2026');
      expect(DateFormatter.formatDDMMYYYY('2026-09-22'), '22/09/2026');
      expect(DateFormatter.formatDDMMYYYY(null), '-');
      expect(DateFormatter.formatDDMMYYYY(''), '-');
    });

    test('Customer.fromJson safely parses String and num decimals without toDouble errors', () {
      final json = {
        'customer_id': '101',
        'user_id': '1',
        'customer_name': 'Kavi Farmer',
        'primary_phone': '9842100000',
        'village_location': 'Vadagarai',
        'opening_balance': '1500.50',
        'current_balance': '1500.50',
      };
      final customer = Customer.fromJson(json);
      expect(customer.customerId, 101);
      expect(customer.openingBalance, 1500.50);
      expect(customer.currentBalance, 1500.50);
    });

    test('WorkService.fromJson safely parses rate decimals', () {
      final json = {
        'service_id': '5',
        'user_id': '1',
        'service_name': 'Rotavator',
        'billing_unit': 'Hours',
        'default_rate': '900.00',
      };
      final service = WorkService.fromJson(json);
      expect(service.serviceId, 5);
      expect(service.defaultRate, 900.00);
    });

    test('SubscriptionRecord.fromJson parses string/num amounts without errors', () {
      final json = {
        'subscription_id': '20',
        'user_id': '1',
        'user_name': 'Test User',
        'mobile_number': '9842100000',
        'plan_name': '1 Month Plan',
        'start_date': '2026-09-20 12:00:00',
        'end_date': '2026-10-20 12:00:00',
        'original_amount': '999.00',
        'discount_amount': '0.00',
        'subscription_amount': '999.00',
        'status': 'Active',
      };
      final sub = SubscriptionRecord.fromJson(json);
      expect(sub.subscriptionId, 20);
      expect(sub.subscriptionAmount, 999.00);
      expect(sub.status, 'Active');
    });
  });
}
