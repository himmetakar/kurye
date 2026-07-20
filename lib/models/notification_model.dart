class NotificationModel {
  final String id;
  final String type;
  final String targetRole; // 'firma' | 'restoran' | 'kurye' | 'superadmin'
  final String? targetId;
  final String? courierId;
  final String? courierName;
  final String? shiftId;
  final String? weekStartDate;
  final String? orderId;
  final String? message;
  final bool read;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.targetRole,
    this.targetId,
    this.courierId,
    this.courierName,
    this.shiftId,
    this.weekStartDate,
    this.orderId,
    this.message,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      targetRole: json['targetRole'] ?? '',
      targetId: json['targetId'],
      courierId: json['courierId'],
      courierName: json['courierName'],
      shiftId: json['shiftId'],
      weekStartDate: json['weekStartDate'],
      orderId: json['orderId'],
      message: json['message'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'targetRole': targetRole,
      'targetId': targetId,
      'courierId': courierId,
      'courierName': courierName,
      'shiftId': shiftId,
      'weekStartDate': weekStartDate,
      'orderId': orderId,
      'message': message,
      'read': read,
      'createdAt': createdAt,
    };
  }
}
