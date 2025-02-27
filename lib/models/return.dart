class Return {
  final int id;
  final int userId;
  final int productId;
  final int quantity;
  final String orderDate;
  final String status;
  final int companyId;

  Return({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.orderDate,
    required this.status,
    required this.companyId,
  });

  factory Return.fromJson(Map<String, dynamic> json) {
    return Return(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      orderDate: json['order_date'].toString(),
      status: json['status'],
      companyId: json['company_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'order_date': orderDate,
      'status': status,
      'company_id': companyId,
    };
  }
}