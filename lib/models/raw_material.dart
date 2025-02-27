class RawMaterial {
  final String id;
  final String name;
  final String unit;
  final double costPerUnit;
  final double currentStock;
  final DateTime createdAt;

  RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.costPerUnit,
    required this.currentStock,
    required this.createdAt,
  });

  factory RawMaterial.fromJson(Map<String, dynamic> json) {
    return RawMaterial(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      costPerUnit: (json['cost_per_unit'] as num).toDouble(),
      currentStock: (json['current_stock'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ProductionCalculator {
  static const Map<String, Map<String, double>> conversionRates = {
    'Cattle Beef': {
      'Sausages': 0.85,
      'T-Bone': 0.4,
      'Steak': 0.6,
      'Mince': 0.75,
      'Burger Patties': 0.8,
    },
    'Goat Meat': {
      'Sausages': 0.8,
      'Steak': 0.5,
      'Mince': 0.7,
      'Curry Pieces': 0.65,
    },
    'Lamb Meat': {
      'Chops': 0.6,
      'Racks': 0.4,
      'Mince': 0.75,
      'Leg Roast': 0.5,
    },
    'Chicken': {
      'Breast Fillets': 0.7,
      'Thighs': 0.6,
      'Drumsticks': 0.65,
      'Whole Chicken': 0.9,
    },
    'Pork': {
      'Bacon': 0.6,
      'Chops': 0.55,
      'Sausages': 0.75,
      'Ribs': 0.5,
    },
  };

  static double calculateMaxProduction(
      RawMaterial material, String product) {
    final rates = conversionRates[material.name];
    if (rates == null || !rates.containsKey(product)) return 0;
    return material.currentStock * rates[product]!;
  }
}
