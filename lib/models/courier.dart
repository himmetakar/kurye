class Courier {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? courierCompanyId;
  final String? assignedRestaurantId;
  final String status; // 'musait' | 'aktif' | 'pasif' | 'araniyor' | 'kabul_edildi' | 'tasimada'
  final int queuePosition;
  final int deliveriesCount;
  final int penaltiesCount;
  final double latitude;
  final double longitude;
  final bool isAtRestaurant;
  final String? arrivedAtRestaurantAt;
  final double earningsWallet;
  final List<EarningsLogEntry> earningsLog;
  final double rating;
  final int avgDeliveryTimeMinutes;
  final int performanceScore;
  final int assignedOrdersCount;
  final int acceptedOrdersCount;
  final int acceptanceRate;
  final int weeklyAcceptanceRate;
  final int dailyCancellationsCount;
  final String? lastDeactivatedAt;
  final bool isShadowBanned;
  final int dailyViolationCount;
  final String? lastViolationDate;
  final String? shadowBannedAt;
  final String? lastAssignedOrderId;
  final String? lastAssignedAt;
  final String? iban;
  final String? pendingCompanyId;

  Courier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.courierCompanyId,
    this.assignedRestaurantId,
    required this.status,
    required this.queuePosition,
    required this.deliveriesCount,
    required this.penaltiesCount,
    required this.latitude,
    required this.longitude,
    required this.isAtRestaurant,
    this.arrivedAtRestaurantAt,
    required this.earningsWallet,
    required this.earningsLog,
    required this.rating,
    required this.avgDeliveryTimeMinutes,
    required this.performanceScore,
    required this.assignedOrdersCount,
    required this.acceptedOrdersCount,
    required this.acceptanceRate,
    required this.weeklyAcceptanceRate,
    required this.dailyCancellationsCount,
    this.lastDeactivatedAt,
    required this.isShadowBanned,
    required this.dailyViolationCount,
    this.lastViolationDate,
    this.shadowBannedAt,
    this.lastAssignedOrderId,
    this.lastAssignedAt,
    this.iban,
    this.pendingCompanyId,
  });

  factory Courier.fromJson(Map<String, dynamic> json) {
    var rawLogs = json['earningsLog'] as List?;
    List<EarningsLogEntry> logsList = rawLogs != null 
        ? rawLogs.map((i) => EarningsLogEntry.fromJson(i)).toList()
        : [];

    return Courier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      courierCompanyId: json['courierCompanyId'],
      assignedRestaurantId: json['assignedRestaurantId'],
      status: json['status'] ?? 'musait',
      queuePosition: (json['queuePosition'] ?? 0).toInt(),
      deliveriesCount: (json['deliveriesCount'] ?? 0).toInt(),
      penaltiesCount: (json['penaltiesCount'] ?? 0).toInt(),
      latitude: (json['latitude'] ?? 37.2155).toDouble(),
      longitude: (json['longitude'] ?? 28.3622).toDouble(),
      isAtRestaurant: json['isAtRestaurant'] ?? false,
      arrivedAtRestaurantAt: json['arrivedAtRestaurantAt'],
      earningsWallet: (json['earningsWallet'] ?? 0).toDouble(),
      earningsLog: logsList,
      rating: (json['rating'] ?? 5.0).toDouble(),
      avgDeliveryTimeMinutes: (json['avgDeliveryTimeMinutes'] ?? 20).toInt(),
      performanceScore: (json['performanceScore'] ?? 100).toInt(),
      assignedOrdersCount: (json['assignedOrdersCount'] ?? 0).toInt(),
      acceptedOrdersCount: (json['acceptedOrdersCount'] ?? 0).toInt(),
      acceptanceRate: (json['acceptanceRate'] ?? 100).toInt(),
      weeklyAcceptanceRate: (json['weeklyAcceptanceRate'] ?? 100).toInt(),
      dailyCancellationsCount: (json['dailyCancellationsCount'] ?? 0).toInt(),
      lastDeactivatedAt: json['lastDeactivatedAt'],
      isShadowBanned: json['isShadowBanned'] ?? false,
      dailyViolationCount: (json['dailyViolationCount'] ?? 0).toInt(),
      lastViolationDate: json['lastViolationDate'],
      shadowBannedAt: json['shadowBannedAt'],
      lastAssignedOrderId: json['lastAssignedOrderId'],
      lastAssignedAt: json['lastAssignedAt'],
      iban: json['iban'],
      pendingCompanyId: json['pendingCompanyId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'courierCompanyId': courierCompanyId,
      'assignedRestaurantId': assignedRestaurantId,
      'status': status,
      'queuePosition': queuePosition,
      'deliveriesCount': deliveriesCount,
      'penaltiesCount': penaltiesCount,
      'latitude': latitude,
      'longitude': longitude,
      'isAtRestaurant': isAtRestaurant,
      'arrivedAtRestaurantAt': arrivedAtRestaurantAt,
      'earningsWallet': earningsWallet,
      'earningsLog': earningsLog.map((e) => e.toJson()).toList(),
      'rating': rating,
      'avgDeliveryTimeMinutes': avgDeliveryTimeMinutes,
      'performanceScore': performanceScore,
      'assignedOrdersCount': assignedOrdersCount,
      'acceptedOrdersCount': acceptedOrdersCount,
      'acceptanceRate': acceptanceRate,
      'weeklyAcceptanceRate': weeklyAcceptanceRate,
      'dailyCancellationsCount': dailyCancellationsCount,
      'lastDeactivatedAt': lastDeactivatedAt,
      'isShadowBanned': isShadowBanned,
      'dailyViolationCount': dailyViolationCount,
      'lastViolationDate': lastViolationDate,
      'shadowBannedAt': shadowBannedAt,
      'lastAssignedOrderId': lastAssignedOrderId,
      'lastAssignedAt': lastAssignedAt,
      'iban': iban,
      'pendingCompanyId': pendingCompanyId,
    };
  }
}

class EarningsLogEntry {
  final String orderId;
  final double amount;
  final String type; // 'paket' | 'prim' | 'ceza' | 'odeme'
  final String timestamp;
  final String note;

  EarningsLogEntry({
    required this.orderId,
    required this.amount,
    required this.type,
    required this.timestamp,
    required this.note,
  });

  factory EarningsLogEntry.fromJson(Map<String, dynamic> json) {
    return EarningsLogEntry(
      orderId: json['orderId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'paket',
      timestamp: json['timestamp'] ?? '',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'type': type,
      'timestamp': timestamp,
      'note': note,
    };
  }
}
