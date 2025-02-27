import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class ProductionCostForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  
  const ProductionCostForm({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  _ProductionCostFormState createState() => _ProductionCostFormState();
}

class _ProductionCostFormState extends State<ProductionCostForm> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCurrency = 'USD';
  final List<String> _costTypes = [
    'Transport',
    'Electricity',
    'Water',
    'Labor',
    'Tollgate',
    'Customs',
    'Tax',
    'Other'
  ];

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
            DropdownButtonFormField<String>(
              value: _typeController.text.isEmpty ? null : _typeController.text,
              items: _costTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                _typeController.text = value ?? '';
              },
              decoration: const InputDecoration(
                labelText: 'Cost Type',
              ),
            ),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              items: ['USD', 'EUR', 'GBP', 'ZWL'].map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Currency',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveCost,
              child: const Text('Add Cost'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCost() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'description': _typeController.text,
        'amount': double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')),
        'currency': _selectedCurrency,
      });
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _amountController.dispose();
    super.dispose();
  }
} 