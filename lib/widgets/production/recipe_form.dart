import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/widgets/production/ingredient_form.dart';

class RecipeForm extends StatefulWidget {
  final Map<String, dynamic>? recipe;
  
  const RecipeForm({Key? key, this.recipe}) : super(key: key);

  @override
  _RecipeFormState createState() => _RecipeFormState();
}

class _RecipeFormState extends State<RecipeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _outputController = TextEditingController();
  List<Map<String, dynamic>> _ingredients = [];
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _nameController.text = widget.recipe!['product_name'] ?? '';
      _outputController.text = widget.recipe!['expected_output_kg']?.toString() ?? '';
      _loadIngredients();
    }
  }

  Future<void> _loadIngredients() async {
    if (widget.recipe?['id'] == null) return;  // Add null check
    
    final response = await supabase
        .from('recipe_materials')
        .select()
        .eq('recipe_id', widget.recipe!['id']);

    setState(() {
      _ingredients = List<Map<String, dynamic>>.from(response);
    });
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _outputController,
              decoration: const InputDecoration(labelText: 'Expected Output (kg)'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
            ..._buildIngredientsList(),
            ElevatedButton(
              onPressed: _addIngredient,
              child: const Text('Add Ingredient'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveRecipe,
              child: const Text('Save Recipe'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIngredientsList() {
    return _ingredients.map((ingredient) {
      return ListTile(
        title: Text(ingredient['material_name'] ?? 'Unknown Material'),
        subtitle: Text('${ingredient['quantity'] ?? 0} ${ingredient['unit'] ?? ''}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _removeIngredient(ingredient),
        ),
      );
    }).toList();
  }

  void _addIngredient() {
    // Show ingredient selection modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => IngredientForm(
        onSave: (ingredient) {
          setState(() {
            _ingredients.add(ingredient);
          });
        },
      ),
    );
  }

  void _removeIngredient(Map<String, dynamic> ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      try {
        final recipeData = {
          'product_name': _nameController.text,
          'expected_output_kg': double.parse(_outputController.text),
        };

        final response = await supabase
            .from('production_recipes')
            .insert(recipeData)
            .select();

        if (response.isNotEmpty) {
          final recipeId = response[0]['id'];
          
          // Save ingredients
          for (final ingredient in _ingredients) {
            await supabase
                .from('recipe_materials')
                .insert({
                  'recipe_id': recipeId,
                  'material_id': ingredient['material_id'],
                  'quantity': ingredient['quantity'],
                  'unit': ingredient['unit'],
                })
                .select();
          }

          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _outputController.dispose();
    super.dispose();
  }
} 