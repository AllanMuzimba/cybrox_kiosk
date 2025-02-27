// lib/models/tax.dart

class Tax {
  final int id;
  final String name;
  final double rate;

  Tax({
    required this.id,
    required this.name,
    required this.rate,
  });

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      id: json['id'],
      name: json['name'],
      rate: json['rate'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rate': rate,
    };
  }
}