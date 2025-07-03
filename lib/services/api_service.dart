import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> getApiHeaders() => _getHeaders();

  // Authentication
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String token = responseBody['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return responseBody;
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  // Dashboard
  static Future<Map<String, dynamic>> getDashboardOverview({
    String? startDate,
    String? endDate,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/dashboard/overview').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard: ${response.statusCode}');
    }
  }

  // Sales Ledgers
  static Future<Map<String, dynamic>> getSalesLedgers({
    String? search,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    int? perPage,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    
    if (search != null) queryParams['search'] = search;
    if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (perPage != null) queryParams['per_page'] = perPage.toString();

    final uri = Uri.parse('$baseUrl/sales-ledgers').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load sales ledgers: ${response.statusCode}');
    }
  }

  // Products
  static Future<Map<String, dynamic>> getProducts({
    String? search,
    int? categoryId,
    String? barcode,
    int? perPage,
    int? page,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    
    if (search != null) queryParams['search'] = search;
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (barcode != null) queryParams['barcode'] = barcode;
    if (perPage != null) queryParams['per_page'] = perPage.toString();
    if (page != null) queryParams['page'] = page.toString();

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  // Categories
  static Future<Map<String, dynamic>> getCategories({
    String? search,
    int? perPage,
    int? page,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    
    if (search != null) queryParams['search'] = search;
    if (perPage != null) queryParams['per_page'] = perPage.toString();
    if (page != null) queryParams['page'] = page.toString();

    final uri = Uri.parse('$baseUrl/category-masters').replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  // Users
  static Future<Map<String, dynamic>> getUsers({int? page, int? perPage, String? search}) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (perPage != null) queryParams['per_page'] = perPage.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final uri = Uri.parse('$baseUrl/users').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users: \\${response.statusCode}');
    }
  }

  // Transactions
  static Future<Map<String, dynamic>> getTransactions({String? search, int? page}) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (page != null) queryParams['page'] = page.toString();
    final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create transaction: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getTransactionById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transaction: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateTransaction(int id, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update transaction: \\${response.statusCode}');
    }
  }

  static Future<void> deleteTransaction(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete transaction: \\${response.statusCode}');
    }
  }

  // Expense Ledgers
  static Future<Map<String, dynamic>> getExpenseLedgers({
    String? startDate,
    String? endDate,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    final uri = Uri.parse('$baseUrl/expense-ledgers').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load expense ledgers: \\${response.statusCode}');
    }
  }

  // Product Masters
  static Future<Map<String, dynamic>> getProductMasters({
    String? search,
    int? categoryId,
    int? perPage,
    int? page,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (perPage != null) queryParams['per_page'] = perPage.toString();
    if (page != null) queryParams['page'] = page.toString();
    final uri = Uri.parse('$baseUrl/product-masters').replace(queryParameters: queryParams);
    debugPrint('[API] GET Product Masters: URL = $uri');
    debugPrint('[API] Query Params: $queryParams');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load product masters: ${response.statusCode}');
    }
  }

  // Get current user by email
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email == null) return null;
    final usersResponse = await getUsers();
    if (usersResponse['data'] is List) {
      final users = usersResponse['data'] as List;
      return users.cast<Map<String, dynamic>>().firstWhere(
        (user) => user['email'] == email,
        orElse: () => {},
      );
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>?> getInventoryStatus() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/inventory-status'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load inventory status: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>?> getSalesLedger({
    required String fromDate,
    required String toDate,
    String search = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uri = Uri.parse('$baseUrl/sales-ledgers').replace(queryParameters: {
      'start_date': fromDate,
      'end_date': toDate,
      if (search.isNotEmpty) 'search': search,
    });
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load sales ledger');
    }
  }

  static Future<Map<String, dynamic>?> getSalesLedgerById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/sales-ledgers/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load sales ledger details: \\${response.statusCode}');
    }
  }

  // Expense Ledger CRUD
  static Future<Map<String, dynamic>?> getExpenseLedgerById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/expense-ledgers/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load expense ledger details: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>?> createExpenseLedger(Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/expense-ledgers'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create expense ledger: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>?> updateExpenseLedger(int id, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/expense-ledgers/$id'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update expense ledger: \\${response.statusCode}');
    }
  }

  static Future<void> deleteExpenseLedger(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/expense-ledgers/$id'),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete expense ledger: \\${response.statusCode}');
    }
  }

  static Future<void> updateSalesLedger(int id, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/sales-ledgers/$id'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update sales ledger: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getAllPendingSalesLedgers() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/sales-ledgers/pending'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load pending sales ledgers: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getUserById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> patchSalesLedgerPaymentInfo(int id, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/sales-ledgers/$id/payment-info'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update sales ledger: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return {'error': 'Failed to create user', 'status': response.statusCode};
      }
    }
  }

  static Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return {'error': 'Failed to update user', 'status': response.statusCode};
      }
    }
  }

  static Future<void> deleteUser(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: {
        ...headers,
        'Accept': 'application/json',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      try {
        final error = jsonDecode(response.body);
        if (error is Map && error['message'] != null) {
          throw Exception(error['message']);
        }
      } catch (_) {}
      throw Exception('Failed to delete user: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getSalesLedgersByUser({
    required int userId,
    String? paymentStatus, // 'pending', 'paid', or null for all
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{
      'user_id': userId.toString(),
    };
    if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
    final uri = Uri.parse('$baseUrl/sales-ledgers').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user sales ledgers: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getUserDetails(int userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/details'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user details: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create product: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update product: \\${response.statusCode}');
    }
  }

  static Future<void> deleteProduct(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete product: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> createProductMaster(Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/product-masters'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create product master: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateProductMaster(int id, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/product-masters/$id'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update product master: \\${response.statusCode}');
    }
  }

  static Future<void> deleteProductMaster(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/product-masters/$id'),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete product master: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> getProductMasterById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/product-masters/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final resp = jsonDecode(response.body);
      return resp['data'] ?? resp;
    } else {
      throw Exception('Failed to load product master: \\${response.statusCode}');
    }
  }

  // CATEGORY MASTERS
  static Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/category-masters/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      String msg = 'Failed to delete category';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) msg = data['message'];
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<void> createCategory(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/category-masters'),
      headers: {
        ...(await _getHeaders()),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Failed to create category';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) msg = data['message'];
        if (data is Map && data['errors'] != null) {
          msg = (data['errors'] as Map).values.map((e) => (e as List).join(', ')).join('\n');
        }
        if (msg == 'Failed to create category') {
          msg += ' (Status: ${response.statusCode})\nResponse: ${response.body}';
        }
      } catch (_) {
        msg += ' (Status: ${response.statusCode})\nRaw response: ${response.body}';
      }
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> getCategoryById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/category-masters/$id'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load category details: \\${response.statusCode}');
    }
  }

  // TODO: Implement editCategory
} 