import 'package:cybrox_kiosk_management/models/user.dart';
import 'package:cybrox_kiosk_management/navigation/navigation%20copy.dart';
import 'package:cybrox_kiosk_management/services/shared_prefs_services.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;

  const AppScaffold({
    super.key,
    required this.child,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userData = await SharedPreferencesService().getUserData();
    if (userData != null) {
      setState(() {
        currentUser = userData;
      });
    }
  }

  void _handleLogout() async {
    await SharedPreferencesService().clearUserData();
    setState(() {
      currentUser = null;
    });
    // Add navigation to login screen if needed
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      drawer: MyNavigationDrawer(
        currentUser: currentUser!,
        onLogout: _handleLogout,
        child: widget.child,
      ),
    );
  }
}