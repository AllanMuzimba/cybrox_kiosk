import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  runApp(const KioskHQApp(companyId: 0, userRole: ''));
}

class KioskHQApp extends StatelessWidget {
  final int companyId;
  final String userRole;
  static const routeName = '/dashboard';

  const KioskHQApp({
    Key? key,
    required this.companyId,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiosk HQ Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4FC3F7),
          primary: const Color(0xFF4FC3F7),
          secondary: const Color(0xFF03A9F4),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<CompanyDetails> _companies = [];
  bool _isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _fetchCompanies() async {
    if (!mounted) return;
    
    try {
      final response = await _supabase
          .from('company_details')
          .select()
          .order('is_hq', ascending: false)
          .order('company_name');

      if (!mounted) return;

      final List<CompanyDetails> companies = [];
      
      for (var companyData in response) {
        if (!mounted) return;

        final ordersResponse = await _supabase
            .from('stock_requests')
            .select('cost, quantity')
            .eq('requesting_company_id', companyData['id']);
        
        double totalOrders = 0;
        for (var order in ordersResponse) {
          final orderCost = (order['cost'] ?? 0).toDouble();
          final quantity = (order['quantity'] ?? 0).toDouble();
          totalOrders += orderCost * quantity;
        }
      
        final depositsResponse = await _supabase
            .from('finance')
            .select('amount')
            .eq('company_id', companyData['id']);
        
        double totalDeposits = 0;
        for (var deposit in depositsResponse) {
          totalDeposits += (deposit['amount'] ?? 0).toDouble();
        }

        companies.add(CompanyDetails.fromMap({
          ...companyData,
          'balance': totalDeposits - totalOrders,
        }));
      }

      if (!mounted) return;

      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      print('Error fetching companies: $e');
      print('Error details: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hqCompany = _companies.firstWhere(
      (company) => company.isHq,
      orElse: () => CompanyDetails(
        id: 2,
        companyName: 'Kiosk HQ',
        address: 'Mutare, Zimbabwe',
        contactPhone: '0719 025 5433',
        email: 'default@kioskhq.com',
        tin: '00000000` ',
        isHq: true,
        createdAt: DateTime.now(),
      ),
    );

    final branchCompanies = _companies.where((company) => !company.isHq).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFE1F5FE),
              const Color(0xFFB3E5FC),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WelcomeHeader(),
                const SizedBox(height: 12),
                
                CompanyCountCard(companyCount: branchCompanies.length),
                const SizedBox(height: 8),
                
                HQOfficeCard(hqCompany: hqCompany),
                const SizedBox(height: 8),
                
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Text(
                    'Branch Companies',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0277BD),
                    ),
                  ),
                ),
                
                Expanded(
                  child: CompanyListView(companies: branchCompanies),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchCompanies,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.business,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Kiosk HQ',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF01579B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your centralized company management dashboard',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyCountCard extends StatelessWidget {
  final int companyCount;

  const CompanyCountCard({
    Key? key,
    required this.companyCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card3D(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Companies',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  companyCount.toString(),
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.business_center,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HQOfficeCard extends StatelessWidget {
  final CompanyDetails hqCompany;

  const HQOfficeCard({
    Key? key,
    required this.hqCompany,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card3D(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FC3F7), Color(0xFF039BE5)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF039BE5).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Headquarters',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'HQ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              hqCompany.companyName,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hqCompany.address,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  hqCompany.contactPhone,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  hqCompany.email,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyListView extends StatelessWidget {
  final List<CompanyDetails> companies;

  const CompanyListView({
    Key? key,
    required this.companies,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: companies.length,
      itemBuilder: (context, index) {
        final company = companies[index];
        if (company.isHq) {
          return const SizedBox.shrink();
        }
        
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: 1.0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: CompanyCard(company: company),
          ),
        );
      },
    );
  }
}

class CompanyCard extends StatelessWidget {
  final CompanyDetails company;

  const CompanyCard({
    Key? key,
    required this.company,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card3D(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Color(0xFF0288D1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.companyName,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF01579B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'TIN: ${company.tin}',
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Balance: \$${company.balance.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: company.balance >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CompanyDetailRow(
              icon: Icons.location_on,
              value: company.address,
            ),
            const SizedBox(height: 8),
            CompanyDetailRow(
              icon: Icons.phone,
              value: company.contactPhone,
            ),
            const SizedBox(height: 8),
            CompanyDetailRow(
              icon: Icons.email,
              value: company.email,
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyDetailRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const CompanyDetailRow({
    Key? key,
    required this.icon,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF0288D1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: const Color(0xFF455A64),
            ),
          ),
        ),
      ],
    );
  }
}

class Card3D extends StatefulWidget {
  final Widget child;

  const Card3D({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<Card3D> createState() => _Card3DState();
}

class _Card3DState extends State<Card3D> {
  double rotateX = 0;
  double rotateY = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          rotateY = (rotateY + details.delta.dx * 0.01).clamp(-0.05, 0.05);
          rotateX = (rotateX - details.delta.dy * 0.01).clamp(-0.05, 0.05);
        });
      },
      onPanEnd: (_) {
        setState(() {
          rotateX = 0;
          rotateY = 0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(rotateX)
          ..rotateY(rotateY),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

// Data model based on your database schema
class CompanyDetails {
  final int id;
  final String companyName;
  final String address;
  final String contactPhone;
  final String email;
  final String tin;
  final bool isHq;
  final DateTime createdAt;
  final int synced;
  final double balance;

  CompanyDetails({
    required this.id,
    required this.companyName,
    required this.address,
    required this.contactPhone,
    required this.email,
    required this.tin,
    required this.isHq,
    required this.createdAt,
    this.synced = 0,
    this.balance = 0.0,
  });

  // Factory method to create from database
  factory CompanyDetails.fromMap(Map<String, dynamic> map) {
    return CompanyDetails(
      id: map['id'] ?? 0,
      companyName: map['company_name'] ?? '',
      address: map['address'] ?? '',
      contactPhone: map['contact_phone'] ?? '',
      email: map['email'] ?? '',
      tin: map['tin'] ?? '',
      isHq: map['is_hq'] == true || map['is_hq'] == 1,  // Handle both boolean and integer
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      synced: map['synced'] ?? 0,
      balance: (map['balance'] ?? 0).toDouble(),
    );
  }
}