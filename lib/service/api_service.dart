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
}