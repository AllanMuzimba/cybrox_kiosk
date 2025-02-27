import 'package:cybrox_kiosk_management/utils/cost_calculator.dart';
import 'package:cybrox_kiosk_management/widgets/production/ingredient_form.dart';
import 'package:cybrox_kiosk_management/widgets/production/recipe_form.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final String recipeId;
  
  const RecipeDetailsScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  final supabase = Supabase.instance.client;
  final CostCalculator _costCalculator = CostCalculator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editRecipe,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadRecipeDetails(),
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipe = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['product_name'],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Expected Output: ${recipe['expected_output_kg']} kg',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FutureBuilder<double>(
                  future: CostCalculator.calculateProductionCost(widget.recipeId),
                  builder: (context, costSnapshot) {
                    if (!costSnapshot.hasData) return const SizedBox();
                    return Text(
                      'Total Cost: \$${costSnapshot.data!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ingredients:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Ingredient'),
                      onPressed: () => _addIngredient(recipe),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildIngredientsList(recipe['ingredients'] ?? []),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editRecipe() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RecipeForm(recipe: {'id': widget.recipeId}),
    ).then((_) => setState(() {}));  // Refresh after edit
  }

  void _addIngredient(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => IngredientForm(
        onSave: (ingredient) async {
          await supabase
              .from('recipe_materials')
              .insert({
                'recipe_id': widget.recipeId,
                'material_id': ingredient['material_id'],
                'quantity': ingredient['quantity'],
                'unit': ingredient['unit'],
              });
          setState(() {});  // Refresh the list
        },
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // First delete recipe materials
        await supabase
            .from('recipe_materials')
            .delete()
            .eq('recipe_id', widget.recipeId);

        // Then delete the recipe
        await supabase
            .from('production_recipes')
            .delete()
            .eq('id', widget.recipeId);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting recipe: $e')),
          );
        }
      }
    }
  }

  Widget _buildIngredientsList(List<dynamic> ingredients) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        return Dismissible(
          key: Key(ingredient['material_id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteIngredient(ingredient['material_id']),
          child: ListTile(
            title: Text(ingredient['raw_materials']['name']),
            subtitle: Text('${ingredient['quantity']} ${ingredient['unit']}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editIngredient(ingredient),
            ),
          ),
        );
      },
    );
  }

  void _editIngredient(Map<String, dynamic> ingredient) {
    // Implement ingredient editing
  }

  Future<void> _deleteIngredient(String materialId) async {
    await supabase
        .from('recipe_materials')
        .delete()
        .eq('recipe_id', widget.recipeId)
        .eq('material_id', materialId);
    setState(() {});
  }

  Future<Map<String, dynamic>> _loadRecipeDetails() async {
    final response = await supabase
        .from('production_recipes')
        .select('''
          *,
          ingredients:recipe_materials(
            material_id,
            quantity,
            unit,
            raw_materials(name)
          )
        ''')
        .eq('id', widget.recipeId)
        .single();

    return response;
  }
} 