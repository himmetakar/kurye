class ContactMessage {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String message;
  final String createdAt;

  ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.message,
    required this.createdAt,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      company: json['company'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'message': message,
      'createdAt': createdAt,
    };
  }
}
