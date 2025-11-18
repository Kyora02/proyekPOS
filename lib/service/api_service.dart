import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final String _baseUrl = kIsWeb
      ? 'http://localhost:3000/api'
      : 'http://10.0.2.2:3000/api';

  Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;    if (user == null) {
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

      final body = jsonEncode(
          {'name': name, 'order': order, 'outlets': outlets, 'productQty': productQty});

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

  Future<List<Map<String, dynamic>>> getCategories(
      {required String outletId}) async {
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

  Future<List<Map<String, dynamic>>> getProducts(
      {required String outletId}) async {
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
    List<Map<String, dynamic>>? outlets,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/products/$id');

    final Map<String, dynamic> body = {
      'name': name,
      'description': description,
      'sku': sku,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'categoryId': categoryId,
    };

    if (outlets != null) {
      body['outlets'] = outlets;
    }

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
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

  Future<List<Map<String, dynamic>>> getPelanggan(
      {required String outletId}) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/pelanggan?outletId=$outletId');
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
    required String outletId,
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
      'outletId': outletId,
    });

    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body);

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
    required String outletId,
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
      'outletId': outletId,
    });

    final response = await http.put(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body);

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

  Future<List<Map<String, dynamic>>> getKaryawan(
      {required String outletId}) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse('$_baseUrl/karyawan?outletId=$outletId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Gagal memuat karyawan: ${response.body}');
      }
    } catch (e) {
      print('Error di getKaryawan: $e');
      rethrow;
    }
  }

  Future<void> addKaryawan({
    required String nama,
    required String nip,
    required String email,
    required String password,
    String? notelp,
    required String outlet,
    required String outletId,
    required String status,
  }) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse('$_baseUrl/karyawan');
      final body = jsonEncode({
        'nama': nama,
        'nip': nip,
        'email': email,
        'password': password,
        'notelp': notelp,
        'outlet': outlet,
        'outletId': outletId,
        'status': status,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body,
      );

      if (response.statusCode != 201) {
        throw Exception('Gagal menambah karyawan: ${response.body}');
      }
    } catch (e) {
      print('Error di addKaryawan: $e');
      rethrow;
    }
  }

  Future<void> updateKaryawan({
    required String id,
    required String nama,
    required String nip,
    String? notelp,
    required String outlet,
    required String outletId,
    required String status,
  }) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse('$_baseUrl/karyawan/$id');
      final body = jsonEncode({
        'nama': nama,
        'nip': nip,
        'notelp': notelp,
        'outlet': outlet,
        'outletId': outletId,
        'status': status,
      });

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal mengupdate karyawan: ${response.body}');
      }
    } catch (e) {
      print('Error di updateKaryawan: $e');
      rethrow;
    }
  }

  Future<void> deleteKaryawan(String id) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse('$_baseUrl/karyawan/$id');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus karyawan: ${response.body}');
      }
    } catch (e) {
      print('Error di deleteKaryawan: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getKupon(
      {required String outletId}) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/kupon?outletId=$outletId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load kupon: ${response.body}');
    }
  }

  Future<void> addKupon({
    required String nama,
    String? deskripsi,
    required double nilai,
    required String outletId,
    required String tipeNilai,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required bool status,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/kupon');
    final body = jsonEncode({
      'nama': nama,
      'deskripsi': deskripsi,
      'nilai': nilai,
      'outletId': outletId,
      'tipeNilai': tipeNilai,
      'tanggalMulai': tanggalMulai.toIso8601String(),
      'tanggalSelesai': tanggalSelesai.toIso8601String(),
      'status': status,
    });

    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body);

    if (response.statusCode != 201) {
      throw Exception('Failed to add kupon: ${response.body}');
    }
  }

  Future<void> updateKupon({
    required String id,
    required String nama,
    String? deskripsi,
    required double nilai,
    required String outletId,
    required String tipeNilai,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required bool status,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/kupon/$id');
    final body = jsonEncode({
      'nama': nama,
      'deskripsi': deskripsi,
      'nilai': nilai,
      'outletId': outletId,
      'tipeNilai': tipeNilai,
      'tanggalMulai': tanggalMulai.toIso8601String(),
      'tanggalSelesai': tanggalSelesai.toIso8601String(),
      'status': status,
    });

    final response = await http.put(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to update kupon: ${response.body}');
    }
  }

  Future<void> deleteKupon(String id) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/kupon/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete kupon: ${response.body}');
    }
  }

  Future<void> addOutlet({
    required String name,
    required String alamat,
    required String city,
    required String ownerName,
    required String operationDuration,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/outlets');
    final body = jsonEncode({
      'name': name,
      'alamat': alamat,
      'city': city,
      'ownerName': ownerName,
      'operationDuration': operationDuration,
    });

    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body);

    if (response.statusCode != 201) {
      throw Exception('Failed to add outlet: ${response.body}');
    }
  }

  Future<void> updateOutlet({
    required String id,
    required String name,
    required String alamat,
    required String city,
    required String operationDuration,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/outlets/$id');
    final body = jsonEncode({
      'name': name,
      'alamat': alamat,
      'city': city,
      'operationDuration': operationDuration,
    });

    final response = await http.put(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to update outlet: ${response.body}');
    }
  }

  Future<void> deleteOutlet(String id) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/outlets/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete outlet: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getStockProducts(String outletId) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/stok/products/$outletId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load stock products: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllStock(
      {required String outletId}) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/stok/all?outletId=$outletId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load all stock: ${response.body}');
    }
  }

  Future<void> addStock({
    required String outletId,
    required String productId,
    required String stokToAdd,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/stok/add');
    final body = jsonEncode({
      'outletId': outletId,
      'productId': productId,
      'stokToAdd': stokToAdd,
    });

    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to add stock: ${response.body}');
    }
  }

  Future<void> updateStock({
    required String outletId,
    required String productId,
    required String newStock,
  }) async {
    try {
      final token = await _getAuthToken();
      final url = Uri.parse('$_baseUrl/stok/update');

      final body = jsonEncode({
        'outletId': outletId,
        'productId': productId,
        'newStock': newStock,
      });

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update stock: ${response.body}');
      }
    } catch (e) {
      print('Error di updateStock: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSalesReports({
    required DateTime startDate,
    required DateTime endDate,
    required String outletId,
  }) async {
    try {
      final token = await _getAuthToken();

      final String start = DateFormat('yyyy-MM-dd').format(startDate);
      final String end = DateFormat('yyyy-MM-dd').format(endDate);

      final url = Uri.parse(
          '$_baseUrl/reports/sales?startDate=$start&endDate=$end&outletId=$outletId');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((dynamic item) {
          final Map<String, dynamic> map = item as Map<String, dynamic>;

          return {
            'noTransaksi': map['noTransaksi'],
            'outlet': map['namaOutlet'],
            'totalPenjualan': map['total_bayar'],
            'metodePembayaran': map['metodePembayaran'],
            'timestamp': DateTime.parse(map['waktuTransaksi']),
            'customer': map['namaCustomer'],
            'karyawan': map['namaKaryawan'],
          };
        }).toList();
      } else {
        throw Exception('Gagal memuat laporan penjualan: ${response.body}');
      }
    } catch (e) {
      print('Error di getSalesReports: $e');
      rethrow;
    }
  }
  Future<List<Map<String, dynamic>>> getProductSalesReports({
    required String outletId,
  }) async {
    try {
      final token = await _getAuthToken();

      final url = Uri.parse(
          '$_baseUrl/reports/product-sales?outletId=$outletId');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Gagal memuat laporan penjualan produk: ${response.body}');
      }
    } catch (e) {
      print('Error di getProductSalesReports: $e');
      rethrow;
    }
  }
}