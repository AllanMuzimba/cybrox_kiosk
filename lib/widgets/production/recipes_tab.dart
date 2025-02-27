import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/screens/production/recipe_details_screen.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';

class RecipesTab extends StatefulWidget {
  final SupabaseService supabaseService;
  final GlobalKey<_RecipesTabState> _key = GlobalKey<_RecipesTabState>();

  RecipesTab({
    Key? key,
    required this.supabaseService,
  }) : super(key: key);

  void refreshRecipes() {
    _key.currentState?._loadRecipes();
  }

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: supabase.from('production_recipes').stream(primaryKey: ['id']),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final recipes = snapshot.data!;

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return ListTile(
              title: Text(recipe['product_name']),
              subtitle: Text('Expected Output: ${recipe['expected_output_kg']} kg'),
              onTap: () => _viewRecipeDetails(recipe),
            );
          },
        );
      },
    );
  }

  void _viewRecipeDetails(Map<String, dynamic> recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(recipeId: recipe['id']),
      ),
    );
  }

  void _loadRecipes() {
    setState(() {});  // This will trigger a rebuild of StreamBuilder
  }
} 