import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/utils/currency_converter.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';

class BatchDetailsScreen extends StatefulWidget {
  final String batchId;
  
  const BatchDetailsScreen({Key? key, required this.batchId}) : super(key: key);

  @override
  _BatchDetailsScreenState createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  final supabase = Supabase.instance.client;
  final _profitMarginController = TextEditingController(text: '30');
  final _sellingPriceController = TextEditingController();
  bool _isCustomPrice = false;
  
  final List<double> _suggestedMargins = [20, 30, 40, 50, 60];
  List<Map<String, dynamic>> _recipeMaterials = [];
  double _totalCost = 0;
  User? get currentUser => supabase.auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadBatchDetails(),
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final batch = snapshot.data!;
          final materialsCost = _calculateTotalIngredientCost(batch);
          final additionalCost = _calculateAdditionalCosts(batch);
          final totalCost = materialsCost + additionalCost;
          final outputKg = (batch['actual_output_kg'] ?? 0).toDouble();
          final costPerKg = outputKg > 0 ? totalCost / outputKg : 0.0;
          final isFinished = batch['status'] == 'finished';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBatchHeader(batch),
                _buildStatusSection(batch),
                _buildIngredientCosts(batch),
                _buildCostSection(batch, costPerKg),
                _buildPricingCalculator(costPerKg, outputKg),
                _buildAdditionalCosts(batch['costs'] ?? []),
                if (batch['status'] == 'in_progress')
                  _buildFinishBatchButton(batch),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBatchHeader(Map<String, dynamic> batch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Batch #${batch['batch_number']}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatusSection(Map<String, dynamic> batch) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCurrentUserProfile(),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        final displayName = userProfile?['full_name'] ?? currentUser?.email ?? 'Unknown user';
        
        return Card(
          child: Column(
            children: [
              if (batch['status'] == 'finished')
                Container(
                  color: Colors.green.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 32),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PRODUCTION COMPLETED',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text('Transferred by $displayName',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ListTile(
                title: const Text('Status'),
                subtitle: Text(batch['status']?.toUpperCase() ?? 'IN PROGRESS'),
                trailing: _getStatusIcon(batch['status']),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCostSection(Map<String, dynamic> batch, double costPerKg) {
    final outputKg = batch['actual_output_kg'] ?? 0.0;
    final materialsCost = _calculateTotalIngredientCost(batch);
    final additionalCost = _calculateAdditionalCosts(batch);
    final totalCost = materialsCost + additionalCost;

    print('Materials Cost: $materialsCost'); // Debug print
    print('Additional Cost: $additionalCost'); // Debug print
    print('Total Cost: $totalCost'); // Debug print

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Production Costs Breakdown',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            // Materials Cost
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Raw Materials Cost:'),
                Text('\$${materialsCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            
            // Additional Costs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Additional Costs:'),
                Text('\$${additionalCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            
            // Total Cost
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Production Cost:'),
                Text('\$${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            
            // Cost per KG
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cost per KG:'),
                Text('\$${costPerKg.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    )),
              ],
            ),
            
            // Output
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Output:'),
                Text('${outputKg.toStringAsFixed(2)} KG',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateRecipeMaterialsCost(List<dynamic> recipeMaterials) {
    try {
      print('Calculating recipe materials cost...'); // Debug print
      return recipeMaterials.fold(0.0, (total, material) {
        final rawMaterial = material['raw_materials'];
        final quantity = double.parse(material['quantity'].toString());
        final costPerUnit = double.parse(rawMaterial['cost_per_unit'].toString());
        final materialCost = quantity * costPerUnit;
        print('Material: ${rawMaterial['name']}, Cost: $materialCost'); // Debug print
        return total + materialCost;
      });
    } catch (e) {
      print('Error calculating recipe materials cost: $e');
      return 0.0;
    }
  }

  double _calculateAdditionalCosts(Map<String, dynamic> batch) {
    final costs = batch['costs'] ?? [];
    return costs.fold(0.0, (total, cost) {
      return total + (double.tryParse(cost['usd_amount']?.toString() ?? '0') ?? 0.0);
    });
  }

  Widget _buildPricingCalculator(double costPerKg, double outputKg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing Calculator',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            // Toggle between margin-based and custom price
            SwitchListTile(
              title: const Text('Custom Price'),
              subtitle: Text(_isCustomPrice ? 'Enter selling price' : 'Use margin percentage'),
              value: _isCustomPrice,
              onChanged: (bool value) {
                setState(() {
                  _isCustomPrice = value;
                  if (!value) {
                    _sellingPriceController.clear();
                    _profitMarginController.text = '30'; // Default margin
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // Input Section
            if (_isCustomPrice)
              TextField(
                controller: _sellingPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Selling Price per kg',
                  prefixText: '\$ ',
                ),
                onChanged: (_) => setState(() {}),
              )
            else
              Column(
                children: [
                  // Margin Selection Chips
                  Wrap(
                    spacing: 8.0,
                    children: _suggestedMargins.map((margin) {
                      return ChoiceChip(
                        label: Text('$margin%'),
                        selected: _profitMarginController.text == margin.toString(),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _profitMarginController.text = margin.toString();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Custom margin input
                  TextField(
                    controller: _profitMarginController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Profit Margin',
                      suffixText: '%',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Pricing Summary
            _buildDetailedPricingSummary(costPerKg, outputKg),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedPricingSummary(double costPerKg, double outputKg) {
    double sellingPrice;
    double profitMargin;
    
    if (_isCustomPrice) {
      sellingPrice = double.tryParse(_sellingPriceController.text) ?? costPerKg;
      profitMargin = costPerKg > 0 ? ((sellingPrice - costPerKg) / sellingPrice) * 100 : 0;
    } else {
      profitMargin = double.tryParse(_profitMarginController.text) ?? 30;
      sellingPrice = costPerKg * (1 + (profitMargin / 100));
    }

    final profitPerKg = sellingPrice - costPerKg;
    final isProfit = profitPerKg > 0;
    
    final batchQuantity = outputKg;
    final totalProfit = profitPerKg * batchQuantity;
    final grossIncome = sellingPrice * batchQuantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPricingRow('Cost per kg:', '\$${costPerKg.toStringAsFixed(2)}'),
        _buildPricingRow('Selling price per kg:', '\$${sellingPrice.toStringAsFixed(2)}'),
        _buildPricingRow(
          'Profit per kg:',
          '\$${profitPerKg.abs().toStringAsFixed(2)}',
          color: isProfit ? Colors.green : Colors.red,
        ),
        _buildPricingRow(
          'Margin:',
          '${profitMargin.toStringAsFixed(1)}%',
          color: isProfit ? Colors.green : Colors.red,
        ),
        const Divider(),
        _buildPricingRow('Batch Quantity:', '${batchQuantity.toStringAsFixed(2)} kg'),
        _buildPricingRow(
          'Expected Batch Profit:',
          '\$${totalProfit.toStringAsFixed(2)}',
          color: isProfit ? Colors.green : Colors.red,
        ),
        _buildPricingRow(
          'Gross Income:',
          '\$${grossIncome.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingRow(String label, String value, {Color? color, TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: style ?? TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalCosts(List<dynamic> costs) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Additional Costs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: costs.length,
            itemBuilder: (context, index) {
              final cost = costs[index];
              return ListTile(
                title: Text(cost['description'] ?? 'Unknown Cost'),
                subtitle: Text('${cost['amount']} ${cost['currency']}'),
                trailing: Text('\$${(double.tryParse(cost['usd_amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}'),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildIngredientCosts(Map<String, dynamic> batch) {
    final recipe = batch['recipe'];
    final recipeMaterials = recipe?['recipe_materials'] ?? [];
    double totalIngredientCost = 0;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recipe Ingredients',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Recipe: ${recipe?['product_name'] ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Divider(),
          DataTable(
            columns: const [
              DataColumn(label: Text('Ingredient')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Unit Cost')),
              DataColumn(label: Text('Total Cost')),
            ],
            rows: recipeMaterials.map<DataRow>((material) {
              try {
                final rawMaterial = material['raw_materials'];
                final quantity = double.parse(material['quantity'].toString());
                final costPerUnit = double.parse(rawMaterial['cost_per_unit'].toString());
                final cost = quantity * costPerUnit;
                totalIngredientCost += cost;

                print('Processing material: ${rawMaterial['name']}, ' // Debug print
                      'Quantity: $quantity, '
                      'Cost/Unit: $costPerUnit, '
                      'Total: $cost');

                return DataRow(
                  cells: [
                    DataCell(Text(rawMaterial['name'])),
                    DataCell(Text('${quantity.toStringAsFixed(2)} ${rawMaterial['unit']}')),
                    DataCell(Text('\$${costPerUnit.toStringAsFixed(2)}')),
                    DataCell(Text('\$${cost.toStringAsFixed(2)}')),
                  ],
                );
              } catch (e) {
                print('Error processing material: $material');
                print('Error: $e');
                return DataRow(
                  cells: const [
                    DataCell(Text('Error')),
                    DataCell(Text('-')),
                    DataCell(Text('-')),
                    DataCell(Text('-')),
                  ],
                );
              }
            }).toList(),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Ingredient Cost:'),
                Text(
                  '\$${totalIngredientCost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalIngredientCost(Map<String, dynamic> batch) {
    final recipe = batch['recipe'];
    final recipeMaterials = recipe?['recipe_materials'] ?? [];
    return recipeMaterials.fold(0.0, (total, material) {
      try {
        final rawMaterial = material['raw_materials'];
        final quantity = double.parse(material['quantity'].toString());
        final costPerUnit = double.parse(rawMaterial['cost_per_unit'].toString());
        return total + (quantity * costPerUnit);
      } catch (e) {
        print('Error calculating cost: $e');
        return total;
      }
    });
  }

  Widget _buildFinishBatchButton(Map<String, dynamic> batch) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: () => _finishBatch(batch),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
        ),
        child: const Text('Mark as Finished'),
      ),
    );
  }

  Icon _getStatusIcon(String? status) {
    switch (status) {
      case 'finished':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'in_progress':
        return const Icon(Icons.pending, color: Colors.orange);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  Future<void> _finishBatch(Map<String, dynamic> batch) async {
    try {
      if (batch['status'] == 'finished') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This batch is already finished')),
        );
        return;
      }

      final recipeMaterials = batch['recipe']['recipe_materials'] ?? [];
      final materialsCost = _calculateRecipeMaterialsCost(recipeMaterials);
      final additionalCost = _calculateAdditionalCosts(batch);
      final totalCost = materialsCost + additionalCost;
      final outputKg = batch['actual_output_kg'] ?? 0.0;
      final costPerKg = outputKg > 0 ? totalCost / outputKg : 0.0;
      
      double sellingPrice;
      if (_isCustomPrice) {
        sellingPrice = double.tryParse(_sellingPriceController.text) ?? costPerKg;
      } else {
        final profitMargin = double.tryParse(_profitMarginController.text) ?? 30;
        sellingPrice = costPerKg * (1 + (profitMargin / 100));
      }

      // Generate a unique barcode using timestamp and batch number
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final barcode = 'PRD${batch['batch_number']}${timestamp.substring(timestamp.length - 4)}';

      // Prepare product data
      final productData = {
        'name': batch['recipe']['product_name'],
        'price': costPerKg,
        'sell_price': sellingPrice,
        'description': batch['recipe']['product_name'],
        'stock_quantity': outputKg,
        'batch_id': batch['batch_number'],
        'user_id': currentUser?.id,
        'barcode': barcode,                    // Add generated barcode
        'tax_rate': 0.0,                       // Default tax rate
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 1. Update production_batches
      await supabase
          .from('production_batches')
          .update({
            'status': 'finished',
            'total_cost': totalCost,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.batchId);

      // 2. Insert into products
      final productResponse = await supabase
          .from('products')
          .insert(productData)
          .select()
          .single();
      
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Batch finished and product added to inventory')),
        );
      }
    } catch (e) {
      print('Error finishing batch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating batch status: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final batch = await _loadBatchDetails();
    final isFinished = batch['status'] == 'finished';
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isFinished ? '⚠️ Delete Finished Batch' : 'Confirm Delete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFinished)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade50,
                  child: const Text(
                    'WARNING: This batch has been completed and transferred to inventory. '
                    'Deleting it may cause inventory discrepancies.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to delete this batch? '
                'This will also delete all related costs and records.'
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteBatch();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBatch() async {
    try {
      // First delete related records in additional_costs
      await supabase
          .from('additional_costs')
          .delete()
          .eq('batch_id', widget.batchId);
      
      // Then delete the batch
      await supabase
          .from('production_batches')
          .delete()
          .eq('id', widget.batchId);
      
      if (mounted) {
        Navigator.of(context).pop(); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting batch: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _loadBatchDetails() async {
    try {
      print('Loading batch details for ID: ${widget.batchId}');
      final response = await supabase
          .from('production_batches')
          .select('''
            *,
            costs:additional_costs(*),
            recipe:production_recipes!recipe_id(
              id,
              product_name,
              recipe_materials(
                id,
                quantity,
                raw_materials(
                  id,
                  name,
                  unit,
                  cost_per_unit,
                  current_stock
                )
              )
            )
          ''')
          .eq('id', widget.batchId)
          .single();

      print('Full batch response: $response');
      return response;
    } catch (e, stackTrace) {
      print('Error loading batch details: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _getCurrentUserProfile() async {
    if (currentUser == null) return null;
    
    try {
      final response = await supabase
          .from('users')
          .select('id, name, email, username')
          .eq('email', currentUser?.email as Object)
          .single();
      
      print('User details: $response');
      return response;
    } catch (e) {
      print('Error fetching user details: $e');
      return {
        'id': currentUser?.id,
        'email': currentUser?.email,
        'name': currentUser?.email
      };
    }
  }

  @override
  void dispose() {
    _profitMarginController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }
} 