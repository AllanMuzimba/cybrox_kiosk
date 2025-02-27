class Payment {
  final int id;
  final int companyId;
  final double amount;
  final String reference;
  final String? notes;
  final DateTime paymentDate;

  Payment({
    required this.id,
    required this.companyId,
    required this.amount,
    required this.reference,
    this.notes,
    required this.paymentDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'amount': amount,
      'reference': reference,
      'notes': notes,
      'payment_date': paymentDate.toIso8601String(),
    };
  }
}