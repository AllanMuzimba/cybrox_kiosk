import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/utils/currency_converter.dart';

class CostCalculator {
  static final supabase = Supabase.instance.client;

  static Future<double> calculateProductionCost(String recipeId) async {
    final materialsResponse = await supabase
        .from('recipe_materials')
        .select('''
          *,
          raw_materials(
            cost_per_unit,
            unit
          )
        ''')
        .eq('recipe_id', recipeId);

    double totalCost = 0;
    for (final material in materialsResponse) {
      final quantity = material['quantity'] as double;
      final costPerUnit = material['raw_materials']['cost_per_unit'] as double;
      totalCost += quantity * costPerUnit;
    }

    return totalCost;
  }

  static double calculateSellingPrice({
    required double productionCost,
    required double targetProfitMargin,
    double taxRate = 0.0,
  }) {
    // Add tax to production cost
    final costWithTax = productionCost * (1 + taxRate);
    
    // Calculate price to achieve target margin
    final sellingPrice = costWithTax / (1 - targetProfitMargin);
    
    return sellingPrice;
  }

  static Future<Map<String, double>> getProductionMetrics(String batchId) async {
    final response = await supabase
        .from('production_batches')
        .select('''
          *,
          costs:additional_costs(*)
        ''')
        .eq('id', batchId)
        .single();

    final batch = response;
    final costs = List<Map<String, dynamic>>.from(batch['costs']);

    double totalCost = batch['total_cost'];
    double outputKg = batch['actual_output_kg'];
    
    return {
      'total_cost': totalCost,
      'cost_per_kg': totalCost / outputKg,
      'output_kg': outputKg,
    };
  }
} 