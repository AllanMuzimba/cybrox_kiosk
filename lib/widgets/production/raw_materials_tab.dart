import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/widgets/production/raw_materials_form.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';
import 'package:cybrox_kiosk_management/models/raw_material.dart';

class RawMaterialsTab extends StatefulWidget {
  final SupabaseService supabaseService;
  final GlobalKey<_RawMaterialsTabState> _key;

  RawMaterialsTab({
    Key? key,
    required this.supabaseService,
  }) : _key = GlobalKey<_RawMaterialsTabState>(),
       super(key: key);

  void refreshMaterials() {
    _key.currentState?._loadRawMaterials();
  }

  @override
  State<RawMaterialsTab> createState() => _RawMaterialsTabState();
}

class _RawMaterialsTabState extends State<RawMaterialsTab> {
  bool _isLoading = false;
  List<RawMaterial> rawMaterials = [];

  @override
  void initState() {
    super.initState();
    _loadRawMaterials();
  }

  Future<void> _loadRawMaterials() async {
    try {
      setState(() => _isLoading = true);
      final response = await widget.supabaseService.supabase
          .from('raw_materials')
          .select()
          .order('name');
      
      setState(() {
        rawMaterials = response.map((json) => RawMaterial.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error loading raw materials: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showUpdateDialog(RawMaterial material) async {
    final nameController = TextEditingController(text: material.name);
    final currentStockController = TextEditingController(text: material.currentStock.toString());
    final unitController = TextEditingController(text: material.unit);
    final costPerUnitController = TextEditingController(text: material.costPerUnit.toString());

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Raw Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: currentStockController,
                decoration: const InputDecoration(labelText: 'Current Stock'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              TextField(
                controller: costPerUnitController,
                decoration: const InputDecoration(labelText: 'Cost Per Unit'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'current_stock': double.tryParse(currentStockController.text) ?? 0,
              'unit': unitController.text,
              'cost_per_unit': double.tryParse(costPerUnitController.text) ?? 0,
            }),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);
        
        await widget.supabaseService.supabase
            .from('raw_materials')
            .update(result)
            .eq('id', material.id);

        await _loadRawMaterials();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Raw material updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating raw material: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rawMaterials.isEmpty) {
      return const Center(
        child: Text(
          'No raw materials found.\nClick + to add new materials.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: ListView.separated(
          itemCount: rawMaterials.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final material = rawMaterials[index];
            return ListTile(
              title: Text(
                material.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock: ${material.currentStock} ${material.unit}'),
                  Text('Cost: \$${material.costPerUnit.toStringAsFixed(2)}/${material.unit}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showUpdateDialog(material),
              ),
            );
          },
        ),
      ),
    );
  }
} 