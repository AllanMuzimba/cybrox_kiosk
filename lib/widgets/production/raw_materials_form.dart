import 'package:flutter/material.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';
import 'package:flutter/services.dart';

class RawMaterialsForm extends StatefulWidget {
  final SupabaseService supabaseService;
  final Function() onSubmit;

  const RawMaterialsForm({
    Key? key,
    required this.supabaseService,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _RawMaterialsFormState createState() => _RawMaterialsFormState();
}

class _RawMaterialsFormState extends State<RawMaterialsForm> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final currentStockController = TextEditingController();
  final unitController = TextEditingController();
  final costPerUnitController = TextEditingController();
  String selectedCurrency = 'USD';
  Map<String, double> exchangeRates = {};
  bool _isLoadingRates = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExchangeRates();
  }

  Future<void> _loadExchangeRates() async {
    try {
      final response = await widget.supabaseService.supabase
          .from('exchange_rates')
          .select('currency, rate');
      
      setState(() {
        exchangeRates = {
          'USD': 1.0,
          ...Map.fromEntries(
            (response as List).map((rate) => 
              MapEntry(rate['currency'] as String, (rate['rate'] as num).toDouble())
            ),
          ),
        };
        if (!exchangeRates.containsKey(selectedCurrency)) {
          selectedCurrency = 'USD';
        }
        _isLoadingRates = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading exchange rates')),
        );
      }
      setState(() {
        exchangeRates = {'USD': 1.0};
        selectedCurrency = 'USD';
        _isLoadingRates = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    currentStockController.dispose();
    unitController.dispose();
    costPerUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85, // Max 85% of screen height
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Raw Material',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Material Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name',
                  hintText: 'Enter material name',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // Stock and Unit
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    // Stack vertically on small screens
                    return Column(
                      children: [
                        TextFormField(
                          controller: currentStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Current Stock',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (double.tryParse(value) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'kg, g, etc',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ],
                    );
                  } else {
                    // Side by side on larger screens
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: currentStockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Current Stock',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (double.tryParse(value) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              hintText: 'kg, g, etc',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Cost and Currency
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    // Stack vertically on small screens
                    return Column(
                      children: [
                        TextFormField(
                          controller: costPerUnitController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Cost per Unit',
                            prefixText: selectedCurrency == 'USD' ? '\$ ' : null,
                            suffixText: selectedCurrency != 'USD' ? selectedCurrency : null,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (double.tryParse(value) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _isLoadingRates
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                value: selectedCurrency,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                items: exchangeRates.keys
                                    .toList()
                                    .map((currency) => DropdownMenuItem(
                                          value: currency,
                                          child: Text(currency),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => selectedCurrency = value);
                                  }
                                },
                              ),
                      ],
                    );
                  } else {
                    // Side by side on larger screens
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: costPerUnitController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Cost per Unit',
                              prefixText: selectedCurrency == 'USD' ? '\$ ' : null,
                              suffixText: selectedCurrency != 'USD' ? selectedCurrency : null,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (double.tryParse(value) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _isLoadingRates
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  value: selectedCurrency,
                                  decoration: const InputDecoration(
                                    labelText: 'Currency',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  items: exchangeRates.keys
                                      .toList()
                                      .map((currency) => DropdownMenuItem(
                                            value: currency,
                                            child: Text(currency),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => selectedCurrency = value);
                                    }
                                  },
                                ),
                        ),
                      ],
                    );
                  }
                },
              ),
              
              // Conversion Info
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  selectedCurrency == 'USD' 
                      ? 'Amount in USD: \$${_getConvertedAmount().toStringAsFixed(2)}'
                      : 'Converted: \$${_getConvertedAmount().toStringAsFixed(2)} USD',
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedCurrency == 'USD' ? Colors.black54 : Colors.blue,
                    fontWeight: selectedCurrency == 'USD' ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
              
              // Submit Button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Material'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getConvertedAmount() {
    try {
      final amount = double.tryParse(costPerUnitController.text.trim()) ?? 0.0;
      if (selectedCurrency == 'USD') {
        print('DEBUG: USD amount (1:1): $amount');
        return double.parse(amount.toStringAsFixed(2));
      }
      
      final rate = exchangeRates[selectedCurrency] ?? 1.0;
      final convertedAmount = amount / rate;
      final roundedAmount = double.parse(convertedAmount.toStringAsFixed(2));
      
      print('DEBUG: Converting from $selectedCurrency to USD');
      print('DEBUG: Original amount: $amount');
      print('DEBUG: Exchange rate: $rate');
      print('DEBUG: Converted amount (rounded): $roundedAmount');
      
      return roundedAmount;
    } catch (e) {
      print('DEBUG: Error in conversion: $e');
      return 0.0;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      final convertedCost = _getConvertedAmount();
      final currentStock = double.parse(currentStockController.text.trim());

      final formattedCost = double.parse(convertedCost.toStringAsFixed(2));
      final formattedStock = double.parse(currentStock.toStringAsFixed(2));

      print('DEBUG: Submitting raw material:');
      print('DEBUG: Name: ${nameController.text}');
      print('DEBUG: Unit: ${unitController.text}');
      print('DEBUG: Converted Cost (USD): $formattedCost');
      print('DEBUG: Current Stock: $formattedStock');

      final response = await widget.supabaseService.supabase
          .from('raw_materials')
          .insert({
            'name': nameController.text.trim(),
            'unit': unitController.text.trim(),
            'cost_per_unit': formattedCost,
            'current_stock': formattedStock,
          })
          .select()
          .single();

      print('DEBUG: Insert response: $response');

      if (mounted) {
        Navigator.pop(context);
        widget.onSubmit();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error in _submitForm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding material: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
} 