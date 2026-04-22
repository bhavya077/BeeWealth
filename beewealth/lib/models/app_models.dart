class User {
  final String email;
  final String name;
  final String role;
  final String? membershipId;
  final String? mobile;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final String? upiNumber;

  User({
    required this.email,
    required this.name,
    required this.role,
    this.membershipId,
    this.mobile,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    this.upiNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'user',
      membershipId: json['membership_id'],
      mobile: json['mobile'],
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      ifscCode: json['ifsc_code'],
      upiId: json['upi_id'],
      upiNumber: json['upi_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'membership_id': membershipId,
      'mobile': mobile,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'upi_id': upiId,
      'upi_number': upiNumber,
    };
  }
}

class DashboardData {
  final double totalInvestment;
  final double totalProfitLoss;
  final double currentValue;
  final double totalWithdrawn;

  DashboardData({
    required this.totalInvestment,
    required this.totalProfitLoss,
    required this.currentValue,
    required this.totalWithdrawn,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalInvestment: double.tryParse(json['total_investment']?.toString() ?? '0') ?? 0.0,
      totalProfitLoss: double.tryParse(json['total_profit_loss']?.toString() ?? '0') ?? 0.0,
      currentValue: double.tryParse(json['current_value']?.toString() ?? '0') ?? 0.0,
      totalWithdrawn: double.tryParse(json['total_withdrawn']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class LedgerEntry {
  final int id;
  final String date;
  final String entryType;
  final double amount;
  final double unitsDelta;
  final String description;

  LedgerEntry({
    required this.id,
    required this.date,
    required this.entryType,
    required this.amount,
    required this.unitsDelta,
    required this.description,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      entryType: json['entry_type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      unitsDelta: double.tryParse(json['units_delta']?.toString() ?? '0') ?? 0.0,
      description: json['description'] ?? '',
    );
  }
}

class PerformanceData {
  final String date;
  final double amount;
  final double perUnitChange;
  final double percentage;

  PerformanceData({
    required this.date,
    required this.amount,
    required this.perUnitChange,
    required this.percentage,
  });

  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    return PerformanceData(
      date: json['date'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      perUnitChange: double.tryParse(json['per_unit_change']?.toString() ?? '0') ?? 0.0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}
