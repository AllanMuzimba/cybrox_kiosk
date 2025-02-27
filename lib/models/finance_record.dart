class FinanceRecord {
  final int? id;
  final int companyId;
  final int? userId;
  final double amount;
  final DateTime createdAt;
  final String type;   // 'payment' or 'order'

  FinanceRecord({
    this.id,
    required this.companyId,
    this.userId,
    required this.amount,
    required this.createdAt,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'user_id': userId,
    'amount': amount,
    'created_at': createdAt.toIso8601String(),
    'type': type,
  };

  factory FinanceRecord.fromJson(Map<String, dynamic> json) {
    return FinanceRecord(
      id: json['id'],
      companyId: json['company_id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'],
    );
  }
}
