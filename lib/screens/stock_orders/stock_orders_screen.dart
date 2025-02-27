import 'dart:io';


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sunmi_printer_plus/core/sunmi/sunmi_printer.dart';

  // For SunmiPrintAlign and SunmiFontSize

import 'package:cybrox_kiosk_management/models/company.dart';
import 'package:cybrox_kiosk_management/models/product.dart';
import 'package:cybrox_kiosk_management/models/stock_order.dart';
import 'package:cybrox_kiosk_management/models/user.dart' as cybrox_user;
import 'package:cybrox_kiosk_management/services/shared_prefs_services.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';
import 'package:cybrox_kiosk_management/services/printer_service.dart';

// Add these enums
enum SunmiPrintAlign { LEFT, CENTER, RIGHT, center }
enum SunmiFontSize { SM, MD, LG, XL, SMALL }

// Our custom style implementation
class SunmiTextStyle {
  final bool? bold;
  final bool? italic;
  final SunmiPrintAlign? align;
  final SunmiFontSize? fontSize;

  const SunmiTextStyle({this.bold, this.italic, this.align, this.fontSize});
}

// Add this extension to handle the style conversion
extension SunmiTextStyleExt on SunmiTextStyle {
  dynamic toMap() => {
    'bold': bold,
    'italic': italic,
    'align': align?.index,
    'fontSize': fontSize?.index,
  };
}

class StockOrderScreen extends StatefulWidget {
  final cybrox_user.User? currentUser;
  
  const StockOrderScreen({
    super.key,
    required this.currentUser,
  });

  static const routeName = '/stock_order';

  @override
  _StockOrderScreenState createState() => _StockOrderScreenState();
}

class _StockOrderScreenState extends State<StockOrderScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final SharedPreferencesService _sharedPreferencesService = SharedPreferencesService();
  List<StockOrder> _stockOrders = [];
  List<Product> _products = [];
  List<Company> _companies = [];
  bool _isLoading = false;
  bool _isAdmin = false;
  String _filterStatus = 'all'; // Default filter
  int? _filterCompanyId; // Default company filter (null means no filter)
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  Map<int, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchProducts(),
        _fetchCompanies(),
        _fetchStockRequests(),
        _checkUserRole(),
        _fetchUserNames(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _checkUserRole() async {
    final user = await _sharedPreferencesService.getUserData();
    if (user != null) {
      final isAdmin = user.role == 'admin';
      if (mounted) setState(() => _isAdmin = isAdmin);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error retrieving user data')),
        );
      }
    }
  }

  Future<void> _fetchProducts() async {
    final products = await _supabaseService.fetchProducts();
    if (mounted) setState(() => _products = products);
  }

  Future<void> _fetchCompanies() async {
    final companies = await _supabaseService.fetchCompanies();
    if (mounted) setState(() => _companies = companies);
  }

  Future<void> _fetchStockRequests() async {
    try {
      final requestsData = await _supabaseService.fetchStockRequests();
      if (mounted) {
        setState(() {
          _stockOrders = requestsData.map((data) => StockOrder.fromJson(data)).toList();
        });
      }
    } catch (e) {
      print('Error fetching stock requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stock requests: $e')),
        );
      }
    }
  }

  Future<void> _fetchUserNames() async {
    try {
      final users = await _supabaseService.fetchUsers();
      setState(() {
        _userNames = {
          for (var user in users)
            user.id: user.name
        };
      });
    } catch (e) {
      print('Error fetching user names: $e');
    }
  }

  String _getCompanyNameById(int companyId) {
    try {
      return _companies.firstWhere((c) => c.id == companyId).name;
    } catch (e) {
      return 'Unknown Company';
    }
  }

  Future<void> _printInvoice(StockOrder order) async {
    try {
      final companyName = _getCompanyNameById(order.requestingCompanyId);
      final productName = Product.getProductNameById(order.productId, _products);
      final total = order.cost * order.quantity;

      final data = {
        'Order #': order.id,
        'Date': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        'Company': companyName,
        'Product': productName,
        'Quantity': order.quantity,
        'Unit Cost': '\$${order.cost.toStringAsFixed(2)}',
        'Total Cost': '\$${total.toStringAsFixed(2)}',
        'Payment Method': 'Credited',
      };

      await PrinterService.printDocument(
        title: 'INVOICE',
        data: data,
        isInvoice: true,
      );

    } catch (e) {
      print('Error printing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing document: $e')),
        );
      }
    }
  }

  Future<void> _printGRV(StockOrder order) async {
    try {
      await SunmiPrinter.startTransactionPrint(true);
      
      // Header
      await SunmiPrinter.printText(
        'Kiosk HQ Office\n',
        style: SunmiTextStyle(
          bold: true,
          align: SunmiPrintAlign.CENTER,
          fontSize: SunmiFontSize.LG
        ).toMap(),
      );
      await SunmiPrinter.lineWrap(2);
      
      // GRV Title
      await SunmiPrinter.printText(
        'GOODS RECEIVED VOUCHER\n',
        style: SunmiTextStyle(
          bold: true,
          align: SunmiPrintAlign.CENTER,
          fontSize: SunmiFontSize.XL
        ).toMap(),
      );
      await SunmiPrinter.lineWrap(2);

      final companyName = _getCompanyNameById(order.requestingCompanyId);
      final productName = Product.getProductNameById(order.productId, _products);
      final total = order.cost * order.quantity;
      
      // Order Details
      await SunmiPrinter.printText(
        'GRV #: ${order.id}\n' +
        'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n' +
        'Company: $companyName\n' +
        'Product: $productName\n' +
        'Quantity: ${order.quantity}\n' +
        'Unit Cost: \$${order.cost.toStringAsFixed(2)}\n' +
        'Total Cost: \$${total.toStringAsFixed(2)}\n',
        style: SunmiTextStyle(fontSize: SunmiFontSize.MD).toMap(),
      );
      await SunmiPrinter.lineWrap(3);

      // GRV Note
      await SunmiPrinter.printText(
        'Stock Received\n',
        style: SunmiTextStyle(
          bold: true,
          fontSize: SunmiFontSize.MD
        ).toMap(),
      );
      await SunmiPrinter.lineWrap(2);

      // Footer
      await SunmiPrinter.printText(
        'Kiosk Management System\npowered by Cybrox-AllanWebApp\n',
        style: SunmiTextStyle(
          italic: true,
          align: SunmiPrintAlign.CENTER,
          fontSize: SunmiFontSize.SM
        ).toMap(),
      );

      await SunmiPrinter.cut();
    } catch (e) {
      print('Error printing GRV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing GRV: $e')),
        );
      }
    }
  }

  Future<void> _handleStatusChange(StockOrder order, String newStatus) async {
    try {
      // Update the status
      await _supabaseService.supabase
          .from('stock_requests')
          .update({
            'status': newStatus,
            'received_date': newStatus == 'received' ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', order.id);

      // Print appropriate document
      if (newStatus == 'delivered') {
        await _printInvoice(order);
      } else if (newStatus == 'received') {
        await _printGRV(order);
      }

      // Refresh the data
      await _fetchStockRequests();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked as $newStatus')),
        );
      }
    } catch (e) {
      print('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order status: $e')),
        );
      }
    }
  }

  Future<void> _showStatusConfirmation(StockOrder order, String newStatus) async {
    final isDelivery = newStatus == 'delivered';
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDelivery ? 'Confirm Delivery' : 'Confirm Receipt'),
        content: Text(isDelivery
            ? 'Are you sure you want to mark this order as delivered?'
            : 'Have you received and verified the stock?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleStatusChange(order, newStatus);
            },
            child: Text(isDelivery ? 'Mark Delivered' : 'Confirm Receipt'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'delivered':
        color = Colors.blue;
        break;
      case 'received':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton(StockOrder order) {
    if (_isAdmin) {
      if (order.status == 'pending') {
        return IconButton(
          icon: const Icon(Icons.delivery_dining, color: Colors.blue),
          onPressed: () => _showStatusConfirmation(order, 'delivered'),
        );
      }
    } else {
      if (order.status == 'delivered') {
        return IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: () => _showStatusConfirmation(order, 'received'),
        );
      }
    }
    
    // Add reprint button for received orders
    if (order.status == 'received') {
      return IconButton(
        icon: const Icon(Icons.print, color: Colors.grey),
        tooltip: 'Reprint Invoice and GRV',
        onPressed: () => _reprintDocuments(order),
      );
    }
    
    return const SizedBox.shrink();
  }

  Future<void> _reprintDocuments(StockOrder order) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printing documents...')),
      );
      
      // Print both documents
      await _printInvoice(order);
      await _printGRV(order);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents reprinted successfully')),
        );
      }
    } catch (e) {
      print('Error reprinting documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reprinting documents: $e')),
        );
      }
    }
  }

  Widget _buildOrdersTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DataTable(
          border: TableBorder.all(
            color: Colors.grey.shade200,
            width: 1,
            borderRadius: BorderRadius.circular(8),
          ),
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columnSpacing: 20,
          horizontalMargin: 16,
          columns: const [
            DataColumn(label: Text('Order No', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Company', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Requested By', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _stockOrders.map((order) {
            final companyName = _getCompanyNameById(order.requestingCompanyId);
            final productName = Product.getProductNameById(order.productId, _products);
            final total = order.cost * order.quantity;

            return DataRow(
              cells: [
                DataCell(Text('#${order.id}')),
                DataCell(Text(companyName)),
                DataCell(Text(productName)),
                DataCell(Text(order.quantity.toString())),
                DataCell(Text('\$${order.cost.toStringAsFixed(2)}')),
                DataCell(Text('\$${total.toStringAsFixed(2)}')),
                DataCell(_buildStatusBadge(order.status)),
                DataCell(Text(_userNames[order.userId] ?? 'Unknown')),
                DataCell(_buildActionButton(order)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButton<String>(
      value: _filterStatus,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Orders')),
        DropdownMenuItem(value: 'pending', child: Text('Pending')),
        DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
        DropdownMenuItem(value: 'received', child: Text('Received')),
      ],
      onChanged: (value) {
        setState(() {
          _filterStatus = value!;
          //clear widget onpressed highlight state
          FocusScope.of(context).requestFocus(FocusNode());
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Stock Order Management' : 'My Stock Orders'),
        actions: [
          IconButton(
            onPressed: 
            Platform.isMacOS ? 
              _printTableOnMac :
              _printTable, 
            icon: Icon(Icons.print),
          ),
          const SizedBox(width: 16),
          _buildFilterDropdown(),
          const SizedBox(width: 16),
         _buildCompanyFilterDropdown(), //
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildOrdersTable(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockRequestDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCompanyFilterDropdown() {
    return DropdownButton<int>(
      value: _filterCompanyId,
      hint: Text('Filter by Company'), // Hint text when no company is selected
      items: [
        DropdownMenuItem<int>(
          value: null, // Reset filter
          child: Text('All Companies'),
        ),
        ..._companies.map((company) {
          return DropdownMenuItem<int>(
            value: company.id,
            child: Text(company.name),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _filterCompanyId = value; // Update the selected company filter
            FocusScope.of(context).requestFocus(FocusNode());
        });
      },
    );
  }

  void _showAddStockRequestDialog() {
    if (widget.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create stock requests')),
      );
      return;
    }

    // Store the parent context

    showDialog(
      context: context,
      builder: (context) => AddStockRequestDialog(
        products: _products,
        companies: _companies,
        onSubmit: _handleAddStockRequest,
        currentUser: widget.currentUser!,
        supabaseService: _supabaseService,
      ),
    );
  }

  Future<void> _printTable() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Header row
                pw.TableRow(
                  children: [
                    pw.Text('Order No'),
                    pw.Text('Company'),
                    pw.Text('Product'),
                    pw.Text('Quantity'),
                    pw.Text('Cost'),
                    pw.Text('Total'),
                    pw.Text('Status'),
                  ],
                ),
                // Data rows
                ..._stockOrders.map((order) {
                  final companyName = _getCompanyNameById(order.requestingCompanyId);
                  final productName = Product.getProductNameById(order.productId, _products);
                  final total = order.cost * order.quantity;

                  return pw.TableRow(
                    children: [
                      pw.Text('#${order.id}'),
                      pw.Text(companyName),
                      pw.Text(productName),
                      pw.Text(order.quantity.toString()),
                      pw.Text('\$${order.cost.toStringAsFixed(2)}'),
                      pw.Text('\$${total.toStringAsFixed(2)}'),
                      pw.Text(order.status.toUpperCase()),
                    ],
                  );
                }).toList(),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'stock_orders_report.pdf',
      );
    } catch (e) {
      print('Error printing table: $e');
    }
  }

  Future<void> _printTableOnMac() async {
    try {
      final pdf = pw.Document();
      
      // Add macOS-specific page settings
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginTop: 1.0 * PdfPageFormat.cm,
            marginBottom: 1.0 * PdfPageFormat.cm,
            marginLeft: 1.0 * PdfPageFormat.cm,
            marginRight: 1.0 * PdfPageFormat.cm,
          ),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Stock Orders Report', 
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold
                    )
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Table header
                  pw.TableRow(
                    children: [
                      pw.Text('Order No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Company', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Cost', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Table rows
                  ..._stockOrders.map((order) {
                    final companyName = _getCompanyNameById(order.requestingCompanyId);
                    final productName = Product.getProductNameById(order.productId, _products);
                    final total = order.cost * order.quantity;

                    return pw.TableRow(
                      children: [
                        pw.Text('#${order.id}'),
                        pw.Text(companyName),
                        pw.Text(productName),
                        pw.Text(order.quantity.toString()),
                        pw.Text('\$${order.cost.toStringAsFixed(2)}'),
                        pw.Text('\$${total.toStringAsFixed(2)}'),
                        pw.Text(order.status.toUpperCase()),
                      ],
                    );
                  }),
                ],
              ),
              ],
            );
          },
        ),
      );

      // For macOS, you might want to show the print preview first
      final result = await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'stock_orders_report.pdf',
        format: PdfPageFormat.a4,
        usePrinterSettings: true,  // Important for macOS
      );

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document printed successfully')),
        );
      }

    } catch (e) {
      print('Printing error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error printing document: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleAddStockRequest(StockOrder stockRequest) async {
    try {
      await _supabaseService.addStockRequest(stockRequest);
      await _fetchStockRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock request added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding stock request: $e')),
      );
    }
  }

}

// Separate dialog widget for better state management
class AddStockRequestDialog extends StatefulWidget {
  final List<Product> products;
  final List<Company> companies;
  final Function(StockOrder) onSubmit;
  final cybrox_user.User currentUser;
  final SupabaseService supabaseService;

  const AddStockRequestDialog({
    super.key,
    required this.products,
    required this.companies,
    required this.onSubmit,
    required this.currentUser,
    required this.supabaseService,
  });

  @override
  _AddStockRequestDialogState createState() => _AddStockRequestDialogState();
}

class _AddStockRequestDialogState extends State<AddStockRequestDialog> {
  bool _isSubmitting = false;  // Add this
  Product? selectedProduct;
  Company? selectedCompany;
  final quantityController = TextEditingController(text: '1');
  final sellPriceController = TextEditingController();
  double totalCost = 0.0;
  double totalTax = 0.0;
  double netIncome = 0.0;
  double marginProfit = 0.0;

  @override
  void initState() {
    super.initState();
    // Pre-select the user's company
    if (widget.currentUser.companyId != null) {
      selectedCompany = widget.companies.firstWhere(
        (company) => company.id == widget.currentUser.companyId,
        orElse: () => widget.companies.first,
      );
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    sellPriceController.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    if (selectedProduct == null) return;

    final quantity = int.tryParse(quantityController.text) ?? 1;
    final sellPrice = double.tryParse(sellPriceController.text) ?? 0.0;

    setState(() {
      totalCost = selectedProduct!.cost * quantity;
      totalTax = selectedProduct!.taxRate / 100 * totalCost;
      marginProfit = (sellPrice * quantity) - (totalCost + totalTax);
      netIncome = sellPrice * quantity;
    });
  }

  void _handleSubmit() async {
    if (!mounted) return;
    
    if (selectedProduct == null || selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product and company')),
      );
      return;
    }

    // Validate quantity and sell price
    int quantity;
    double sellPrice;
    try {
      quantity = int.parse(quantityController.text);
      if (quantity <= 0) throw FormatException('Quantity must be positive');
      
      sellPrice = double.parse(sellPriceController.text);
      if (sellPrice <= 0) throw FormatException('Sell price must be positive');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity and sell price')),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      final response = await widget.supabaseService.supabase
          .from('stock_requests')
          .insert({
            'user_id': widget.currentUser.id,
            'requesting_company_id': selectedCompany!.id,
            'fulfilling_company_id': selectedCompany!.id,
            'product_id': selectedProduct!.id!,
            'quantity': quantity,
            'cost': selectedProduct!.cost.toDouble(),
            'sell_price': sellPrice,
            'status': 'pending',
            'order_date': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final stockRequest = StockOrder.fromJson(response);
      widget.onSubmit(stockRequest);
      Navigator.pop(context);

    } catch (e) {
      print('Error submitting stock request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Stock Request'),
      content: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  items: widget.products.map((product) {
                    return DropdownMenuItem<Product>(
                      value: product,
                      child: Text(product.name),
                    );
                  }).toList(),
                  onChanged: _isSubmitting ? null : (Product? value) {
                    setState(() {
                      selectedProduct = value;
                      _updateCalculations();
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Product'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Company>(
                  value: selectedCompany,
                  items: widget.companies.map((company) {
                    return DropdownMenuItem<Company>(
                      value: company,
                      child: Text(company.name),
                      enabled: company.id == widget.currentUser.companyId,
                    );
                  }).toList(),
                  onChanged: _isSubmitting || widget.currentUser.role != 'admin'
                    ? null 
                    : (Company? value) {
                        setState(() => selectedCompany = value);
                      },
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onChanged: _isSubmitting ? null : (_) => _updateCalculations(),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sellPriceController,
                  decoration: const InputDecoration(labelText: 'Sell Price'),
                  keyboardType: TextInputType.number,
                  onChanged: _isSubmitting ? null : (_) => _updateCalculations(),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Cost: \$${totalCost.toStringAsFixed(2)}'),
                      Text('Tax (${selectedProduct?.taxRate ?? 0}%): \$${totalTax.toStringAsFixed(2)}'),
                      Text('Margin Profit: \$${marginProfit.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: marginProfit >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Net Income: \$${netIncome.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting 
            ? const Text('Submitting...')
            : const Text('Add'),
        ),
      ],
    );
  }
}