class Sale {
  final int id;
  final String date;
  final double totalAmount;

  Sale({
    required this.id,
    required this.date,
    required this.totalAmount,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      date: json['date'].toString(),
      totalAmount: json['total_amount'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'total_amount': totalAmount,
    };
  }
}