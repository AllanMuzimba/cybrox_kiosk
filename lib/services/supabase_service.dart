import 'dart:async';
import 'dart:convert';

import 'package:cybrox_kiosk_management/models/StockAudit.dart';
import 'package:cybrox_kiosk_management/models/finance_record.dart';
import 'package:cybrox_kiosk_management/models/tax.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cybrox_kiosk_management/models/product.dart';
import 'package:cybrox_kiosk_management/models/company.dart';
import 'package:cybrox_kiosk_management/models/stock_order.dart';
import 'package:cybrox_kiosk_management/models/return.dart';
import 'package:cybrox_kiosk_management/models/sale.dart';
import 'package:cybrox_kiosk_management/models/user.dart' as cybrox_user;
import 'package:cybrox_kiosk_management/services/shared_prefs_services.dart';
import 'package:crypto/crypto.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;
  final _sharedPrefs = SharedPreferencesService();

  //methds to handle user
  Future<User?> fetchCurrentUser() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) return null;

      final response = await supabase
          .from('users')
          .select()
          .eq('email', authUser.email as Object)
          .single();

      return User.fromJson(response);
    } catch (e, stackTrace) {
      print('Error fetching user: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> signOut(BuildContext context, cybrox_user.User user) async {
    try {
      // Clear Supabase session
      await supabase.auth.signOut();
      
      // Clear local storage using the correct service name
      await _sharedPrefs.clearUserData();
      
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  //end methods for user

  Future<Product?> getProductById(int productId) async {
    final response = await supabase
        .from('products')
        .select()
        .eq('id', productId)
        .single();
    return Product.fromJson(response);
  }

  Future<void> updateProductQuantity({
    required int productId,
    required int newQuantity,
  }) async {
    await supabase
        .from('products')
        .update({'stock_quantity': newQuantity})
        .eq('id', productId);
  }

  Future<Map<String, dynamic>> addStockRequest(StockOrder stockRequest) async {
    try {
      // 1. Get current stock quantity
      final productResponse = await supabase
          .from('products')
          .select('stock_quantity')
          .eq('id', stockRequest.productId)
          .single();

      print('Product Response: $productResponse');

      final stockQuantity = productResponse['stock_quantity'];
      if (stockQuantity == null) {
        return {'error': 'Stock quantity not found for product'};
      }

      if (stockQuantity is! int) {
        return {'error': 'Stock quantity is not an integer'};
      }

      final currentStock = stockQuantity;

      // 2. Check if stock is sufficient
      if (currentStock < stockRequest.quantity) {
        return {'error': 'Insufficient product stock'};
      }

      // 3. Deduct stock from products table
      final updatedStock = currentStock - stockRequest.quantity;
      await supabase
          .from('products')
          .update({'stock_quantity': updatedStock})
          .eq('id', stockRequest.productId);

      // 4. Insert stock request
      await supabase
          .from('stock_requests')
          .insert(stockRequest.toJson());

      return {'success': 'Stock request processed successfully'};
    } catch (e) {
      print('Error in addStockRequest: $e'); // Log the error
      return {'error': 'Error processing stock request: $e'};
    }
  }

  Future<void> addCompany(Company company) async {
    await supabase.from('company_details').insert(company.toJson());
  }

  Future<List<StockOrder>> fetchStockOrders() async {
    final response = await supabase.from('stock_orders').select();
    return response.map((e) => StockOrder.fromJson(e)).toList();
  }

  Future<void> addStockOrder(StockOrder stockOrder) async {
    await supabase.from('stock_orders').insert(stockOrder.toJson());
  }

  Future<List<Return>> fetchReturns() async {
    final response = await supabase.from('returns').select();
    return response.map((e) => Return.fromJson(e)).toList();
  }

  Future<void> addReturn(Return returnItem) async {
    await supabase.from('returns').insert(returnItem.toJson());
  }

  Future<List<Sale>> fetchSales() async {
    final response = await supabase.from('sales').select();
    return response.map((e) => Sale.fromJson(e)).toList();
  }
  // Add these methods to SupabaseService

  Future<void> addSale(Sale sale) async {
    await supabase.from('sales').insert(sale.toJson());
  }

  Future<void> updateCompany(Company company) async {
    //implement update company logic
    await supabase.from('company_details').update(company.toJson());
    
  }

  
  Future<void> updateStockOrder(StockOrder stockOrder, Map<String, Object> stockOrderData) async {
    await supabase.from('stock_orders').update(stockOrder.toJson());
  }

  Future<void> updateReturn(Return returnItem) async {
    await supabase.from('returns').update(returnItem.toJson());
  }

  Future<void> updateSale(Sale sale) async {
    await supabase.from('sales').update(sale.toJson());
  }

  Future<void> deleteCompany(int id) async {
    await supabase.from('company_details').delete().eq('id', id);
  }

  Future<List<Tax>> fetchTaxes() async {
    final response = await supabase.from('taxes').select();
    return response.map((e) => Tax.fromJson(e)).toList();
  }

  Future<void> addTax(Tax tax) async {
    await supabase.from('taxes').insert(tax.toJson());
  }
 
  Future<void> deleteStockRequest(int id) async {
    await supabase.from('stock_requests').delete().eq('id', id);
  }

  Future<List<cybrox_user.User>> fetchUsers() async {
    final response = await supabase.from('users').select();
    return response.map((e) => cybrox_user.User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateUser(cybrox_user.User user) async {
    await supabase
        .from('users')
        .update({
          'name': user.name,
          'username': user.username,
          'role': user.role,
          'email': user.email,
          'phone': user.phone,
          'company_id': user.companyId,
        })
        .eq('id', user.id);
  }

  Future<void> deleteUser(String userId) async {
    await supabase
        .from('users')
        .delete()
        .eq('id', userId);
  }
 
  //start methods for stocck request

  // Fetch companies from the database
  Future<List<Company>> fetchCompanies() async {
    final data = await supabase.from('company_details').select();
    return data.map((e) => Company.fromJson(e)).toList();
  }

  //fetch company by id
  Future<Company?> fetchCompanyById(int companyId) async {
    final response = await supabase
        .from('company_details')
        .select()
        .eq('id', companyId)
        .single();
    return Company.fromJson(response);
  }

  // Fetch stock requests from the database
  Future<List<Map<String, dynamic>>> fetchStockRequests() async {
    try {
      final response = await supabase
          .from('stock_requests')
          .select('''
            id,
            user_id,
            requesting_company_id,
            fulfilling_company_id,
            product_id,
            quantity,
            cost,
            sell_price,
            status,
            order_date,
            requesting_company:company_details!requesting_company_id(
              id, 
              company_name
            ),
            product:products!product_id(
              id,
              name
            ),
            user:users!user_id(
              id,
              name
            )
          ''')
          .order('order_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error in fetchStockRequests: $e');
      throw e;
    }
  }

  // Fetch received stock orders from the database
  Future<List<StockOrder>> fetchReceivedStockOrders() async {
    final data = await supabase.from('stock_orders').select();
    return data.map((e) => StockOrder.fromJson(e)).toList();
  }

  //start methods for product
  Future<void> processReceivedOrder(
    int orderId,
    Map<String, dynamic> stockOrderData,
    Map<String, dynamic> financeData,
    int quantity,
    int productId,
  ) async {
    try {
      // Start a transaction
      await supabase.rpc('begin_transaction');

      // Update stock request status
      await supabase
          .from('stock_requests')
          .update({'status': 'received', 'received_date': DateTime.now().toIso8601String()})
          .eq('id', orderId);

      // Insert into stock_orders
      await supabase.from('stock_orders').insert(stockOrderData);

      // Insert into finance
      await supabase.from('finance').insert(financeData);

      // Update product stock quantity
      await supabase.rpc('update_product_stock', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
      });

      // Commit the transaction
      await supabase.rpc('commit_transaction');
    } catch (e) {
      // Rollback on error
      await supabase
      .rpc('rollback_transaction');
      rethrow;
    }
  }

  // Fetch all products
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .order('name', ascending: true);
      
      return (response as List)
          .map((productJson) => Product.fromJson(productJson))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Add a new product
  Future<Product> addProduct(BuildContext context, Product product) async {
    try {
      // Check if barcode is unique
      final existingProducts = await supabase
          .from('products')
          .select('id')
          .eq('barcode', product.barcode);
      
      if (existingProducts.isNotEmpty) {
        throw Exception('A product with this barcode already exists');
      }

      final response = await supabase
          .from('products')
          .insert(product.toJson())
          .select()
          .single();
      
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update an existing product
  Future<void> updateProduct(Product product) async {
    try {
      if (product.id == null) {
        throw Exception('Product ID cannot be null for update operation');
      }

      // Check if barcode is unique (excluding this product)
      final existingProducts = await supabase
          .from('products')
          .select('id')
          .eq('barcode', product.barcode)
          .neq('id', product.id as Object);
      
      if (existingProducts.isNotEmpty) {
        throw Exception('Another product with this barcode already exists');
      }

      await supabase
          .from('products')
          .update(product.toJson())
          .eq('id', product.id as Object);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete a product
  Future<void> deleteProduct(int id) async {
    try {
      await supabase
          .from('products')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
  
  Future<void> addFinanceRecord(FinanceRecord financeRecord) async {
    // Implement adding a finance record
    print('Adding finance record: $financeRecord');
  }

  Future<void> createInvoice({
    required int orderId,
    required int companyId,
    required int userId,
    required double totalCost,
  }) async {
    // Implement creating an invoice using Supabase client
    print('Created invoice for orderId=$orderId');
  }
  
  Future<List<StocksAudit>> fetchStocksAudit() async {
    final data = await supabase.from('finance').select();
    return data.map((e) => StocksAudit.fromJson(e)).toList();
  }

   Future<void> updatePaymentStatus(int orderId, String status) async {
    await supabase.from('finance').update({'payment_status': status}).eq('order_id', orderId);
  }

  Future<void> markOrderAsReceived(Map<String, dynamic> stockOrderData, FinanceRecord financeRecord) async {
    // Start a transaction
    await supabase.rpc('begin_transaction');
    
    try {
      // Update the stock order
      await supabase
          .from('stock_orders')
          .update(stockOrderData)
          .eq('id', stockOrderData['id']);

      // Insert the finance record
      await supabase
          .from('finance_records')
          .insert(financeRecord.toJson());

      await supabase.rpc('commit_transaction');
    } catch (e) {
      await supabase.rpc('rollback_transaction');
      rethrow;
    }
  }

  Future<void> insertStockOrder(Map<String, dynamic> stockOrderData) async {
    final response = await supabase.from('stock_orders').insert(stockOrderData).single();
    if (response.error != null) throw Exception(response.error!.message);
  }

  Future<void> updateStockRequestStatus(int requestId, String status) async {
    final response = await supabase.from('stock_requests').update({'status': status}).eq('id', requestId).single();
    if (response.error != null) throw Exception(response.error!.message);
  }

  Future<void> updateStockOrderStatus(int orderId, String status) async {
    try {
      final response = await supabase
          .from('stock_requests')
          .update({'status': status})
          .eq('id', orderId)
          .select(); // Add .select() to get the updated row
          print('Supabase Update Successful: $response'); // Log the data
    } catch (e) {
      print('General Error: $e'); // Log any general errors
      rethrow;
    }
  }

  Future<void> updateProductStock(int productId, int quantity) async {
  // Fetch the current stock quantity
  final response = await supabase
      .from('products')
      .select('stock_quantity')
      .eq('id', productId)
      .single()
      .single();

  if (response.error != null) {
    throw Exception('Error fetching product: ${response.error!.message}');
  }

  // Get the current stock quantity from the response


  final currentStockQuantity = response.data['stock_quantity'];

  // Calculate the new stock quantity
  final newStockQuantity = currentStockQuantity - quantity;

  // Update the stock quantity in the database
  final updateResponse = await supabase
      .from('products')
      .update({'stock_quantity': newStockQuantity})
      .eq('id', productId)
      .single(); // Use execute() here for the update

  if (updateResponse.error != null) {
    throw Exception('Error updating product stock: ${updateResponse.error!.message}');
  }
}
 
  Future<int> insertFinanceRecord(FinanceRecord record) async {
    final response = await supabase
      .from('finance')
      .insert(record.toJson())
      .select('id')
      .single();
    
    return response['id'] as int;
  }

  Future<List<FinanceRecord>> fetchFinanceRecords() async {
  try {
    final response = await supabase
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

    return (response as List).map((record) => FinanceRecord.fromJson(record)).toList();
  } catch (e) {
    debugPrint('Error fetching finance records: $e');
    throw Exception('Failed to fetch finance records');
  }
}

  Future<void> copyToStockOrders(StockOrder order) async {
    await supabase.from('stock_orders').insert(order.toJson());
  }

  Future<double> getCompanyOutstandingBalance(int companyId) async {
    final response = await supabase
        .from('finance_records')
        .select('amount, type')
        .eq('company_id', companyId);
    
    double balance = 0.0;
    for (var record in response) {
      if (record['type'] == 'order') {
        balance += record['amount'];
      } else if (record['type'] == 'payment') {
        balance -= record['amount'];
      }
    }
    return balance;
  }

  Future<bool> isUserAdmin(String userId) async {
    // Replace with actual logic to check if the user is an admin
    final response = await supabase
        .from('users')
        .select('is_admin')
        .eq('id', userId)
        .single();

    if (response.error != null) {
      throw Exception('Failed to check if user is admin: ${response.error!.message}');
    }

    return response.data['is_admin'] as bool;
  }

  Future<Map<String, dynamic>> addUser(Map<String, dynamic> userData) async {
    final response = await supabase
      .from('users')
      .insert(userData)
      .select('id')
      .single();
    return response;
  }

  Future<void> resetUserPassword(int userId, String newPassword) async {
    try {
      // Hash the password before storing
      final bytes = utf8.encode(newPassword);
      final hashedPassword = sha256.convert(bytes).toString();
      
      await supabase
        .from('users')
        .update({'password': hashedPassword})
        .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchStockOrdersWithDetails() async {
    final response = await supabase
      .from('stock_orders')
      .select('''
        *,
        products!product_id(*),
        users!user_id(*)
      ''')
      .order('order_date', ascending: false);
    return response;
  }

  Future<List<Map<String, dynamic>>> fetchFinanceRecordsWithDetails() async {
    final response = await supabase
      .from('finance')
      .select('''
        *,
        company_details!company_id(*),
        users!user_id(*)
      ''')
      .order('created_at', ascending: false);
    return response;
  }

  Future<List<Map<String, dynamic>>> getRecipeRawMaterials(int recipeId) async {
    try {
      final response = await supabase
          .from('recipe_materials')
          .select('''
            quantity,
            raw_materials (
              id,
              name,
              cost_per_unit,
              unit_of_measure
            )
          ''')
          .eq('recipe_id', recipeId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching recipe materials: $e');
      throw Exception('Failed to fetch recipe materials');
    }
  }
}

extension on PostgrestMap {
  get error => null;
  
  get data => StockOrder.fromJson(this);
}