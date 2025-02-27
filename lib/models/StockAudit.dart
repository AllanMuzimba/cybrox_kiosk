class StocksAudit {
  final int id;
  final int orderId;
  final int companyId;
  final int userId;
  final double totalCost;
  final String paymentStatus;
  final String? invoiceId;

  StocksAudit({
    required this.id,
    required this.orderId,
    required this.companyId,
    required this.userId,
    required this.totalCost,
    required this.paymentStatus,
    this.invoiceId,
  });
  

  factory StocksAudit.fromJson(Map<String, dynamic> json) {
    return StocksAudit(
      id: json['id'],
      orderId: json['order_id'],
      companyId: json['company_id'],
      userId: json['user_id'],
      totalCost: json['total_cost'].toDouble(),
      paymentStatus: json['payment_status'],
      invoiceId: json['invoice_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'company_id': companyId,
      'user_id': userId,
      'total_cost': totalCost,
      'payment_status': paymentStatus,
      'invoice_id': invoiceId,
    };
  }
}