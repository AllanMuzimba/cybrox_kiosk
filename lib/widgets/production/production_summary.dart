import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/utils/cost_calculator.dart';

class ProductionSummary extends StatelessWidget {
  final String batchId;

  const ProductionSummary({
    Key? key,
    required this.batchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: CostCalculator.getProductionMetrics(batchId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final metrics = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Production Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildMetricRow('Total Cost', '\$${metrics['total_cost']?.toStringAsFixed(2)}'),
                _buildMetricRow('Cost per KG', '\$${metrics['cost_per_kg']?.toStringAsFixed(2)}'),
                _buildMetricRow('Output', '${metrics['output_kg']?.toStringAsFixed(2)} kg'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
} 