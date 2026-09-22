class User {
  final int userId;
  final String fullName;
  final String mobileNumber;
  final String role;
  final String status;
  final String gender;
  final String address;
  final String state;
  final String pincode;
  final String aadharCard;
  final String profileImage;
  final int? tractorCount;
  final int? customerCount;
  final String? currentPlan;
  final String? planEndDate;

  User({
    required this.userId,
    required this.fullName,
    required this.mobileNumber,
    required this.role,
    required this.status,
    required this.gender,
    required this.address,
    required this.state,
    required this.pincode,
    required this.aadharCard,
    required this.profileImage,
    this.tractorCount,
    this.customerCount,
    this.currentPlan,
    this.planEndDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] != null ? (int.tryParse(json['user_id'].toString()) ?? 0) : 0,
      fullName: json['full_name']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Tractor Owner',
      status: json['status']?.toString() ?? 'Active',
      gender: json['gender']?.toString() ?? 'Male',
      address: json['address']?.toString() ?? '',
      state: json['state']?.toString() ?? 'Tamil Nadu',
      pincode: json['pincode']?.toString() ?? '',
      aadharCard: json['aadhar_card']?.toString() ?? '',
      profileImage: json['profile_image']?.toString() ?? '',
      tractorCount: json['tractor_count'] != null ? int.tryParse(json['tractor_count'].toString()) : null,
      customerCount: json['customer_count'] != null ? int.tryParse(json['customer_count'].toString()) : null,
      currentPlan: json['current_plan']?.toString() ?? json['plan_name']?.toString(),
      planEndDate: json['plan_end_date']?.toString() ?? json['end_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'role': role,
      'status': status,
      'gender': gender,
      'address': address,
      'state': state,
      'pincode': pincode,
      'aadhar_card': aadharCard,
      'profile_image': profileImage,
      'tractor_count': tractorCount,
      'customer_count': customerCount,
      'current_plan': currentPlan,
      'plan_end_date': planEndDate,
    };
  }
}

class Tractor {
  final int tractorId;
  final int userId;
  final String tractorName;
  final String brand;
  final String registrationNumber;
  final String modelName;
  final int manufacturingYear;
  final int hp;
  final String purchaseDate;
  final String fuelType;
  final String insuranceDetails;
  final String currentStatus;

  Tractor({
    required this.tractorId,
    required this.userId,
    required this.tractorName,
    required this.brand,
    required this.registrationNumber,
    required this.modelName,
    required this.manufacturingYear,
    required this.hp,
    required this.purchaseDate,
    required this.fuelType,
    required this.insuranceDetails,
    required this.currentStatus,
  });

  factory Tractor.fromJson(Map<String, dynamic> json) {
    return Tractor(
      tractorId: json['tractor_id'] != null ? (int.tryParse(json['tractor_id'].toString()) ?? 0) : 0,
      userId: json['user_id'] != null ? (int.tryParse(json['user_id'].toString()) ?? 0) : 0,
      tractorName: json['tractor_name']?.toString() ?? json['model_name']?.toString().split(' ')[0] ?? 'Mahindra',
      brand: json['brand']?.toString() ?? 'Mahindra',
      registrationNumber: json['registration_number']?.toString() ?? '',
      modelName: json['model_name']?.toString() ?? '',
      manufacturingYear: json['manufacturing_year'] != null ? (int.tryParse(json['manufacturing_year'].toString()) ?? 2023) : 2023,
      hp: json['hp'] != null ? (int.tryParse(json['hp'].toString()) ?? 45) : 45,
      purchaseDate: json['purchase_date']?.toString() ?? '2023-01-01',
      fuelType: json['fuel_type']?.toString() ?? 'Diesel',
      insuranceDetails: json['insurance_details']?.toString() ?? 'Active Insurance',
      currentStatus: json['current_status']?.toString() ?? 'Active',
    );
  }
}

class Customer {
  final int customerId;
  final int userId;
  final String customerName;
  final String primaryPhone;
  final String villageLocation;
  final String gender;
  final String pincode;
  final String status;
  final double openingBalance;
  final double currentBalance;

  Customer({
    required this.customerId,
    required this.userId,
    required this.customerName,
    required this.primaryPhone,
    required this.villageLocation,
    required this.gender,
    required this.pincode,
    required this.status,
    required this.openingBalance,
    required this.currentBalance,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id'] != null ? (int.tryParse(json['customer_id'].toString()) ?? 0) : 0,
      userId: json['user_id'] != null ? (int.tryParse(json['user_id'].toString()) ?? 0) : 0,
      customerName: json['customer_name']?.toString() ?? '',
      primaryPhone: json['primary_phone']?.toString() ?? '',
      villageLocation: json['village_location']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'Male',
      pincode: json['pincode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      openingBalance: double.tryParse(json['opening_balance']?.toString() ?? '0') ?? 0.0,
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? json['opening_balance']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class WorkService {
  final int serviceId;
  final int userId;
  final String serviceName;
  final String billingUnit;
  final double defaultRate;

  WorkService({
    required this.serviceId,
    required this.userId,
    required this.serviceName,
    required this.billingUnit,
    required this.defaultRate,
  });

  factory WorkService.fromJson(Map<String, dynamic> json) {
    return WorkService(
      serviceId: json['service_id'] != null ? (int.tryParse(json['service_id'].toString()) ?? 0) : 0,
      userId: json['user_id'] != null ? (int.tryParse(json['user_id'].toString()) ?? 0) : 0,
      serviceName: json['service_name']?.toString() ?? '',
      billingUnit: json['billing_unit']?.toString() ?? 'Hours',
      defaultRate: double.tryParse(json['default_rate']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class FieldWorkEntry {
  final int? workEntryId;
  final int? userId;
  final String entryDate;
  final int tractorId;
  final int customerId;
  final int serviceId;
  final int? operatorId;
  final double actualHours;
  final int loadCount;
  final double rateApplied;
  final double totalAmount;
  final double manualAdjustment;
  final String adjustmentRemarks;
  final double netPayable;

  final String? tractorRegistration;
  final String? tractorModel;
  final String? customerName;
  final String? customerPhone;
  final String? villageLocation;
  final String? serviceName;
  final String? billingUnit;

  FieldWorkEntry({
    this.workEntryId,
    this.userId,
    required this.entryDate,
    required this.tractorId,
    required this.customerId,
    required this.serviceId,
    this.operatorId,
    required this.actualHours,
    required this.loadCount,
    required this.rateApplied,
    required this.totalAmount,
    required this.manualAdjustment,
    required this.adjustmentRemarks,
    required this.netPayable,
    this.tractorRegistration,
    this.tractorModel,
    this.customerName,
    this.customerPhone,
    this.villageLocation,
    this.serviceName,
    this.billingUnit,
  });

  factory FieldWorkEntry.fromJson(Map<String, dynamic> json) {
    return FieldWorkEntry(
      workEntryId: json['work_entry_id'] != null ? int.tryParse(json['work_entry_id'].toString()) : null,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      entryDate: json['entry_date']?.toString() ?? '',
      tractorId: json['tractor_id'] != null ? (int.tryParse(json['tractor_id'].toString()) ?? 0) : 0,
      customerId: json['customer_id'] != null ? (int.tryParse(json['customer_id'].toString()) ?? 0) : 0,
      serviceId: json['service_id'] != null ? (int.tryParse(json['service_id'].toString()) ?? 0) : 0,
      operatorId: json['operator_id'] != null ? int.tryParse(json['operator_id'].toString()) : null,
      actualHours: double.tryParse(json['actual_hours']?.toString() ?? '0') ?? 0.0,
      loadCount: json['load_count'] != null ? (int.tryParse(json['load_count'].toString()) ?? 0) : 0,
      rateApplied: double.tryParse(json['rate_applied']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      manualAdjustment: double.tryParse(json['one_time_manual_billing_time_adjustment']?.toString() ?? '0') ?? 0.0,
      adjustmentRemarks: json['adjustment_remarks']?.toString() ?? '',
      netPayable: double.tryParse(json['net_payable']?.toString() ?? '0') ?? 0.0,
      tractorRegistration: json['tractor_registration']?.toString(),
      tractorModel: json['tractor_model']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      villageLocation: json['village_location']?.toString(),
      serviceName: json['service_name']?.toString(),
      billingUnit: json['billing_unit']?.toString(),
    );
  }
}

class CustomerPayment {
  final int? paymentId;
  final int? userId;
  final int customerId;
  final String paymentDate;
  final double amountPaid;
  final String paymentMode;
  final String? referenceNumber;
  final double balanceAfterPayment;
  final String? customerName;

  CustomerPayment({
    this.paymentId,
    this.userId,
    required this.customerId,
    required this.paymentDate,
    required this.amountPaid,
    required this.paymentMode,
    this.referenceNumber,
    required this.balanceAfterPayment,
    this.customerName,
  });

  factory CustomerPayment.fromJson(Map<String, dynamic> json) {
    return CustomerPayment(
      paymentId: json['payment_id'] != null ? int.tryParse(json['payment_id'].toString()) : null,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      customerId: json['customer_id'] != null ? (int.tryParse(json['customer_id'].toString()) ?? 0) : 0,
      paymentDate: json['payment_date']?.toString() ?? '',
      amountPaid: double.tryParse(json['amount_paid']?.toString() ?? '0') ?? 0.0,
      paymentMode: json['payment_mode']?.toString() ?? 'Cash',
      referenceNumber: json['reference_number']?.toString(),
      balanceAfterPayment: double.tryParse(json['balance_after_payment']?.toString() ?? '0') ?? 0.0,
      customerName: json['customer_name']?.toString(),
    );
  }
}

class Expense {
  final int? expenseId;
  final int? userId;
  final int? tractorId;
  final String expenseCategory;
  final double amount;
  final String expenseDate;
  final String? notesOrBillNumber;
  final String? tractorRegistration;

  Expense({
    this.expenseId,
    this.userId,
    this.tractorId,
    required this.expenseCategory,
    required this.amount,
    required this.expenseDate,
    this.notesOrBillNumber,
    this.tractorRegistration,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expense_id'] != null ? int.tryParse(json['expense_id'].toString()) : null,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      tractorId: json['tractor_id'] != null ? int.tryParse(json['tractor_id'].toString()) : null,
      expenseCategory: json['expense_category']?.toString() ?? 'Diesel',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      expenseDate: json['expense_date']?.toString() ?? '',
      notesOrBillNumber: json['notes_or_bill_number']?.toString(),
      tractorRegistration: json['tractor_registration']?.toString(),
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final int days;
  final double originalPrice;
  final double discountPercentage;
  final double finalPrice;
  final String description;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.days,
    required this.originalPrice,
    required this.discountPercentage,
    required this.finalPrice,
    required this.description,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      days: json['days'] != null ? (int.tryParse(json['days'].toString()) ?? 0) : 0,
      originalPrice: double.tryParse(json['originalPrice']?.toString() ?? json['original_price']?.toString() ?? '0') ?? 0.0,
      discountPercentage: double.tryParse(json['discountPercentage']?.toString() ?? json['discount_percentage']?.toString() ?? '0') ?? 0.0,
      finalPrice: double.tryParse(json['finalPrice']?.toString() ?? json['final_price']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
    );
  }
}

class SubscriptionRecord {
  final int subscriptionId;
  final int userId;
  final String userName;
  final String mobileNumber;
  final String planName;
  final String startDate;
  final String endDate;
  final double originalAmount;
  final double discountAmount;
  final double subscriptionAmount;
  final String status;

  SubscriptionRecord({
    required this.subscriptionId,
    required this.userId,
    required this.userName,
    required this.mobileNumber,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.originalAmount,
    required this.discountAmount,
    required this.subscriptionAmount,
    required this.status,
  });

  factory SubscriptionRecord.fromJson(Map<String, dynamic> json) {
    return SubscriptionRecord(
      subscriptionId: json['subscription_id'] != null ? (int.tryParse(json['subscription_id'].toString()) ?? 0) : 0,
      userId: json['user_id'] != null ? (int.tryParse(json['user_id'].toString()) ?? 0) : 0,
      userName: json['user_name']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? json['name']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      originalAmount: double.tryParse(json['original_amount']?.toString() ?? json['originalPrice']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      subscriptionAmount: double.tryParse(json['subscription_amount']?.toString() ?? json['finalPrice']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'Active',
    );
  }
}

class DashboardKPIs {
  final int activeTractors;
  final int totalCustomers;
  final int totalFieldJobs;
  final double totalRevenueBilled;
  final double totalCollections;
  final double totalOutstandingDues;
  final double totalExpenses;
  final double netProfit;

  DashboardKPIs({
    required this.activeTractors,
    required this.totalCustomers,
    required this.totalFieldJobs,
    required this.totalRevenueBilled,
    required this.totalCollections,
    required this.totalOutstandingDues,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory DashboardKPIs.fromJson(Map<String, dynamic> json) {
    return DashboardKPIs(
      activeTractors: json['active_tractors'] != null ? (int.tryParse(json['active_tractors'].toString()) ?? 0) : 0,
      totalCustomers: json['total_customers'] != null ? (int.tryParse(json['total_customers'].toString()) ?? 0) : 0,
      totalFieldJobs: json['total_field_jobs'] != null ? (int.tryParse(json['total_field_jobs'].toString()) ?? 0) : 0,
      totalRevenueBilled: double.tryParse(json['total_revenue_billed']?.toString() ?? '0') ?? 0.0,
      totalCollections: double.tryParse(json['total_collections']?.toString() ?? '0') ?? 0.0,
      totalOutstandingDues: double.tryParse(json['total_outstanding_dues']?.toString() ?? '0') ?? 0.0,
      totalExpenses: double.tryParse(json['total_expenses']?.toString() ?? '0') ?? 0.0,
      netProfit: double.tryParse(json['net_profit']?.toString() ?? '0') ?? 0.0,
    );
  }
}
