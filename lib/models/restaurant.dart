class Restaurant {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String managerName;
  final String managerPhone;
  final double latitude;
  final double longitude;
  final String? courierCompanyId;
  final List<String> dedicatedCourierIds;
  final bool isDedicatedMode;

  Restaurant({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.managerName,
    required this.managerPhone,
    required this.latitude,
    required this.longitude,
    this.courierCompanyId,
    required this.dedicatedCourierIds,
    required this.isDedicatedMode,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      managerName: json['managerName'] ?? '',
      managerPhone: json['managerPhone'] ?? '',
      latitude: (json['latitude'] ?? 37.2155).toDouble(),
      longitude: (json['longitude'] ?? 28.3622).toDouble(),
      courierCompanyId: json['courierCompanyId'],
      dedicatedCourierIds: List<String>.from(json['dedicatedCourierIds'] ?? []),
      isDedicatedMode: json['isDedicatedMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'latitude': latitude,
      'longitude': longitude,
      'courierCompanyId': courierCompanyId,
      'dedicatedCourierIds': dedicatedCourierIds,
      'isDedicatedMode': isDedicatedMode,
    };
  }
}
