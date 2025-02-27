import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';
import 'package:cybrox_kiosk_management/models/stock_order.dart';
import 'package:cybrox_kiosk_management/models/company.dart';
import 'package:cybrox_kiosk_management/models/product.dart';
import 'package:cybrox_kiosk_management/models/audit_data.dart';
import 'package:cybrox_kiosk_management/models/company_account.dart';
import 'package:cybrox_kiosk_management/services/receipt_service.dart';
import 'package:cybrox_kiosk_management/models/finance_record.dart';
import 'package:cybrox_kiosk_management/models/user.dart' as cybrox_user;
import 'package:cybrox_kiosk_management/screens/reports/payment_method_dialog.dart';

class AuditReportScreen extends StatefulWidget {
  final cybrox_user.User? currentUser;

  const AuditReportScreen({
    super.key,
    this.currentUser,
  });

  @override
  State<AuditReportScreen> createState() => _AuditReportScreenState();
}

class _AuditReportScreenState extends State<AuditReportScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;
  List<StockOrder> _stockOrders = [];
  List<Company> _companies = [];
  List<Product> _products = [];
  DateTime? _startDate;
  DateTime? _endDate;
  Company? _selectedCompany;
  Product? _selectedProduct;
  List<AuditData> _auditData = [];
  TextEditingController _varianceController = TextEditingController();
  final TextEditingController _paymentAmountController = TextEditingController();
  List<CompanyAccount> _companyAccountData = [];
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadCompanyAccountData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchCompanies(),
        _fetchProducts(),
        _fetchStockOrders(),
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

  Future<void> _fetchCompanies() async {
    final companies = await _supabaseService.fetchCompanies();
    if (mounted) setState(() => _companies = companies);
  }

  Future<void> _fetchProducts() async {
    final products = await _supabaseService.fetchProducts();
    if (mounted) setState(() => _products = products);
  }

  Future<void> _fetchStockOrders() async {
    final ordersData = await _supabaseService.fetchStockRequests();
    if (mounted) {
      setState(() {
        _stockOrders = ordersData.map((data) => StockOrder.fromJson(data)).toList();
      });
    }
  }

  String _getCompanyName(int id) {
    return _companies.firstWhere((c) => c.id == id, orElse: () => Company(id: -1, name: 'Unknown', address: '', contactPhone: '', email: '', tin: '', isHq: false)).name;
  }

  String _getProductName(int id) {
    return _products.firstWhere(
      (p) => p.id == id, 
      orElse: () => Product(
        name: 'Unknown',
        description: '',
        price: 0,
        barcode: '',
        stockQuantity: 0,
        taxRate: 0,
        sellPrice: 0,
      )
    ).name;
  }

  Map<String, dynamic> _calculateAuditMetrics() {
    double totalValue = 0;
    int totalOrders = 0;
    Map<int, int> productQuantities = {};
    Map<int, double> companyValues = {};

    for (var order in _stockOrders) {
      if (_startDate != null && DateTime.parse(order.orderDate).isBefore(_startDate!)) continue;
      if (_endDate != null && DateTime.parse(order.orderDate).isAfter(_endDate!)) continue;

      double orderValue = order.quantity * order.cost;
      totalValue += orderValue;
      totalOrders++;

      productQuantities[order.productId] = (productQuantities[order.productId] ?? 0) + order.quantity;
      companyValues[order.requestingCompanyId] = (companyValues[order.requestingCompanyId] ?? 0) + orderValue;
    }

    return {
      'totalValue': totalValue,
      'totalOrders': totalOrders,
      'productQuantities': productQuantities,
      'companyValues': companyValues,
    };
  }

  Future<void> _loadAuditData() async {
    try {
      setState(() => _isLoading = true);
      
      final stockRequests = await _supabaseService.fetchStockRequests();
      final stockOrderDetails = await _supabaseService.fetchStockOrdersWithDetails();
      final financeDetails = await _supabaseService.fetchFinanceRecordsWithDetails();

      print('Processing audit data...');
      _auditData = await _processAuditData(
        stockRequests,
        stockOrderDetails,
        financeDetails,
        _selectedCompany?.id,
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading audit data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading audit data: $e')),
        );
      }
    }
  }

  Future<List<AuditData>> _processAuditData(
    List<Map<String, dynamic>> stockRequests,
    List<Map<String, dynamic>> stockOrderDetails,
    List<Map<String, dynamic>> financeDetails,
    int? selectedCompanyId,
  ) async {
    // Convert raw data to StockOrder objects first
    final stockOrdersList = stockRequests.map((data) => StockOrder.fromJson(data)).toList();
    
    // Now use the converted list
    return _calculateAuditData(
      stockOrdersList,
      stockOrderDetails,
      financeDetails,
      selectedCompanyId,
    );
  }

  Future<List<AuditData>> _calculateAuditData(
    List<StockOrder> stockOrders,
    List<Map<String, dynamic>> stockOrderDetails,
    List<Map<String, dynamic>> financeDetails,
    int? companyId,
  ) async {
    print('Processing stock order details:');
    stockOrderDetails.forEach((order) {
      print('Order: ${order['id']}, Product: ${order['products']?['name']}, Quantity: ${order['quantity']}');
    });

    print('Starting _processAuditData');
    print('Inputs: ${stockOrders.length} requests, ${stockOrderDetails.length} orders, ${financeDetails.length} finance records');
    print('Filters: companyId=$companyId');

    List<AuditData> auditEntries = [];

    for (var request in stockOrders) {
      try {
        if (companyId != null && request.requestingCompanyId != companyId) continue;

        print('Processing request ID: ${request.id}');
        
        final product = _products.firstWhere(
          (p) => p.id == request.productId,
          orElse: () {
            print('Product not found for ID: ${request.productId}');
            return Product(
              name: 'Unknown',
              description: '',
              price: 0,
              barcode: '',
              stockQuantity: 0,
              taxRate: 0,
              sellPrice: 0,
            );
          }
        );

        final company = _companies.firstWhere(
          (c) => c.id == request.requestingCompanyId,
          orElse: () {
            print('Company not found for ID: ${request.requestingCompanyId}');
            return Company(id: -1, name: 'Unknown', address: '', contactPhone: '', email: '', tin: '', isHq: false);
          }
        );

        final currentStock = stockOrderDetails
          .where((order) => order['product_id'] == request.productId)
          .fold(0, (sum, order) {
            print('Order quantity for product ${request.productId}: ${order['quantity']}');
            return sum + (order['quantity'] as int);
          });

        print('Current stock for product ${request.productId}: $currentStock');

        // Find matching stock order
        final receivedOrder = stockOrderDetails.firstWhere(
          (order) => 
            order['product_id'] == request.productId && 
            order['company_id'] == request.requestingCompanyId,
          orElse: () => <String, dynamic>{},
        );

        final receivedDate = receivedOrder.isNotEmpty 
          ? DateTime.parse(receivedOrder['order_date'].toString())
          : null;
        final receivedQuantity = receivedOrder.isNotEmpty 
          ? receivedOrder['quantity'] as int
          : 0;

        // Calculate sales (requested - received)
        final totalSales = receivedQuantity > 0 ? receivedQuantity - currentStock : 0;
        
        // Calculate financial metrics with null safety
        final sellPrice = request.sellPrice ?? 0.0;  // Add null check
        final cost = request.cost ?? 0.0;  // Add null check
        
        final grossIncome = totalSales * sellPrice;
        final purchaseCost = receivedQuantity * cost;
        final expectedProfit = grossIncome - purchaseCost;

        print('Updated calculations for request ${request.id}:');
        print('Received quantity: $receivedQuantity');
        print('Total sales: $totalSales');
        print('Expected profit: $expectedProfit');

        // Calculate outstanding amount with null safety
        final outstandingAmount = financeDetails
          .where((record) => 
            record['company_id'] == request.requestingCompanyId && 
            record['product_id'] == request.productId)
          .fold(0.0, (sum, record) {
            final amount = record['amount'];
            return sum + (amount != null ? (amount as num).toDouble() : 0.0);
          });

        auditEntries.add(AuditData(
          productId: request.productId,
          productName: product.name,
          companyId: request.requestingCompanyId,
          companyName: company.name,
          requestDate: DateTime.parse(request.orderDate),
          receivedDate: receivedDate,
          requestedQuantity: request.quantity,
          receivedQuantity: receivedQuantity,
          currentStock: currentStock,
          totalSales: totalSales,
          grossIncome: grossIncome,
          purchaseCost: purchaseCost,
          outstandingAmount: outstandingAmount,
          expectedProfit: expectedProfit,
        ));

      } catch (e, stackTrace) {
        print('Error processing request ${request.id}: $e');
        print('Stack trace: $stackTrace');
      }
    }

    print('Finished processing. Generated ${auditEntries.length} audit entries');
    return auditEntries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Audit Report'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.payment),
            label: const Text('Make Payment'),
            onPressed: _showPaymentDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Audit Report'),
                Tab(text: 'Company Accounts'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // First tab - Audit Report
                  Column(
                    children: [
                      _buildFiltersBar(),
                      Expanded(child: _buildAuditTable()),
                      _buildSummarySection(),
                    ],
                  ),
                  // Second tab - Company Accounts
                  _buildCompanyAccountsTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<Company>(
              value: _selectedCompany,
              items: _companies.map((company) {
                return DropdownMenuItem(
                  value: company,
                  child: Text(company.name),
                );
              }).toList(),
              onChanged: (Company? value) {
                setState(() {
                  _selectedCompany = value;
                  _loadAuditData();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Filter by Company',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<Product>(
              value: _selectedProduct,
              items: _products.map((product) {
                return DropdownMenuItem(
                  value: product,
                  child: Text(product.name),
                );
              }).toList(),
              onChanged: (Product? value) {
                setState(() {
                  _selectedProduct = value;
                  _loadAuditData();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Filter by Product',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTable() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 12,
            headingRowHeight: 40,
            dataRowHeight: 48,
            columns: const [
              DataColumn(
                label: Expanded(
                  child: Text('Company', 
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Product',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Req Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Req Qty',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Rcv Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Rcv Qty',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Stock',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Sales',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Income',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Cost',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Due',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Expanded(
                  child: Text('Exp. Profit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                numeric: true,
              ),
            ],
            rows: _auditData.map((data) {
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        data.companyName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        data.productName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(DateFormat('MM/dd/yy').format(data.requestDate))),
                  DataCell(Text(data.requestedQuantity.toString())),
                  DataCell(Text(data.receivedDate != null 
                    ? DateFormat('MM/dd/yy').format(data.receivedDate!)
                    : '-')),
                  DataCell(Text(data.receivedQuantity?.toString() ?? '-')),
                  DataCell(Text(data.currentStock.toString())),
                  DataCell(Text(data.totalSales.toString())),
                  DataCell(Text('\$${data.grossIncome.toStringAsFixed(0)}')),
                  DataCell(Text('\$${data.purchaseCost.toStringAsFixed(0)}')),
                  DataCell(Text('\$${data.outstandingAmount.toStringAsFixed(0)}')),
                  DataCell(Text('\$${data.expectedProfit.toStringAsFixed(0)}')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showVarianceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Stock Variance'),
        content: TextField(
          controller: _varianceController,
          decoration: const InputDecoration(
            labelText: 'Enter variance amount',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save variance
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date Range'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                Navigator.pop(context);
                DateTimeRange? dateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  currentDate: DateTime.now(),
                );
                if (dateRange != null && mounted) {
                  setState(() {
                    _startDate = dateRange.start;
                    _endDate = dateRange.end;
                    _loadAuditData();
                  });
                }
              },
            ),
            ListTile(
              title: const Text('Clear Filters'),
              trailing: const Icon(Icons.clear),
              onTap: () {
                setState(() {
                  _selectedCompany = null;
                  _selectedProduct = null;
                  _startDate = null;
                  _endDate = null;
                  _loadAuditData();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    if (_auditData.isEmpty) return const SizedBox.shrink();

    final totalGrossIncome = _auditData.fold(0.0, (sum, data) => sum + data.grossIncome);
    final totalPurchaseCost = _auditData.fold(0.0, (sum, data) => sum + data.purchaseCost);
    final totalOutstanding = _auditData.fold(0.0, (sum, data) => sum + data.outstandingAmount);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Gross Income', totalGrossIncome),
            _buildSummaryItem('Purchase Cost', totalPurchaseCost),
            _buildSummaryItem('Outstanding', totalOutstanding),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('\$${value.toStringAsFixed(2)}'),
      ],
    );
  }

  Future<void> _loadCompanyAccountData() async {
    try {
      setState(() => _isLoading = true);

      // Fetch all finance records
      final financeRecords = await _supabaseService.supabase
          .from('finance')
          .select('''
            id,
            amount,
            created_at,
            company:company_details(
              id,
              company_name
            )
          ''')
          .order('created_at');

      // Fetch stock requests (invoices)
      final stockRequests = await _supabaseService.supabase
          .from('stock_requests')
          .select('''
            id,
            quantity,
            cost,
            order_date,
            requesting_company:company_details!requesting_company_id(
              id,
              company_name
            )
          ''')
          .order('order_date');

      // Combine all transactions
      List<Map<String, dynamic>> allTransactions = [];
      
      // Add all finance records as payments
      allTransactions.addAll(financeRecords.map((rec) => {
        'date': DateTime.parse(rec['created_at']),
        'companyId': rec['company']['id'],
        'companyName': rec['company']['company_name'],
        'type': 'Payment',
        'reference': 'RCP#${rec['id']}',
        'debit': 0.0,
        'credit': double.parse(rec['amount'].toString()),
        'isPayment': true,
      }));

      // Add invoices
      allTransactions.addAll(stockRequests.map((req) => {
        'date': DateTime.parse(req['order_date']),
        'companyId': req['requesting_company']['id'],
        'companyName': req['requesting_company']['company_name'],
        'type': 'Invoice',
        'reference': 'INV#${req['id']}',
        'debit': double.parse(req['quantity'].toString()) * double.parse(req['cost'].toString()),
        'credit': 0.0,
        'isPayment': false,
      }));

      // Sort by date ascending first for balance calculation
      allTransactions.sort((a, b) => a['date'].compareTo(b['date']));

      // Calculate running balances per company
      Map<int, double> companyRunningBalances = {};
      List<CompanyAccount> accountEntries = [];

      for (var transaction in allTransactions) {
        final companyId = transaction['companyId'];
        final currentBalance = companyRunningBalances[companyId] ?? 0.0;
        
        // Update running balance (debit increases, credit decreases)
        final newBalance = currentBalance + transaction['debit'] - transaction['credit'];
        companyRunningBalances[companyId] = newBalance;

        accountEntries.add(CompanyAccount(
          companyName: transaction['companyName'],
          invoiceDate: transaction['date'],
          invoiceNumber: transaction['type'] == 'Invoice' ? 
            int.parse(transaction['reference'].substring(4)) : null,
          receiptNumber: transaction['isPayment'] ? 
            int.parse(transaction['reference'].substring(4)) : null,
          orderCost: transaction['debit'],
          amountPaid: transaction['credit'],
          balance: newBalance,
          transactionType: transaction['type'],
        ));
      }

      // Sort by date descending for display (newest first)
      accountEntries.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

      setState(() {
        _companyAccountData = accountEntries;
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading company account data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading account data: $e')),
        );
      }
    }
  }

  Future<void> _printReceipt({
    required int receiptNumber,
    required String companyName,
    required double amount,
    required double balance,
  }) async {
    try {
      await ReceiptService.generateAndPrintReceipt(
        receiptNumber: receiptNumber,
        companyName: companyName,
        amount: amount,
        balance: balance,
      );
    } catch (e) {
      print('Error generating receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating receipt: $e')),
      );
    }
  }

  Widget _buildCompanyAccountsTable() {
    return Column(
      children: [
        // Company filter dropdown
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Company>(
                  value: _selectedCompany,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Company',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<Company>(
                      value: null,
                      child: Text('All Companies'),
                    ),
                    ..._companies.map((company) => DropdownMenuItem(
                      value: company,
                      child: Text(company.name),
                    )),
                  ],
                  onChanged: (Company? value) {
                    setState(() => _selectedCompany = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Add payment button
              ElevatedButton.icon(
                onPressed: _showPaymentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Record Payment'),
              ),
            ],
          ),
        ),
        // Accounts table
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Company')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Invoice #'), numeric: true),
                    DataColumn(label: Text('Receipt #'), numeric: true),
                    DataColumn(label: Text('Debit'), numeric: true),
                    DataColumn(label: Text('Credit'), numeric: true),
                    DataColumn(label: Text('Balance'), numeric: true),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _companyAccountData
                    .where((account) => _selectedCompany == null || 
                      account.companyName == _selectedCompany!.name)
                    .map((account) {
                      final isPayment = account.transactionType == 'Payment';
                      return DataRow(
                        cells: [
                          DataCell(Text(DateFormat('MM/dd/yy').format(account.invoiceDate))),
                          DataCell(Text(account.companyName)),
                          DataCell(Text(account.transactionType)),
                          DataCell(Text(account.invoiceNumber != null ? 
                            account.invoiceNumber.toString() : '-')),
                          DataCell(Text(account.receiptNumber != null ? 
                            account.receiptNumber.toString() : '-')),
                          DataCell(Text(account.orderCost > 0 
                            ? currencyFormat.format(account.orderCost)
                            : '-')),
                          DataCell(Text(account.amountPaid > 0
                            ? currencyFormat.format(account.amountPaid)
                            : '-')),
                          DataCell(
                            Text(
                              currencyFormat.format(account.balance),
                              style: TextStyle(
                                color: account.balance > 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            isPayment ? IconButton(
                              icon: const Icon(Icons.print),
                              onPressed: () => _printReceipt(
                                receiptNumber: account.receiptNumber!,
                                companyName: account.companyName,
                                amount: account.amountPaid,
                                balance: account.balance,
                              ),
                            ) : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentFormDialog(
        currentUser: widget.currentUser,
        onPaymentComplete: () {
          _loadCompanyAccountData();  // Refresh data after payment
        },
      ),
    );
  }
} 