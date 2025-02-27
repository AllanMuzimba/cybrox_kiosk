class AccountSummary {
  final int companyId;
  final String companyName;
  final double totalDebit;
  final double totalCredit;
  final double balance;
  final DateTime lastTransactionDate;

  AccountSummary({
    required this.companyId,
    required this.companyName,
    required this.totalDebit,
    required this.totalCredit,
    required this.balance,
    required this.lastTransactionDate,
  });
}