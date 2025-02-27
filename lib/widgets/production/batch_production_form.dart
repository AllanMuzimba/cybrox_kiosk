import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/utils/currency_converter.dart';
import 'package:cybrox_kiosk_management/widgets/production/production_cost_form.dart';

class BatchProductionForm extends StatefulWidget {
  final VoidCallback onSubmit;

  const BatchProductionForm({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _BatchProductionFormState createState() => _BatchProductionFormState();
}

class _BatchProductionFormState extends State<BatchProductionForm> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  
  String? _selectedRecipeId;
  List<Map<String, dynamic>> _recipes = [];
  String _batchNumber = '';
  final _outputController = TextEditingController();
  final List<Map<String, dynamic>> _costs = [];
  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  final _batchNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateBatchNumber();
  }

  Future<void> _generateBatchNumber() async {
    try {
      print('Generating batch number...');
      final response = await supabase
          .from('production_batches')
          .select('batch_number')
          .order('batch_number', ascending: false)
          .limit(1)
          .maybeSingle();

      print('Database response: $response');

      int nextNumber;
      if (response != null && response['batch_number'] != null) {
        print('Last batch number: ${response['batch_number']}');
        nextNumber = int.parse(response['batch_number']) + 1;
      } else {
        print('No existing batches, starting from 001');
        nextNumber = 1;
      }

      _batchNumber = nextNumber.toString().padLeft(3, '0');
      print('Generated batch number: $_batchNumber');
      
      _batchNumberController.text = _batchNumber;
      setState(() {});
    } catch (e) {
      print('Error generating batch number: $e');
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      _batchNumber = timestamp.substring(timestamp.length - 3).padLeft(3, '0');
      _batchNumberController.text = _batchNumber;
      print('Generated fallback batch number: $_batchNumber');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadRecipes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                _recipes = snapshot.data!;
                
                return DropdownButtonFormField<String>(
                  value: _selectedRecipeId,
                  items: _recipes.map((recipe) {
                    return DropdownMenuItem<String>(
                      value: recipe['id'],
                      child: Text(recipe['product_name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRecipeId = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Recipe',
                  ),
                );
              },
            ),
            TextFormField(
              controller: _batchNumberController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Batch Number',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
                helperText: _batchNumber.isEmpty ? 'Waiting for batch number...' : null,
                errorText: _batchNumber.isEmpty ? 'Failed to generate batch number' : null,
              ),
            ),
            TextFormField(
              controller: _outputController,
              decoration: const InputDecoration(labelText: 'Actual Output (kg)'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text('Additional Costs', style: Theme.of(context).textTheme.titleMedium),
            ..._buildCostsList(),
            ElevatedButton(
              onPressed: _addCost,
              child: const Text('Add Cost'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitForm,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Start Production'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadRecipes() async {
    final response = await supabase
        .from('production_recipes')
        .select();

    return List<Map<String, dynamic>>.from(response);
  }

  List<Widget> _buildCostsList() {
    return _costs.map((cost) {
      return ListTile(
        title: Text(cost['type']?.toString() ?? cost['description']?.toString() ?? 'Unknown Cost'),
        subtitle: Text('${cost['amount']} ${cost['currency']}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _removeCost(cost),
        ),
      );
    }).toList();
  }

  void _addCost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProductionCostForm(
        onSave: (cost) {
          setState(() {
            _costs.add(cost);
          });
        },
      ),
    );
  }

  void _removeCost(Map<String, dynamic> cost) {
    setState(() {
      _costs.remove(cost);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() && _selectedRecipeId != null) return;

    setState(() => _isLoading = true);

    try {
      await CurrencyConverter.updateRates();
      
      // Convert all costs to USD
      double totalCost = 0;
      for (final cost in _costs) {
        final amount = double.parse(cost['amount'].toString());
        final usdAmount = CurrencyConverter.convert(
          amount, 
          cost['currency'], 
          'USD'
        );
        totalCost += usdAmount;
      }

      // Create batch
      final response = await supabase
          .from('production_batches')
          .insert({
            'recipe_id': _selectedRecipeId,
            'batch_number': _batchNumber,
            'actual_output_kg': int.parse(_outputController.text),
            'total_cost': totalCost,
            'status': 'in_progress',
          })
          .select();
      
      if (response.isNotEmpty) {
        final batchId = response[0]['id'];
        
        // Save additional costs
        for (final cost in _costs) {
          await supabase
              .from('additional_costs')
              .insert({
                'batch_id': batchId,
                'cost_type': cost['type'],
                'amount': cost['amount'],
                'currency': cost['currency'],
                'usd_amount': CurrencyConverter.convert(
                  double.parse(cost['amount'].toString()),
                  cost['currency'],
                  'USD'
                ),
              })
              .select();
        }

        if (mounted) {
          widget.onSubmit();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch created successfully')),
          );
        }
      }
    } catch (e) {
      print('Error creating batch: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    _outputController.dispose();
    super.dispose();
  }
} 