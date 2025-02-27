class CompanyAccount {
  final String companyName;
  final DateTime invoiceDate;
  final int? invoiceNumber;
  final int? receiptNumber;
  final double orderCost;
  final double amountPaid;
  final double balance;
  final String transactionType;

  const CompanyAccount({
    required this.companyName,
    required this.invoiceDate,
    this.invoiceNumber,
    this.receiptNumber,
    required this.orderCost,
    required this.amountPaid,
    required this.balance,
    required this.transactionType,
  });
} 