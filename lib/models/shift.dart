class Shift {
  final String id;
  final String courierId;
  final String? companyId;
  final String? restaurantId;
  final String weekStartDate;
  final Map<String, dynamic> days; // Day name to details (e.g. {'enabled': bool, 'start': String, 'end': String})
  final String status; // 'submitted' | 'approved' | 'rejected'
  final String submittedAt;
  final String? reviewedAt;
  final String? reviewNote;
  final String createdAt;

  Shift({
    required this.id,
    required this.courierId,
    this.companyId,
    this.restaurantId,
    required this.weekStartDate,
    required this.days,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNote,
    required this.createdAt,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] ?? '',
      courierId: json['courierId'] ?? '',
      companyId: json['companyId'],
      restaurantId: json['restaurantId'],
      weekStartDate: json['weekStartDate'] ?? '',
      days: Map<String, dynamic>.from(json['days'] ?? {}),
      status: json['status'] ?? 'submitted',
      submittedAt: json['submittedAt'] ?? '',
      reviewedAt: json['reviewedAt'],
      reviewNote: json['reviewNote'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courierId': courierId,
      'companyId': companyId,
      'restaurantId': restaurantId,
      'weekStartDate': weekStartDate,
      'days': days,
      'status': status,
      'submittedAt': submittedAt,
      'reviewedAt': reviewedAt,
      'reviewNote': reviewNote,
      'createdAt': createdAt,
    };
  }
}
