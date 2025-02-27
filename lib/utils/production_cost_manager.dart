import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/utils/currency_converter.dart';
import 'package:cybrox_kiosk_management/utils/cost_calculator.dart';

class ProductionCostManager {
  static final supabase = Supabase.instance.client;

  static Future<Map<String, double>> calculateBatchCosts({
    required String recipeId,
    required double outputKg,
    required List<Map<String, dynamic>> additionalCosts,
  }) async {
    // Get base production cost
    final baseCost = await CostCalculator.calculateProductionCost(recipeId);
    
    // Convert and sum additional costs
    double totalAdditionalCosts = 0;
    for (final cost in additionalCosts) {
      final amount = double.parse(cost['amount'].toString());
      final usdAmount = CurrencyConverter.convert(
        amount,
        cost['currency'],
        'USD'
      );
      totalAdditionalCosts += usdAmount;
    }

    final totalCost = baseCost + totalAdditionalCosts;
    final costPerKg = totalCost / outputKg;

    return {
      'base_cost': baseCost,
      'additional_costs': totalAdditionalCosts,
      'total_cost': totalCost,
      'cost_per_kg': costPerKg,
    };
  }

  static Future<double> suggestSellingPrice({
    required String recipeId,
    required double outputKg,
    required List<Map<String, dynamic>> additionalCosts,
    required double targetProfitMargin,
    double taxRate = 0.0,
  }) async {
    final costs = await calculateBatchCosts(
      recipeId: recipeId,
      outputKg: outputKg,
      additionalCosts: additionalCosts,
    );

    return CostCalculator.calculateSellingPrice(
      productionCost: costs['cost_per_kg']!,
      targetProfitMargin: targetProfitMargin,
      taxRate: taxRate,
    );
  }
} 