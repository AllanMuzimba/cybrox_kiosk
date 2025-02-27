import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cybrox_kiosk_management/services/shared_prefs_services.dart';
import 'package:cybrox_kiosk_management/models/user.dart' as cybrox_user;

class PaymentFormDialog extends StatefulWidget {
  final cybrox_user.User? currentUser;
  final VoidCallback onPaymentComplete;

  const PaymentFormDialog({
    super.key,
    required this.currentUser,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabaseClient = Supabase.instance.client;
  
  int? _userId;
  String? _username;
  final _amountController = TextEditingController();

  String _selectedTransactionType = 'income';
  String? _selectedCompanyId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _companies = [];

  @override
  void initState() {
    super.initState();
    _fetchUserAndCompanies();
  }

  Future<void> _fetchUserAndCompanies() async {
    final userData = await SharedPreferencesService().getUserData();
    if (userData != null) {
      setState(() {
        _userId = userData.id;
        _username = userData.username;
      });
    }
    await _fetchCompanies();
  }

  /// Fetch the list of companies from Supabase
  Future<void> _fetchCompanies() async {
    try {
      final response = await supabaseClient.from('company_details').select('id, company_name');

      setState(() {
        _companies = List<Map<String, dynamic>>.from(response);
        if (_companies.isNotEmpty) {
          _selectedCompanyId = _companies.first['id'].toString();
        }
      });
    } catch (e) {
      print('Error fetching companies: $e');
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company')),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await supabaseClient.from('finance').insert({
        'company_id': int.parse(_selectedCompanyId!),
        'user_id': _userId,
        'amount': _selectedTransactionType == 'expense' 
          ? -double.parse(_amountController.text)
          : double.parse(_amountController.text),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction recorded successfully')),
        );
        widget.onPaymentComplete();
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Transaction error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Record Transaction',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Dropdown to Select Company
                  const Text('Select Company:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCompanyId,
                    isExpanded: true,
                    items: _companies.map((company) {
                      return DropdownMenuItem(
                        value: company['id'].toString(),
                        child: Text(company['company_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCompanyId = value);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Income'),
                          value: 'income',
                          groupValue: _selectedTransactionType,
                          onChanged: (value) {
                            setState(() => _selectedTransactionType = value!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Expense'),
                          value: 'expense',
                          groupValue: _selectedTransactionType,
                          onChanged: (value) {
                            setState(() => _selectedTransactionType = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitTransaction,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
