class Faculty {
  final String name;
  final String department;
  final String phone;
  double rating; // Mutable field

  Faculty({
    required this.name,
    required this.department,
    required this.phone,
    this.rating = 0.0,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      name: json['name'] ?? '',
      department: json['department'] ?? '',
      phone: json['phone'].toString(),
    );
  }
}
