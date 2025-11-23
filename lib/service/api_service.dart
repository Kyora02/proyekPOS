import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  final String _baseUrl = kIsWeb
      ? 'http://localhost:3000/api'
      : 'http://10.0.2.2:3000/api';

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
    } catch (e) {
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
    } catch (e) {
      throw Exception('Failed to update category. $e');
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

  Future<void> addProduct({
    required String name,
    String? description,
    String? sku,
    required double sellingPrice,
    double? costPrice,
    required String categoryId,
    required List<Map<String, dynamic>> outlets,
    XFile? imageFile,
    bool showInMenu = true,
    int? stok,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/products');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    if (sku != null) request.fields['sku'] = sku;
    request.fields['sellingPrice'] = sellingPrice.toString();
    if (costPrice != null) request.fields['costPrice'] = costPrice.toString();
    request.fields['categoryId'] = categoryId;
    request.fields['outlets'] = jsonEncode(outlets);
    request.fields['showInMenu'] = showInMenu.toString();
    if (stok != null) request.fields['stok'] = stok.toString();

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(
          http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: imageFile.name
          )
      );
    }

    var response = await request.send();
    if (response.statusCode != 201) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to add product: $respStr');
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
    XFile? imageFile,
    bool showInMenu = true,
    int? stok,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/products/$id');

    var request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    if (sku != null) request.fields['sku'] = sku;
    request.fields['sellingPrice'] = sellingPrice.toString();
    if (costPrice != null) request.fields['costPrice'] = costPrice.toString();
    request.fields['categoryId'] = categoryId;
    if (outlets != null) request.fields['outlets'] = jsonEncode(outlets);
    request.fields['showInMenu'] = showInMenu.toString();
    if (stok != null) request.fields['stok'] = stok.toString();

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(
          http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: imageFile.name
          )
      );
    }

    var response = await request.send();
    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to update product: $respStr');
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
    required String kodeKupon,
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
      'kodeKupon': kodeKupon,
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
    required String kodeKupon,
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
      'kodeKupon': kodeKupon,
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

  Future<List<Map<String, dynamic>>> getRawMaterials(String outletId) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/stok?outletId=$outletId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load raw materials: ${response.body}');
    }
  }

  Future<void> addRawMaterial({
    required String name,
    required DateTime date,
    required double price,
    required String outletId,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/stok');
    final body = jsonEncode({
      'name': name,
      'date': date.toIso8601String(),
      'price': price,
      'outletId': outletId,
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
      throw Exception('Failed to add raw material: ${response.body}');
    }
  }

  Future<void> updateRawMaterial({
    required String id,
    required String name,
    required DateTime date,
    required double price,
    required String outletId,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/stok/$id');
    final body = jsonEncode({
      'name': name,
      'date': date.toIso8601String(),
      'price': price,
      'outletId': outletId,
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
      throw Exception('Failed to update raw material: ${response.body}');
    }
  }

  Future<void> deleteRawMaterial(String id) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/stok/$id');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete raw material: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createTransaction({
    required double amount,
    required List<Map<String, dynamic>> items,
    required String customerName,
    required String customerPhone,
    required String paymentMethod,
    required String karyawanId,
    required String outletId,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/payment/charge');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'grossAmount': amount,
        'items': items,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'paymentMethod': paymentMethod,
        'karyawanId': karyawanId,
        'outletId': outletId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create transaction: ${response.body}');
    }
  }

  Future<void> updateTransactionStatus(String orderId, String status) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/payment/update-status');

    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'orderId': orderId,
        'status': status,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> getSalesDetail({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      final formattedStartDate = startDate.toIso8601String();
      final formattedEndDate = endDate.toIso8601String();

      final url = Uri.parse(
          '$_baseUrl/reports/sales-detail?outletId=$outletId&startDate=$formattedStartDate&endDate=$formattedEndDate');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>().map((item) {
          return {
            ...item,
            'timestamp': DateTime.fromMillisecondsSinceEpoch(item['timestamp']),
            'outlet': 'Outlet Name Placeholder',
          };
        }).toList();
      } else {
        throw Exception(
            'Gagal memuat detail penjualan: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
  Future<List<Map<String, dynamic>>> getProductSalesReports({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      final formattedStartDate = startDate.toIso8601String();
      final formattedEndDate = endDate.toIso8601String();

      final url = Uri.parse(
          '$_baseUrl/reports/product-sales-reports?outletId=$outletId&startDate=$formattedStartDate&endDate=$formattedEndDate');

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
      rethrow;
    }
  }


  Future<Map<String, dynamic>?> checkTransactionStatus(String orderId) async {
    try {
      final token = await _getAuthToken();

      final url = Uri.parse('$_baseUrl/payment/check-status/$orderId');

      print('Checking status at: $url');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status check response code: ${response.statusCode}');
      print('Status check response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        print('Transaction not found: $orderId');
        return null;
      } else {
        throw Exception('Failed to check status: ${response.body}');
      }
    } catch (e) {
      print('Error checking transaction status: $e');
      return null;
    }
  }

  Future<void> reduceStock({required List<Map<String, dynamic>> items}) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/reports/reduce-stock');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'items': items}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reduce stock: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getCategorySalesReports({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      final formattedStartDate = startDate.toIso8601String();
      final formattedEndDate = endDate.toIso8601String();

      final url = Uri.parse(
          '$_baseUrl/reports/category-sales-reports?outletId=$outletId&startDate=$formattedStartDate&endDate=$formattedEndDate');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
            'Gagal memuat laporan penjualan kategori: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerSalesReports({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      final formattedStartDate = startDate.toIso8601String();
      final formattedEndDate = endDate.toIso8601String();

      final url = Uri.parse(
          '$_baseUrl/reports/customer-sales-reports?outletId=$outletId&startDate=$formattedStartDate&endDate=$formattedEndDate');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
            'Gagal memuat laporan pelanggan: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPurchaseDetail({
    required String outletId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      final formattedStartDate = startDate.toIso8601String();
      final formattedEndDate = endDate.toIso8601String();

      final url = Uri.parse(
          '$_baseUrl/reports/purchase-detail?outletId=$outletId&startDate=$formattedStartDate&endDate=$formattedEndDate');

      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Gagal memuat detail pembelian: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

}