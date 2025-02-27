import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IngredientForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  
  const IngredientForm({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  _IngredientFormState createState() => _IngredientFormState();
}

class _IngredientFormState extends State<IngredientForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMaterialId;
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _materials = [];

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
              future: _loadMaterials(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                _materials = snapshot.data!;
                
                return DropdownButtonFormField<String?>(
                  hint: const Text('Select Material'),
                  value: _selectedMaterialId,
                  items: _materials.map((material) {
                    return DropdownMenuItem<String?>(
                      value: material['id']?.toString(),
                      child: Text(material['name'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedMaterialId = value;
                      if (value != null) {
                        final selectedMaterial = _materials.firstWhere(
                          (m) => m['id'].toString() == value,
                          orElse: () => {'unit': ''},
                        );
                        _unitController.text = selectedMaterial['unit'] ?? '';
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Material',
                  ),
                  validator: (value) => value == null ? 'Required' : null,
                );
              },
            ),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveIngredient,
              child: const Text('Add Ingredient'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadMaterials() async {
    final response = await supabase
        .from('raw_materials')
        .select()
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  void _saveIngredient() {
    if (_formKey.currentState!.validate() && _selectedMaterialId != null) {
      final selectedMaterial = _materials.firstWhere(
        (m) => m['id'].toString() == _selectedMaterialId,
        orElse: () => {'id': '', 'name': '', 'unit': ''},
      );
      
      widget.onSave({
        'material_id': selectedMaterial['id'],
        'material_name': selectedMaterial['name'],
        'quantity': double.parse(_quantityController.text),
        'unit': selectedMaterial['unit'],
      });
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }
} 