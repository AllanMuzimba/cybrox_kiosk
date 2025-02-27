import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/widgets/production/raw_materials_tab.dart';
import 'package:cybrox_kiosk_management/widgets/production/recipes_tab.dart';
import 'package:cybrox_kiosk_management/widgets/production/batch_production_tab.dart';
import 'package:cybrox_kiosk_management/widgets/production/raw_materials_form.dart';
import 'package:cybrox_kiosk_management/widgets/production/recipe_form.dart';
import 'package:cybrox_kiosk_management/widgets/production/batch_production_form.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';

class Production extends StatefulWidget {
  const Production({Key? key}) : super(key: key);

  @override
  _ProductionState createState() => _ProductionState();
}

class _ProductionState extends State<Production> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  late RawMaterialsTab _rawMaterialsTab;
  late RecipesTab _recipesTab;
  late BatchProductionTab _batchProductionTab;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _rawMaterialsTab = RawMaterialsTab(supabaseService: _supabaseService);
    _recipesTab = RecipesTab(supabaseService: _supabaseService);
    _batchProductionTab = BatchProductionTab();
  }

  void refreshCurrentTab() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _rawMaterialsTab.refreshMaterials();
          break;
        case 1:
          _recipesTab.refreshRecipes();
          break;
        case 2:
          _batchProductionTab.refreshBatches();
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Raw Materials'),
            Tab(text: 'Production Recipes'),
            Tab(text: 'Start Production'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _rawMaterialsTab,
          _recipesTab,
          _batchProductionTab,
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          switch (_tabController.index) {
            case 0:
              _showAddRawMaterialModal();
              break;
            case 1:
              _showAddRecipeModal();
              break;
            case 2:
              _showStartProductionModal();
              break;
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRawMaterialModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RawMaterialsForm(
        supabaseService: _supabaseService,
        onSubmit: refreshCurrentTab,
      ),
    );
  }

  void _showAddRecipeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RecipeForm(),
    );
  }

  void _showStartProductionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BatchProductionForm(
        onSubmit: refreshCurrentTab,
      ),
    );
  }
}
