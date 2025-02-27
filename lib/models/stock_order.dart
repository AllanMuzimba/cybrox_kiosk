// lib/models/stock_order.dart
import 'package:cybrox_kiosk_management/models/invoice.dart';

class StockOrder {
  final int id;
  final int userId;
  final int requestingCompanyId;
  final int fulfillingCompanyId;
  final int productId;
  final int quantity;
  final double cost;
  final double sellPrice;
  final String status;
  final String orderDate;

  StockOrder({
    required this.id,
    required this.userId,
    required this.requestingCompanyId,
    required this.fulfillingCompanyId,
    required this.productId,
    required this.quantity,
    required this.cost,
    required this.sellPrice,
    required this.status,
    required this.orderDate,
  });

  factory StockOrder.fromJson(Map<String, dynamic> json) {
    return StockOrder(
      id: json['id'],
      userId: json['user_id'],
      requestingCompanyId: json['requesting_company_id'],
      fulfillingCompanyId: json['fulfilling_company_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      cost: double.parse(json['cost'].toString()),
      sellPrice: double.parse(json['sell_price'].toString()),
      status: json['status'],
      orderDate: json['order_date'],
    );
  }

  get notes => Invoice;

  get orderId => id;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'order_date': orderDate,
      'status': status,
      'requesting_company_id': requestingCompanyId,
      'fulfilling_company_id': fulfillingCompanyId,
      'cost': cost,
      'sell_price': sellPrice,
    };
  }
}
