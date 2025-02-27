import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyFinanceHeader extends StatelessWidget {
  final int companyId;
  final SupabaseClient supabase;

  const CompanyFinanceHeader({
    Key? key,
    required this.companyId,
    required this.supabase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadCompanyFinances(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox();
        }

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final data = snapshot.data!;
        final balance = data['balance'] ?? 0.0;
        final totalOrders = data['total_orders'] ?? 0.0;
        final owing = totalOrders - balance;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Company',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Total Orders', totalOrders),
                    _buildInfoColumn('Balance', balance),
                    _buildInfoColumn(
                      'Outstanding',
                      owing,
                      color: owing > 0 ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(String label, double amount, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _loadCompanyFinances() async {
    final response = await supabase
        .from('companies')
        .select('''
          *,
          balance:finance(amount),
          total_orders:orders(sum)
        ''')
        .eq('id', companyId)
        .single();

    return response;
  }
} 