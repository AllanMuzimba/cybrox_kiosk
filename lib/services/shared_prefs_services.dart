import 'package:shared_preferences/shared_preferences.dart';
import 'package:cybrox_kiosk_management/models/user.dart' as cybrox_user;
import 'dart:convert';

class SharedPreferencesService {
  Future<cybrox_user.User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('user_data');

    if (userDataString == null) return null;

    final Map<String, dynamic> userData = jsonDecode(userDataString);
    return cybrox_user.User(
      id: userData['id'] as int,
      name: userData['name'] as String,
      email: userData['email'] as String,
      username: userData['username'] as String,
      phone: userData['phone'] as String?,
      password: userData['password'] as String,
      role: userData['role'] as String,
      companyId: userData['company_id'] as int?,
      createdAt: DateTime.parse(userData['created_at'] as String),
    );
  }

  Future<void> saveUserData(cybrox_user.User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = jsonEncode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'username': user.username,
      'phone': user.phone,
      'password': user.password,
      'role': user.role,
      'company_id': user.companyId,
      'created_at': user.createdAt.toIso8601String(),
    });
    await prefs.setString('user_data', userData);
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }
}