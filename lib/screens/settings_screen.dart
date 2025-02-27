import 'package:flutter/material.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';
import 'package:cybrox_kiosk_management/models/company.dart';
import 'package:cybrox_kiosk_management/models/tax.dart';
import 'package:cybrox_kiosk_management/models/user.dart' as cybrox_user;
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Company> _companies = [];
  List<Tax> _taxes = [];
  List<cybrox_user.User> _users = [];
  final List<String> _roles = ['admin', 'manager', 'dispatch', 'finance', ];
  String? _selectedRole;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _taxNameController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  Company? _selectedCompany;
  bool _isLoading = true;
  List<Map<String, dynamic>> _exchangeRates = [];
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  bool _isLoadingRates = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
    _fetchTaxes();
    _loadUsers();
    _loadExchangeRates();
    _checkAdminStatus();
  }

  Future<void> _fetchCompanies() async {
    final companies = await _supabaseService.fetchCompanies();
    setState(() {
      _companies = companies;
    });
  }

  Future<void> _fetchTaxes() async {
    final taxes = await _supabaseService.fetchTaxes();
    setState(() {
      _taxes = taxes;
    });
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _supabaseService.fetchUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _loadExchangeRates() async {
    try {
      final response = await _supabaseService.supabase
          .from('exchange_rates')
          .select()
          .order('currency');
      
      setState(() {
        _exchangeRates = (response as List).cast<Map<String, dynamic>>();
        _isLoadingRates = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exchange rates: $e')),
        );
      }
      setState(() => _isLoadingRates = false);
    }
  }

  Future<void> _checkAdminStatus() async {
    if (mounted) {
      setState(() {
      });
    }
  }

  Future<void> _addCompany() async {
    Company company = Company(
      id: 0,
      isHq: false,
      name: _nameController.text,
      address: _addressController.text,
      contactPhone: _contactPhoneController.text,
      email: _emailController.text,
      tin: _tinController.text,
    );
    await _supabaseService.addCompany(company);
    _fetchCompanies();
    Navigator.pop(context);
  }

  Future<void> _addTax() async {
    final tax = Tax(
      id: 0,
      name: _taxNameController.text,
      rate: double.parse(_taxRateController.text),
    );
    await _supabaseService.addTax(tax);
    _fetchTaxes();
    Navigator.pop(context);
  }

  Future<void> _addUser() async {
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company')),
      );
      return;
    }

    try {
      final userData = {
        'name': _nameController.text,
        'username': _usernameController.text,
        'password': _passwordController.text,
        'role': _roleController.text,
        'company_id': _selectedCompany!.id,
        'email': _userEmailController.text,
        'phone': _userPhoneController.text,
      };

      final response = await _supabaseService.addUser(userData);
      
      if (response['id'] != null) {
        // Clear the form
        _nameController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _roleController.clear();
        _userEmailController.clear();
        _userPhoneController.clear();
        setState(() => _selectedCompany = null);

        // Refresh the users list
        await _loadUsers();
        
        // Close the dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
      }
    } catch (e) {
      print('Error creating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating user: $e')),
      );
    }
  }

  Future<void> _resetPassword(cybrox_user.User user) async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for ${user.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _supabaseService.resetUserPassword(
                    user.id,
                    passwordController.text,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error resetting password: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(cybrox_user.User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text(user.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Username', user.username),
            _buildDetailRow('Email', user.email),
            if (user.phone != null) _buildDetailRow('Phone', user.phone!),
            _buildDetailRow('Role', user.role),
            _buildDetailRow(
              'Created',
              DateFormat('MMM dd, yyyy').format(user.createdAt),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPassword(user);
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Company'),
          content: Column(
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
        );
      },
    );
  }

  void _showAddTaxDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Tax'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taxNameController,
                decoration: const InputDecoration(labelText: 'Tax Name'),
              ),
              TextField(
                controller: _taxRateController,
                decoration: const InputDecoration(labelText: 'Tax Rate'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _addTax,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddUserDialog() {
    _selectedRole = null;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: _roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedRole = value;
                    _roleController.text = value ?? '';
                  });
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              TextField(
                controller: _userEmailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _userPhoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              DropdownButtonFormField<Company>(
                value: _selectedCompany,
                items: _companies.map((company) {
                  return DropdownMenuItem<Company>(
                    value: company,
                    child: Text(company.name),
                  );
                }).toList(),
                onChanged: (Company? value) {
                  setState(() {
                    _selectedCompany = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Company'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _addUser,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddExchangeRateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Exchange Rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currencyController,
                decoration: const InputDecoration(
                  labelText: 'Currency Code',
                  hintText: 'e.g., EUR, GBP',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Exchange Rate to USD',
                  hintText: 'e.g., 1.2',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _addExchangeRate(),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addExchangeRate() async {
    try {
      final currency = _currencyController.text.toUpperCase();
      final rate = double.parse(_rateController.text);

      await _supabaseService.supabase
          .from('exchange_rates')
          .insert({
            'currency': currency,
            'rate': rate,
          });

      _currencyController.clear();
      _rateController.clear();
      
      await _loadExchangeRates();
      Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exchange rate added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding exchange rate: $e')),
        );
      }
    }
  }

  Future<void> _updateExchangeRate(Map<String, dynamic> rate) async {
    final TextEditingController rateController = TextEditingController(
      text: rate['rate'].toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${rate['currency']} Rate'),
        content: TextField(
          controller: rateController,
          decoration: const InputDecoration(
            labelText: 'New Rate',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabaseService.supabase
                    .from('exchange_rates')
                    .update({
                      'rate': double.parse(rateController.text),
                      'updated_at': DateTime.now().toIso8601String(),
                    })
                    .eq('id', rate['id']);
                
                await _loadExchangeRates();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rate updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating rate: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection(
              title: 'Companies',
              items: _companies,
              itemBuilder: (company) => ListTile(
                title: Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(company.address),
                trailing: Icon(Icons.business, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Taxes',
              items: _taxes,
              itemBuilder: (tax) => ListTile(
                title: Text(tax.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.business, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Taxes',
              items: _taxes,
              itemBuilder: (tax) => ListTile(
                title: Text(tax.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${tax.rate}%'),
                trailing: Icon(Icons.money, color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Users',
              items: _users,
              itemBuilder: (user) => ListTile(
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.money, color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Users',
              items: _users,
              itemBuilder: (user) => ListTile(
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user.role),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showUserDetails(user),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Exchange Rates',
              items: _exchangeRates,
              itemBuilder: (rate) => ListTile(
                title: Text(
                  rate['currency'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '1 ${rate['currency']} = ${rate['rate']} USD\n'
                  'Updated: ${DateTime.parse(rate['updated_at']).toLocal().toString().split('.')[0]}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _updateExchangeRate(rate),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.business, color: Colors.blueAccent),
                  title: Text('Add Company'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddCompanyDialog();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.money, color: Colors.green),
                  title: Text('Add Tax'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddTaxDialog();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person, color: Colors.purple),
                  title: Text('Add User'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddUserDialog();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.currency_exchange, color: Colors.orange),
                  title: Text('Add Exchange Rate'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddExchangeRateDialog();
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<dynamic> items,
    required Widget Function(dynamic) itemBuilder,
  }) {
    return Card(
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        children: items.map(itemBuilder).toList(),
      ),
    );
  }
}