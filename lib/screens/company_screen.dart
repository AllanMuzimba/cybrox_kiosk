import 'package:flutter/material.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';
import 'package:cybrox_kiosk_management/models/company.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});
  static const routeName = '/company';

  @override
  _CompanyScreenState createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Company> _companies = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    try {
      final companies = await _supabaseService.fetchCompanies();
      setState(() => _companies = companies);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching companies: $e')),
      );
    }
  }

  Future<void> _addCompany() async {
    try {
      final company = Company(
        id: 0,
        name: _nameController.text,
        address: _addressController.text,
        contactPhone: _contactPhoneController.text,
        email: _emailController.text,
        tin: _tinController.text,
        isHq: false,
      );
      await _supabaseService.addCompany(company);
      _fetchCompanies();
      Navigator.pop(context);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add company: $e')),
      );
    }
  }

  Future<void> _updateCompany(Company company) async {
    try {
      final updatedCompany = Company(
        id: company.id,
        name: _nameController.text,
        address: _addressController.text,
        contactPhone: _contactPhoneController.text,
        email: _emailController.text,
        tin: _tinController.text,
        isHq: company.isHq,
      );
      await _supabaseService.updateCompany(updatedCompany);
      _fetchCompanies();
      Navigator.pop(context);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update company: $e')),
      );
    }
  }

  Future<void> _deleteCompany(int id) async {
    try {
      await _supabaseService.deleteCompany(id);
      _fetchCompanies();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete company: $e')),
      );
    }
  }

  void _showAddCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(labelText: 'Contact Phone'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _tinController,
                decoration: const InputDecoration(labelText: 'TIN'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _addCompany,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyDialog(Company company) {
    _nameController.text = company.name;
    _addressController.text = company.address;
    _contactPhoneController.text = company.contactPhone;
    _emailController.text = company.email;
    _tinController.text = company.tin;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(labelText: 'Contact Phone'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _tinController,
                decoration: const InputDecoration(labelText: 'TIN'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _updateCompany(company),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: const Text('Are you sure you want to delete this company?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCompany(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _addressController.clear();
    _contactPhoneController.clear();
    _emailController.clear();
    _tinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Management', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 10,
        shadowColor: Colors.blueAccent.withOpacity(0.5),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddCompanyDialog,
          ),
        ],
      ),
      body: _companies.isEmpty
          ? const Center(
              child: Text(
                'No companies found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _companies.length,
              itemBuilder: (context, index) {
                final company = _companies[index];
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          company.address,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        if (company.isHq)
                          const SizedBox(height: 8),
                        if (company.isHq)
                          const Text(
                            'HQ Branch',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditCompanyDialog(company),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(company.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCompanyDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}