import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/screens/production/batch_details_screen.dart';

class BatchProductionTab extends StatefulWidget {
  BatchProductionTab({super.key}) {
    _key = GlobalKey<_BatchProductionTabState>();
  }

  late final GlobalKey<_BatchProductionTabState> _key;

  void refreshBatches() {
    _key.currentState?.refreshBatches();
  }

  @override
  State<BatchProductionTab> createState() => _BatchProductionTabState();
}

class _BatchProductionTabState extends State<BatchProductionTab> {
  final supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _batchesStream;

  @override
  void initState() {
    super.initState();
    _setupBatchesStream();
  }

  void _setupBatchesStream() {
    _batchesStream = supabase
        .from('production_batches')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((list) => List<Map<String, dynamic>>.from(list));
  }

  void refreshBatches() {
    setState(() {
      _setupBatchesStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _batchesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final batches = snapshot.data!;

        return ListView.builder(
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final batch = batches[index];
            return ListTile(
              title: Text('Batch #${batch['batch_number']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Output: ${batch['actual_output_kg']} kg'),
                  Text('Status: ${batch['status']}'),
                  if (batch['costs'] != null && (batch['costs'] as List).isNotEmpty)
                    Text('Additional Costs: \$${_calculateTotalCosts(batch['costs'])}'),
                ],
              ),
              trailing: Text('\$${batch['total_cost'] ?? 0.0}'),
              onTap: () => _viewBatchDetails(batch),
            );
          },
        );
      },
    );
  }

  void _viewBatchDetails(Map<String, dynamic> batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchDetailsScreen(batchId: batch['id']),
      ),
    );
  }

  double _calculateTotalCosts(List costs) {
    return costs.fold(0.0, (total, cost) {
      return total + (double.tryParse(cost['usd_amount']?.toString() ?? '0') ?? 0.0);
    });
  }
} 