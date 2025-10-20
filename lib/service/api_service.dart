import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final String _baseUrl = 'http://localhost:3000/api';

  Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Pengguna tidak login.');
    }
    final String? token = await user.getIdToken();
    if (token == null) {
      throw Exception('Gagal mendapatkan token otentikasi.');
    }
    return token;
  }

  Future<List<Map<String, dynamic>>> getOutlets() async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse('$_baseUrl/outlets');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Gagal memuat outlets: ${response.body}');
      }
    } catch (e) {
      print('Error di getOutlets: $e');
      rethrow;
    }
  }
  Future<void> addCategory({
    required String name,
    required int order,
    required List<Map<String, dynamic>> outlets,
    required int productQty,
  }) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse('$_baseUrl/categories');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'name': name,
        'order': order,
        'outlets': outlets,
        'productQty' : productQty
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 201) {
        throw Exception('Gagal menambah kategori: ${response.body}');
      }

      print('Kategori berhasil ditambahkan!');

    } catch (e) {
      print('Error di addCategory: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories({required String outletId}) async {
    try {
      final token = await _getAuthToken();

      final url = Uri.parse('$_baseUrl/categories?outletId=$outletId');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Gagal memuat kategori: ${response.body}');
      }
    } catch (e) {
      print('Error di getCategories: $e');
      rethrow;
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required int order,
    required List<Map<String, dynamic>> outlets,
  }) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse('$_baseUrl/categories/$id');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'name': name,
        'order': order,
        'outlets': outlets,
      });
      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to update category: ${errorBody['message']}');
      }
      print('Kategori berhasil diupdate!');

    } catch (e) {
      print('Error in updateCategory: $e');
      throw Exception('Failed to update category. $e');
    }
  }

  Future<void> addProduct({
    required String name,
    String? description,
    String? sku,
    required double sellingPrice,
    double? costPrice,
    required String categoryId,
    required List<Map<String, dynamic>> outlets,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/products');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'sku': sku,
        'sellingPrice': sellingPrice,
        'costPrice': costPrice,
        'categoryId': categoryId,
        'outlets': outlets,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add product: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getProducts({required String outletId}) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/products?outletId=$outletId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    String? description,
    String? sku,
    required double sellingPrice,
    double? costPrice,
    required String categoryId,
    required List<Map<String, dynamic>> outlets,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/products/$id');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'sku': sku,
        'sellingPrice': sellingPrice,
        'costPrice': costPrice,
        'categoryId': categoryId,
        'outlets': outlets,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  Future<void> deleteProduct(String id) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/products/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }
  // --- ADD THESE METHODS TO ApiService ---

  Future<List<Map<String, dynamic>>> getPelanggan() async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/pelanggan');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load pelanggan: ${response.body}');
    }
  }

  Future<void> addPelanggan({
    required String name,
    required String phone,
    String? email,
    String? gender,
    DateTime? dob,
    String? city,
    String? address,
    String? notes,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/pelanggan');
    final body = jsonEncode({
      'name': name,
      'phone': phone,
      'email': email,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'city': city,
      'address': address,
      'notes': notes,
    });

    final response = await http.post(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: body);

    if (response.statusCode != 201) {
      throw Exception('Failed to add pelanggan: ${response.body}');
    }
  }

  Future<void> updatePelanggan({
    required String id,
    required String name,
    required String phone,
    String? email,
    String? gender,
    DateTime? dob,
    String? city,
    String? address,
    String? notes,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/pelanggan/$id');
    final body = jsonEncode({
      'name': name,
      'phone': phone,
      'email': email,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'city': city,
      'address': address,
      'notes': notes,
    });

    final response = await http.put(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to update pelanggan: ${response.body}');
    }
  }

  Future<void> deletePelanggan(String id) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/pelanggan/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete pelanggan: ${response.body}');
    }
  }
}