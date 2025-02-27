import 'package:cybrox_kiosk_management/screens/reports/stock_requests_dashboard_screen.dart';
import 'package:cybrox_kiosk_management/screens/reports/payment_method_dialog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/screens/reports/audit_report_screen.dart';
import 'package:cybrox_kiosk_management/models/user.dart' as cybrox_user;

class ReportScreen extends StatefulWidget {
  static const routeName = '/reports';
  final cybrox_user.User? currentUser;

  const ReportScreen({super.key, required this.currentUser});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient supabaseClient = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentFormDialog(
        currentUser: widget.currentUser,
        onPaymentComplete: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Account Statement'),
            Tab(text: 'Audit Report'),
            Tab(text: 'Payment Method'),
            Tab(text: 'HR Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StockRequestsDashboard(supabaseClient: supabaseClient),
          AuditReportScreen(currentUser: widget.currentUser),
          Center(
            child: ElevatedButton(
              onPressed: _showPaymentDialog,
              child: const Text('Open Payment Dialog'),
            ),
          ),
          const Center(child: Text('HR Reports')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class AccountStatementReport extends StatelessWidget {
  const AccountStatementReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Account Statement Report'));
  }
}

class AuditReport extends StatelessWidget {
  const AuditReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuditReportScreen();
  }
}

class HRReports extends StatelessWidget {
  const HRReports({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('HR Reports'));
  }
}
