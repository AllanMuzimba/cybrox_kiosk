class Company {
  final int id;
  final String name;
  final String address;
  final String contactPhone;
  final String email;
  final String tin;
  final bool isHq;

  Company({
    required this.id,
    required this.name,
    required this.address,
    required this.contactPhone,
    required this.email,
    required this.tin,
    required this.isHq,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'],
        name: json['company_name'],
        address: json['address'],
        contactPhone: json['contact_phone'],
        email: json['email'],
        tin: json['tin'],
        isHq: json['is_hq'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'company_name': name,
        'address': address,
        'contact_phone': contactPhone,
        'email': email,
        'tin': tin,
        'is_hq': isHq,
      };
}