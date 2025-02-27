// stock_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cybrox_kiosk_management/screens/reports/order_statement_screen.dart';
import 'package:cybrox_kiosk_management/widgets/status_chip.dart';

class StockRequestsDashboard extends StatefulWidget {
  final SupabaseClient supabaseClient;

  const StockRequestsDashboard({
    super.key,
    required this.supabaseClient,
  });

  @override
  State<StockRequestsDashboard> createState() => _StockRequestsDashboardState();
}

class _StockRequestsDashboardState extends State<StockRequestsDashboard> {
  bool isLoading = true;
  List<Map<String, dynamic>> stockRequests = [];
  List<Map<String, dynamic>> companies = [];
  List<Map<String, dynamic>> products = [];
  Map<String, dynamic> summaryStats = {
    'totalOrders': 0,
    'totalValue': 0.0,
    'statusCount': <String, int>{},
    'productCount': <String, int>{},
  };
  List<FlSpot> salesTrendData = [];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      setState(() => isLoading = true);
      
      // Fetch stock requests with all needed relations
      final stockRequestsResponse = await widget.supabaseClient
          .from('stock_requests')
          .select('''
            id,
            quantity,
            status,
            cost,
            sell_price,
            order_date,
            received_date,
            requesting_company:company_details!requesting_company_id(
              id, 
              company_name
            ),
            product:products!product_id(
              id,
              name,
              price,
              sell_price
            )
          ''')
          .order('order_date', ascending: false);

      // Fetch companies (excluding HQ)
      final companiesResponse = await widget.supabaseClient
          .from('company_details')
          .select()
          .eq('is_hq', false);

      // Fetch products
      final productsResponse = await widget.supabaseClient
          .from('products')
          .select();

      if (mounted) {
        setState(() {
          stockRequests = List<Map<String, dynamic>>.from(stockRequestsResponse);
          companies = List<Map<String, dynamic>>.from(companiesResponse);
          products = List<Map<String, dynamic>>.from(productsResponse);
          calculateMetrics();
          calculateSalesTrends();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
    }
  }

  void calculateMetrics() {
    double receivedProfit = 0;
    double expectedProfit = 0;
    int receivedCount = 0;
    Map<String, int> statusCount = {};

    // Calculate expected profit from all products first
    for (var product in products) {
      try {
        double productPrice = double.parse(product['price']?.toString() ?? '0');
        double productSellPrice = double.parse(product['sell_price']?.toString() ?? '0');
        int stockQuantity = int.parse(product['stock_quantity']?.toString() ?? '0');
        
        // Calculate potential profit for this product's total stock
        double productProfit = stockQuantity * (productSellPrice - productPrice);
        expectedProfit += productProfit;
      } catch (e) {
        print('Error calculating product profit: $e');
        continue;
      }
    }

    // Calculate received profit from fulfilled stock requests
    for (var request in stockRequests) {
      try {
        double quantity = double.parse(request['quantity']?.toString() ?? '0');
        String status = request['status'] ?? 'unknown';
        
        // Get product's actual prices from products table
        double productPrice = double.parse(request['product']?['price']?.toString() ?? '0');
        double productSellPrice = double.parse(request['product']?['sell_price']?.toString() ?? '0');
        
        // Calculate profit using product's actual prices
        double profit = quantity * (productSellPrice - productPrice);
        
        // Update status count
        statusCount[status] = (statusCount[status] ?? 0) + 1;

        // Add to received profit if status is received
        if (status.toLowerCase() == 'received') {
          receivedProfit += profit;
          receivedCount++;
        }
      } catch (e) {
        print('Error calculating request profit: $e');
        continue;
      }
    }

    summaryStats = {
      'totalOrders': stockRequests.length,
      'receivedProfit': receivedProfit,
      'expectedProfit': expectedProfit,
      'statusCount': statusCount,
    };
  }

  void calculateSalesTrends() {
    Map<String, double> dailySales = {};
    for (var sale in stockRequests) {
      String date = DateTime.parse(sale['order_date']).toString().split(' ')[0];
      double amount = double.parse(sale['quantity']?.toString() ?? '0') * 
                     double.parse(sale['sell_price']?.toString() ?? '0');
      dailySales[date] = (dailySales[date] ?? 0) + amount;
    }

    var sortedDates = dailySales.keys.toList()..sort();
    salesTrendData = List.generate(sortedDates.length, (i) {
      return FlSpot(i.toDouble(), dailySales[sortedDates[i]]!);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stock Requests Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildSummaryCards(),
              const SizedBox(height: 24),
              _buildStatusDistribution(),
              const SizedBox(height: 24),
              _buildStockRequestsTable(),
              const SizedBox(height: 24),
              _buildChartSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final formatter = NumberFormat.currency(symbol: '\$');
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return GridView.count(
      crossAxisCount: isSmallScreen ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: isSmallScreen ? 1.2 : 1.5,
      children: [
        _buildSummaryCard(
          'Total Orders',
          summaryStats['totalOrders'].toString(),
          Colors.blue,
          isSmallScreen,
        ),
        _buildSummaryCard(
          'Received Profit',
          formatter.format(summaryStats['receivedProfit']),
          Colors.green,
          isSmallScreen,
        ),
        _buildSummaryCard(
          'Expected Profit',
          formatter.format(summaryStats['expectedProfit']),
          Colors.orange,
          isSmallScreen,
        ),
        _buildSummaryCard(
          'Companies',
          companies.length.toString(),
          Colors.purple,
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, bool isSmallScreen) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockRequestsTable() {
    final formatter = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 4,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Order ID')),
            DataColumn(label: Text('Company')),
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Quantity')),
            DataColumn(label: Text('Cost')),
            DataColumn(label: Text('Selling Price')),
            DataColumn(label: Text('Profit')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: stockRequests.take(10).map((request) {
            double quantity = double.parse(request['quantity']?.toString() ?? '0');
            double productPrice = double.parse(request['product']?['price']?.toString() ?? '0');
            double productSellPrice = double.parse(request['product']?['sell_price']?.toString() ?? '0');
            double profit = quantity * (productSellPrice - productPrice);

            return DataRow(
              cells: [
                DataCell(Text(request['id'].toString())),
                DataCell(Text(request['requesting_company']['company_name'])),
                DataCell(Text(request['product']['name'])),
                DataCell(Text(quantity.toString())),
                DataCell(Text(formatter.format(productPrice))),
                DataCell(Text(formatter.format(productSellPrice))),
                DataCell(
                  Text(
                    formatter.format(profit),
                    style: TextStyle(
                      color: profit >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(_buildStatusChip(request['status'])),
                DataCell(
                  TextButton(
                    onPressed: () => _showOrderStatement(request),
                    child: const Text('View Statement'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showOrderStatement(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderStatementScreen(orderDetails: order),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return buildStatusChip(status);
  }

  Widget _buildChartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('\$${value.toInt()}');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return Text('${value.toInt()}d');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: salesTrendData,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildStatusPieSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildStatusPieSections() {
    final Map<String, int> statusCount = summaryStats['statusCount'] as Map<String, int>;
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    
    var entries = statusCount.entries.toList();
    return List.generate(entries.length, (i) {
      final entry = entries[i];
      final percent = (entry.value / summaryStats['totalOrders'] * 100);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n${percent.toStringAsFixed(1)}%',
        color: colors[i % colors.length],
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}

class AccountStatementWidget extends StatefulWidget {
  final int orderId;

  const AccountStatementWidget({super.key, required this.orderId});

  @override
  State<AccountStatementWidget> createState() => _AccountStatementWidgetState();
}

class _AccountStatementWidgetState extends State<AccountStatementWidget> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final response = await _supabaseClient
          .from('stock_requests')
          .select('''
            *,
            requesting_company:company_details!requesting_company_id(company_name),
            fulfilling_company:company_details!fulfilling_company_id(company_name),
            product:products!product_id(name, description, stock_quantity),
            user:users!user_id(name, email)
          ''')
          .eq('id', widget.orderId)
          .single();

      setState(() {
        _orderDetails = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching order details: $e')),
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

    if (_orderDetails == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Order #${widget.orderId}')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final formatter = NumberFormat.currency(symbol: '\$');
    final quantity = _orderDetails!['quantity'];
    final sellPrice = double.parse(_orderDetails!['sell_price'].toString());
    final cost = double.parse(_orderDetails!['cost'].toString());
    final grossIncome = quantity * sellPrice;
    final totalCost = quantity * cost;
    final netProfit = grossIncome - totalCost;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printStatement(),
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
                _buildInfoRow('Status', buildStatusChip(_orderDetails!['status'])),
                _buildInfoRow('Order Date', 
                  DateFormat('yyyy-MM-dd HH:mm').format(
                    DateTime.parse(_orderDetails!['order_date'])
                  )
                ),
                if (_orderDetails!['received_date'] != null)
                  _buildInfoRow('Received Date', 
                    DateFormat('yyyy-MM-dd HH:mm').format(
                      DateTime.parse(_orderDetails!['received_date'])
                    )
                  ),
              ],
            ),
            const Divider(),
            _buildSection(
              'Product Details',
              [
                _buildInfoRow('Product', _orderDetails!['product']['name']),
                _buildInfoRow('Description', _orderDetails!['product']['description']),
                _buildInfoRow('Quantity', quantity.toString()),
                _buildInfoRow('Unit Cost', formatter.format(cost)),
                _buildInfoRow('Unit Price', formatter.format(sellPrice)),
              ],
            ),
            const Divider(),
            _buildSection(
              'Company Information',
              [
                _buildInfoRow('Requesting Company', 
                  _orderDetails!['requesting_company']['company_name']
                ),
                if (_orderDetails!['fulfilling_company'] != null)
                  _buildInfoRow('Fulfilling Company', 
                    _orderDetails!['fulfilling_company']['company_name']
                  ),
              ],
            ),
            const Divider(),
            _buildSection(
              'Financial Summary',
              [
                _buildInfoRow('Gross Income', formatter.format(grossIncome)),
                _buildInfoRow('Total Cost', formatter.format(totalCost)),
                _buildInfoRow('Net Profit', formatter.format(netProfit), 
                  valueColor: netProfit >= 0 ? Colors.green : Colors.red
                ),
              ],
            ),
            if (_orderDetails!['notes']?.isNotEmpty == true) ...[
              const Divider(),
              _buildSection(
                'Notes',
                [Text(_orderDetails!['notes'])],
              ),
            ],
          ],
        ),
      ),
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

  Future<void> _printStatement() async {
    // Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing not implemented yet')),
    );
  }
}