class JobPosting {
  final String id;
  final String companyId;
  final String companyName;
  final String title;
  final String description;
  final String city;
  final String? district;
  final String salary;
  final String createdAt;

  JobPosting({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
    required this.city,
    this.district,
    required this.salary,
    required this.createdAt,
  });

  factory JobPosting.fromJson(Map<String, dynamic> json) {
    return JobPosting(
      id: json['id'] ?? '',
      companyId: json['companyId'] ?? '',
      companyName: json['companyName'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      district: json['district'],
      salary: json['salary'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'title': title,
      'description': description,
      'city': city,
      'district': district,
      'salary': salary,
      'createdAt': createdAt,
    };
  }
}
