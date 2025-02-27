import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cybrox_kiosk_management/widgets/status_chip.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderStatementScreen extends StatefulWidget {
  final Map<String, dynamic> orderDetails;
  
  const OrderStatementScreen({
    super.key,
    required this.orderDetails,
  });

  @override
  State<OrderStatementScreen> createState() => _OrderStatementScreenState();
}

class _OrderStatementScreenState extends State<OrderStatementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _companyDetails;
  Map<String, dynamic>? _userDetails;
  Map<String, dynamic>? _productDetails;

  @override
  void initState() {
    super.initState();
    _fetchAllDetails();
  }

  Future<void> _fetchAllDetails() async {
    try {
      setState(() => _isLoading = true);

      // First fetch the complete stock request with all related data
      final stockRequest = await _supabase
          .from('stock_requests')
          .select('''
            *,
            requesting_company:company_details!requesting_company_id(*),
            fulfilling_company:company_details!fulfilling_company_id(*),
            product:products!product_id(*),
            user:users!user_id(*)
          ''')
          .eq('id', widget.orderDetails['id'])
          .single();

      if (mounted) {
        setState(() {
          // Store the fetched details
          _companyDetails = stockRequest['requesting_company'];
          _userDetails = stockRequest['user'];
          _productDetails = stockRequest['product'];
          
          // Update the order details with the complete data
          widget.orderDetails.addAll(stockRequest);
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching details: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final formatter = NumberFormat.currency(symbol: '\$');
      
      // Safely get values with null checks
      final quantity = double.tryParse(widget.orderDetails['quantity']?.toString() ?? '0') ?? 0;
      final productPrice = double.tryParse(_productDetails?['price']?.toString() ?? '0') ?? 0;
      final productSellPrice = double.tryParse(_productDetails?['sell_price']?.toString() ?? '0') ?? 0;
      final profit = quantity * (productSellPrice - productPrice);

      return Scaffold(
        appBar: AppBar(
          title: Text('Order #${widget.orderDetails['id'] ?? 'N/A'} Statement'),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _printStatement(context),  // Added context
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Order Information',
                [
                  _buildInfoRow('Status', buildStatusChip(widget.orderDetails['status'] ?? 'unknown')),
                  _buildInfoRow('Order ID', '#${widget.orderDetails['id'] ?? 'N/A'}'),
                  _buildInfoRow('Order Date', _formatDate(widget.orderDetails['order_date'])),
                  if (widget.orderDetails['received_date'] != null)
                    _buildInfoRow('Received Date', _formatDate(widget.orderDetails['received_date'])),
                ],
              ),
              const Divider(),
              _buildSection(
                'Company Information',
                [
                  _buildInfoRow('Company Name', _companyDetails?['company_name'] ?? 'N/A'),
                  _buildInfoRow('Address', _companyDetails?['address'] ?? 'N/A'),
                  _buildInfoRow('Contact Phone', _companyDetails?['contact_phone'] ?? 'N/A'),
                  _buildInfoRow('Email', _companyDetails?['email'] ?? 'N/A'),
                  _buildInfoRow('TIN', _companyDetails?['tin'] ?? 'N/A'),
                ],
              ),
              const Divider(),
              _buildSection(
                'Requester Information',
                [
                  _buildInfoRow('Name', _userDetails?['name'] ?? 'N/A'),
                  _buildInfoRow('Email', _userDetails?['email'] ?? 'N/A'),
                  _buildInfoRow('Phone', _userDetails?['phone'] ?? 'N/A'),
                  _buildInfoRow('Role', _userDetails?['role'] ?? 'N/A'),
                ],
              ),
              const Divider(),
              _buildSection(
                'Product Details',
                [
                  _buildInfoRow('Name', _productDetails?['name'] ?? 'N/A'),
                  _buildInfoRow('Description', _productDetails?['description'] ?? 'N/A'),
                  _buildInfoRow('Barcode', _productDetails?['barcode'] ?? 'N/A'),
                  _buildInfoRow('Stock Quantity', _productDetails?['stock_quantity']?.toString() ?? 'N/A'),
                  _buildInfoRow('Tax Rate', '${_productDetails?['tax_rate']}%' ?? 'N/A'),
                  _buildInfoRow('Quantity Ordered', quantity.toString()),
                  _buildInfoRow('Unit Cost', formatter.format(productPrice)),
                  _buildInfoRow('Unit Price', formatter.format(productSellPrice)),
                ],
              ),
              const Divider(),
              _buildSection(
                'Financial Summary',
                [
                  _buildInfoRow('Total Cost', formatter.format(quantity * productPrice)),
                  _buildInfoRow('Total Revenue', formatter.format(quantity * productSellPrice)),
                  _buildInfoRow('Net Profit', formatter.format(profit),
                    valueColor: profit >= 0 ? Colors.green : Colors.red
                  ),
                ],
              ),
              if (widget.orderDetails['notes']?.toString().isNotEmpty == true) ...[
                const Divider(),
                _buildSection(
                  'Additional Notes',
                  [Text(widget.orderDetails['notes'].toString())],
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Statement')),
        body: Center(
          child: Text('Error loading order details: $e'),
        ),
      );
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(dateStr));
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<void> _printStatement(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing functionality coming soon')),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, dynamic value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: value is Widget 
              ? value 
              : Text(
                  value.toString(),
                  style: TextStyle(color: valueColor),
                ),
          ),
        ],
      ),
    );
  }
} 