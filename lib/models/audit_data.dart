class AuditData {
  final int productId;
  final String productName;
  final int companyId;
  final String companyName;
  final DateTime requestDate;
  final DateTime? receivedDate;
  final int requestedQuantity;
  final int? receivedQuantity;
  final int currentStock;
  final int totalSales;
  final double grossIncome;
  final double purchaseCost;
  final double outstandingAmount;
  final double expectedProfit;

  AuditData({
    required this.productId,
    required this.productName,
    required this.companyId,
    required this.companyName,
    required this.requestDate,
    this.receivedDate,
    required this.requestedQuantity,
    this.receivedQuantity,
    required this.currentStock,
    required this.totalSales,
    required this.grossIncome,
    required this.purchaseCost,
    required this.outstandingAmount,
    required this.expectedProfit,
  });
} 