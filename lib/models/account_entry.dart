class AccountEntry {
  final int id;
  final int companyId;
  final String transactionType; // 'STOCK_REQUEST' or 'PAYMENT'
  final double amount;
  final DateTime transactionDate;
  final String reference; // Stock request ID or Payment reference
  final String description;
  final double runningBalance;

  AccountEntry({
    required this.id,
    required this.companyId,
    required this.transactionType,
    required this.amount,
    required this.transactionDate,
    required this.reference,
    required this.description,
    required this.runningBalance,
  });

  factory AccountEntry.fromJson(Map<String, dynamic> json) {
    return AccountEntry(
      id: json['id'],
      companyId: json['company_id'],
      transactionType: json['transaction_type'],
      amount: json['amount'].toDouble(),
      transactionDate: DateTime.parse(json['transaction_date']),
      reference: json['reference'],
      description: json['description'],
      runningBalance: json['running_balance'].toDouble(),
    );
  }
}
