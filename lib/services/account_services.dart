import 'package:cybrox_kiosk_management/models/account_entry.dart';
import 'package:cybrox_kiosk_management/models/account_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountService {
  
  final SupabaseClient _supabase;

  AccountService(this._supabase);

  // Create a new account entry for stock request
  Future<void> createStockRequestEntry(Map<String, dynamic> stockRequest) async {

    final product = await _supabase
        .from('products')
        .select()
        .eq('id', stockRequest['product_id'])
        .single();

    final totalAmount = 
        (stockRequest['quantity'] * stockRequest['sell_price']).toDouble();

    await _supabase.from('account_entries').insert({
      'company_id': stockRequest['requesting_company_id'],
      'transaction_type': 'STOCK_REQUEST',
      'amount': totalAmount,
      'transaction_date': stockRequest['order_date'],
      'reference': 'SR${stockRequest['id']}',
      'description': 'Stock request for ${product['name']} x ${stockRequest['quantity']}',
    });
  }

  // Record a payment
  Future<void> recordPayment({
    required int companyId,
    required double amount,
    required String reference,
    String? notes,
  }) async {
    await _supabase.from('account_entries').insert({
      'company_id': companyId,
      'transaction_type': 'PAYMENT',
      'amount': -amount, // Negative amount for payments
      'transaction_date': DateTime.now().toIso8601String(),
      'reference': reference,
      'description': 'Payment received${notes != null ? ': $notes' : ''}',
    });
  }

  // Get account statement for a specific company
  Future<List<AccountEntry>> getCompanyStatement(int companyId) async {
    final response = await _supabase
        .from('account_entries')
        .select()
        .eq('company_id', companyId)
        .order('transaction_date');
    
    double runningBalance = 0;
    return response.map<AccountEntry>((entry) {
      runningBalance += entry['amount'];
      entry['running_balance'] = runningBalance;
      return AccountEntry.fromJson(entry);
    }).toList();
  }

  // Get summary of all accounts
  Future<List<AccountSummary>> getAccountsSummary() async {
    final companies = await _supabase.from('company_details').select();
    List<AccountSummary> summaries = [];

    for (var company in companies) {
      final entries = await _supabase
          .from('account_entries')
          .select()
          .eq('company_id', company['id']);

      double totalDebit = 0;
      double totalCredit = 0;
      DateTime? lastTransaction;

      for (var entry in entries) {
        if (entry['amount'] > 0) {
          totalDebit += entry['amount'];
        } else {
          totalCredit += entry['amount'].abs();
        }

        final transactionDate = DateTime.parse(entry['transaction_date']);
        if (lastTransaction == null || transactionDate.isAfter(lastTransaction)) {
          lastTransaction = transactionDate;
        }
      }

      summaries.add(AccountSummary(
        companyId: company['id'],
        companyName: company['company_name'],
        totalDebit: totalDebit,
        totalCredit: totalCredit,
        balance: totalDebit - totalCredit,
        lastTransactionDate: lastTransaction ?? DateTime.now(),
      ));
    }

    return summaries;
  }
}