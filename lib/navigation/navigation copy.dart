import 'package:flutter/material.dart';
import 'package:cybrox_kiosk_management/models/user.dart' as AppUser;

class MyNavigationDrawer extends StatefulWidget {
  final AppUser.User currentUser;
  final Widget child;
  final VoidCallback onLogout;

  const MyNavigationDrawer({
    super.key,
    required this.currentUser,
    required this.child,
    required this.onLogout,
  });

  @override
  _MyNavigationDrawerState createState() => _MyNavigationDrawerState();
}

class _MyNavigationDrawerState extends State<MyNavigationDrawer> {
  bool _isDrawerOpen = false;

  void                                                                                                                                                                                                                          _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _navigateTo(String route) {
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
      setState(() {
        _isDrawerOpen = false;
      });
    }
  }

  Widget _buildDrawerItem(IconData icon, String title, String route) {
    return SizedBox(
      height: 48,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(overflow: TextOverflow.ellipsis),
        ),
        onTap: () => _navigateTo(route),
      ),
    );
  }

Widget _buildDrawerHeader() {
  return Container(
    height: 160,
    width: double.infinity, // Ensures full width
    decoration: const BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.zero, // Ensures no rounded corners
    ),
    padding: const EdgeInsets.all(16), // Adjust padding for spacing
    alignment: Alignment.bottomLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, size: 40, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          widget.currentUser.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          widget.currentUser.email,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
@override
Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name ?? '/dashboard';

    return Scaffold(
        appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Cybrox Kiosk",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(_isDrawerOpen ? Icons.menu_open : Icons.menu, color: Colors.white),
          onPressed: _toggleDrawer,
        ),
        actions: [
          if (currentRoute == '/stock-orders')
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text("+ New Request"),
            ),
        ],
       ),
        body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isDrawerOpen ? 250 : 70,
            child: Drawer(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDrawerHeader(),
                    const Divider(),
                    _buildDrawerItem(Icons.dashboard, "Dashboard", '/dashboard'),
                    _buildDrawerItem(Icons.shopping_cart, "Stock Orders", '/stock-orders'),
                    _buildDrawerItem(Icons.store, "Products", '/products'),
                    _buildDrawerItem(Icons.business, "Companies", '/companies'),
                    _buildDrawerItem(Icons.build, "Production", '/production'),
                    _buildDrawerItem(Icons.bar_chart, "Reports", '/reports'),
                    _buildDrawerItem(Icons.settings, "Settings", '/settings'),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text("Logout", style: TextStyle(color: Colors.red)),
                      onTap: widget.onLogout,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}