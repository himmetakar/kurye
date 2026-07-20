class CourierRequest {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String type; // 'daimi' | 'gecici'
  final String durationDetails;
  final String motorcycleRequired; // 'yes' | 'no'
  final int count;
  final String description;
  final String status; // 'pending' | 'published_as_job' | 'assigned_to_company' | 'completed'
  final String? assignedCompanyId;
  final String? assignedCompanyName;
  final String? assignedCourierId;
  final String? assignedCourierName;
  final String createdAt;

  CourierRequest({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.type,
    required this.durationDetails,
    required this.motorcycleRequired,
    required this.count,
    required this.description,
    required this.status,
    this.assignedCompanyId,
    this.assignedCompanyName,
    this.assignedCourierId,
    this.assignedCourierName,
    required this.createdAt,
  });

  factory CourierRequest.fromJson(Map<String, dynamic> json) {
    return CourierRequest(
      id: json['id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      type: json['type'] ?? 'daimi',
      durationDetails: json['durationDetails'] ?? '',
      motorcycleRequired: json['motorcycleRequired'] ?? 'yes',
      count: json['count'] ?? 1,
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      assignedCompanyId: json['assignedCompanyId'],
      assignedCompanyName: json['assignedCompanyName'],
      assignedCourierId: json['assignedCourierId'],
      assignedCourierName: json['assignedCourierName'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'type': type,
      'durationDetails': durationDetails,
      'motorcycleRequired': motorcycleRequired,
      'count': count,
      'description': description,
      'status': status,
      'assignedCompanyId': assignedCompanyId,
      'assignedCompanyName': assignedCompanyName,
      'assignedCourierId': assignedCourierId,
      'assignedCourierName': assignedCourierName,
      'createdAt': createdAt,
    };
  }
}
