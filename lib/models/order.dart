class OrderModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String customerName;
  final String deliveryAddress;
  final String phone;
  final double price;
  final String? assignedCourierId;
  final String status; // 'araniyor' | 'kabul_edildi' | 'teslim_alindi' | 'tasimada' | 'teslim_edildi' | 'iptal'
  final String createdAt;
  final String? assignedAt;
  final String? pickedUpAt;
  final String? deliveredAt;
  final double latitude;
  final double longitude;
  final bool isDelayed;
  final String? delayReason;
  final bool acknowledged;
  final int? rating;
  final String? ratingComment;
  final bool poolOrder;
  final String? poolAcceptedByCompanyId;
  final bool reportedNotReceived;
  final String? reportedNotReceivedAt;

  OrderModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.customerName,
    required this.deliveryAddress,
    required this.phone,
    required this.price,
    this.assignedCourierId,
    required this.status,
    required this.createdAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.latitude,
    required this.longitude,
    required this.isDelayed,
    this.delayReason,
    required this.acknowledged,
    this.rating,
    this.ratingComment,
    required this.poolOrder,
    this.poolAcceptedByCompanyId,
    required this.reportedNotReceived,
    this.reportedNotReceivedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      customerName: json['customerName'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      phone: json['phone'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      assignedCourierId: json['assignedCourierId'],
      status: json['status'] ?? 'araniyor',
      createdAt: json['createdAt'] ?? '',
      assignedAt: json['assignedAt'],
      pickedUpAt: json['pickedUpAt'],
      deliveredAt: json['deliveredAt'],
      latitude: (json['latitude'] ?? 37.2155).toDouble(),
      longitude: (json['longitude'] ?? 28.3622).toDouble(),
      isDelayed: json['isDelayed'] ?? false,
      delayReason: json['delayReason'],
      acknowledged: json['acknowledged'] ?? false,
      rating: json['rating'],
      ratingComment: json['ratingComment'],
      poolOrder: json['poolOrder'] ?? false,
      poolAcceptedByCompanyId: json['poolAcceptedByCompanyId'],
      reportedNotReceived: json['reportedNotReceived'] ?? false,
      reportedNotReceivedAt: json['reportedNotReceivedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'customerName': customerName,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
      'price': price,
      'assignedCourierId': assignedCourierId,
      'status': status,
      'createdAt': createdAt,
      'assignedAt': assignedAt,
      'pickedUpAt': pickedUpAt,
      'deliveredAt': deliveredAt,
      'latitude': latitude,
      'longitude': longitude,
      'isDelayed': isDelayed,
      'delayReason': delayReason,
      'acknowledged': acknowledged,
      'rating': rating,
      'ratingComment': ratingComment,
      'poolOrder': poolOrder,
      'poolAcceptedByCompanyId': poolAcceptedByCompanyId,
      'reportedNotReceived': reportedNotReceived,
      'reportedNotReceivedAt': reportedNotReceivedAt,
    };
  }
}
