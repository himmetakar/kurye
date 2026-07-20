class Company {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String status;
  final CompanyPricing pricing;
  final CompanyBonuses bonuses;

  Company({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.status,
    required this.pricing,
    required this.bonuses,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'active',
      pricing: CompanyPricing.fromJson(json['pricing'] ?? {}),
      bonuses: CompanyBonuses.fromJson(json['bonuses'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'status': status,
      'pricing': pricing.toJson(),
      'bonuses': bonuses.toJson(),
    };
  }
}

class CompanyPricing {
  final double firstPackageRate;
  final double secondPackageRate;
  final double thirdPackageRate;

  CompanyPricing({
    required this.firstPackageRate,
    required this.secondPackageRate,
    required this.thirdPackageRate,
  });

  factory CompanyPricing.fromJson(Map<String, dynamic> json) {
    return CompanyPricing(
      firstPackageRate: (json['firstPackageRate'] ?? 40).toDouble(),
      secondPackageRate: (json['secondPackageRate'] ?? 25).toDouble(),
      thirdPackageRate: (json['thirdPackageRate'] ?? 15).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstPackageRate': firstPackageRate,
      'secondPackageRate': secondPackageRate,
      'thirdPackageRate': thirdPackageRate,
    };
  }
}

class CompanyBonuses {
  final bool monthlyBonusActive;
  final int monthlyBonusThreshold;
  final double monthlyBonusAmount;

  CompanyBonuses({
    required this.monthlyBonusActive,
    required this.monthlyBonusThreshold,
    required this.monthlyBonusAmount,
  });

  factory CompanyBonuses.fromJson(Map<String, dynamic> json) {
    return CompanyBonuses(
      monthlyBonusActive: json['monthlyBonusActive'] ?? true,
      monthlyBonusThreshold: json['monthlyBonusThreshold'] ?? 200,
      monthlyBonusAmount: (json['monthlyBonusAmount'] ?? 1500).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthlyBonusActive': monthlyBonusActive,
      'monthlyBonusThreshold': monthlyBonusThreshold,
      'monthlyBonusAmount': monthlyBonusAmount,
    };
  }
}
