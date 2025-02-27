import 'package:cybrox_kiosk_management/screens/production/production.dart';
import 'package:flutter/material.dart';
import 'package:cybrox_kiosk_management/models/user.dart' as cybrox_user;
import 'package:cybrox_kiosk_management/screens/dashboard/dashboard_screen.dart';
import 'package:cybrox_kiosk_management/screens/settings_screen.dart';
import 'package:cybrox_kiosk_management/screens/login_screen.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';
import 'package:cybrox_kiosk_management/screens/company_screen.dart';
import 'package:cybrox_kiosk_management/screens/product_screen.dart';
import 'package:cybrox_kiosk_management/screens/report_screen.dart';
import 'package:cybrox_kiosk_management/screens/stock_orders/stock_orders_screen.dart';
import 'package:intl/intl.dart';
import 'package:cybrox_kiosk_management/screens/dashboard/dashboard_screen.dart';
import 'package:cybrox_kiosk_management/screens/invoice/invoice_screen.dart';

class NavigationDrawer extends StatefulWidget {
  final cybrox_user.User currentUser;
  final VoidCallback onLogout;

  const NavigationDrawer({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<NavigationDrawer> createState() => _NavigationDrawerState();
}

class _NavigationDrawerState extends State<NavigationDrawer> {
  int _selectedIndex = 0;
  final SupabaseService _supabaseService = SupabaseService();
  bool _isDrawerOpen = true;
  late List<NavigationItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    // Define navigation items based on user role
    _navigationItems = _getNavigationItemsByRole();
  }

  List<NavigationItem> _getNavigationItemsByRole() {
    // Dashboard is accessible to all users
    final items = [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard,
        screen: KioskHQApp(
          companyId: widget.currentUser.companyId ?? 0,
          userRole: widget.currentUser.role,
        ),
      ),
    ];

    // Add Production route only for admin
    if (widget.currentUser.role == 'admin') {
      items.add(
        NavigationItem(
          title: 'Production',
          icon: Icons.precision_manufacturing,
          screen: const Production(),
        ),
      );
    }

    // Add Invoice route - accessible to all users
    items.add(
      NavigationItem(
        title: 'Invoices',
        icon: Icons.receipt_long,
        screen: const InvoiceScreen(),
      ),
    );

    // Add other items based on role
    switch (widget.currentUser.role) {
      case 'admin':
        // Admin has access to everything
        items.addAll([
          NavigationItem(
            title: 'Products',
            icon: Icons.inventory,
            screen: const ProductScreen(),
          ),
          NavigationItem(
            title: 'Companies',
            icon: Icons.business,
            screen: const CompanyScreen(),
          ),
          NavigationItem(
            title: 'Stock Orders',
            icon: Icons.shopping_cart,
            screen: StockOrderScreen(currentUser: widget.currentUser),
          ),
          NavigationItem(
            title: 'Reports',
            icon: Icons.bar_chart,
            screen: ReportScreen(currentUser: widget.currentUser),
          ),
          NavigationItem(
            title: 'Settings',
            icon: Icons.settings,
            screen: const SettingsScreen(),
          ),
        ]);
        break;

      case 'finance':
        // Finance only has access to reports
        items.add(
          NavigationItem(
            title: 'Reports',
            icon: Icons.bar_chart,
            screen: ReportScreen(currentUser: widget.currentUser),
          ),
        );
        break;

      case 'manager':
      case 'dispatch':
        // Managers and dispatch only have access to stock orders
        items.add(
          NavigationItem(
            title: 'Stock Orders',
            icon: Icons.shopping_cart,
            screen: StockOrderScreen(currentUser: widget.currentUser),
          ),
        );
        break;
    }

   
    return items;
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 10),
              const Text(
                'About Cybrox Kiosk',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cybrox Kiosk Management System',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A comprehensive solution that manages products with dispatch and stock management for retail branches. Seamlessly shares database with Cybrox Retail System.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Developer Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Allan R Muzimba'),
                _buildInfoRow(Icons.email, 'cybroxrass@gmail.com'),
                _buildInfoRow(Icons.phone, '+263780575270'),
                const SizedBox(height: 16),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Sign out
      await _supabaseService.signOut(context, widget.currentUser);
      
      if (!mounted) return;

      // Close loading dialog and navigate
      Navigator.of(context)
        ..pop() // Close loading dialog
        ..pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      
      // Call the onLogout callback
      widget.onLogout();

    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog if open
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserDetailsDialog() {
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
            const Text('User Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserDetailRow('Name', widget.currentUser.name),
            _buildUserDetailRow('Username', widget.currentUser.username),
            _buildUserDetailRow('Email', widget.currentUser.email),
            if (widget.currentUser.phone != null)
              _buildUserDetailRow('Phone', widget.currentUser.phone!),
            _buildUserDetailRow('Role', widget.currentUser.role),
            _buildUserDetailRow(
              'Created', 
              DateFormat('MMM dd, yyyy').format(widget.currentUser.createdAt)
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailRow(String label, String value) {
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
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: Colors.blue,
              title: const Text(
                'Cybrox Kiosk',
                style: TextStyle(fontSize: 18),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  setState(() {
                    _isDrawerOpen = !_isDrawerOpen;
                  });
                },
              ),
            )
          : null,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isDrawerOpen ? 250 : 70,
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 2,
              child: Column(
                crossAxisAlignment: _isDrawerOpen 
                    ? CrossAxisAlignment.start 
                    : CrossAxisAlignment.center,
                children: [
                  if (!isSmallScreen) _buildHeader(),
                  const Divider(height: 1),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (var i = 0; i < _navigationItems.length; i++)
                          _buildNavItem(_navigationItems[i], i),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                    title: _isDrawerOpen
                        ? const Text(
                            'About',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : null,
                    onTap: _showAboutDialog,
                  ),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
          Expanded(
            child: _navigationItems[_selectedIndex].screen,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: _isDrawerOpen 
            ? CrossAxisAlignment.start 
            : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Menu header with toggle
          Row(
            mainAxisAlignment: _isDrawerOpen 
                ? MainAxisAlignment.spaceBetween 
                : MainAxisAlignment.center,
            children: [
              if (_isDrawerOpen)
                Expanded(
                  child: Text(
                    'Cybrox Kiosk',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              SizedBox(
                width: 35,
                height: 35,
                child: IconButton(
                  icon: Icon(
                    _isDrawerOpen ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _isDrawerOpen = !_isDrawerOpen),
                ),
              ),
            ],
          ),
          // User info section
          if (_isDrawerOpen) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: _showUserDetailsDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.blue, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.currentUser.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.currentUser.email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, int index) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      leading: Icon(
        item.icon,
        color: isSelected ? Colors.blue : Colors.grey,
        size: 22,
      ),
      title: _isDrawerOpen
          ? Text(
              item.title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            )
          : null, // Show title only when drawer is open
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (MediaQuery.of(context).size.width < 600) {
          setState(() {
            _isDrawerOpen = false; // Close drawer on tap for small screens
          });
        }
      },
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      dense: true,
      leading: const Icon(
        Icons.logout,
        color: Colors.red,
        size: 22,
      ),
      title: _isDrawerOpen
          ? const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            )
          : null,
      onTap: _handleLogout,
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final Widget screen;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.screen,
  });
}