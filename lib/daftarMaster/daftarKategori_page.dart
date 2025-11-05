import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyekpos2/crud/tambahKategori_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DaftarKategoriPage extends StatefulWidget {
  final String outletId;

  const DaftarKategoriPage({
    super.key,
    required this.outletId,
  });

  @override
  State<DaftarKategoriPage> createState() => _DaftarKategoriPageState();
}

class _DaftarKategoriPageState extends State<DaftarKategoriPage> {
  final String _baseUrl = 'http://localhost:3000';

  List<Map<String, dynamic>> _allCategories = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    return await user.getIdToken();
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Use the outletId passed from the widget
      final String? outletId = widget.outletId;

      if (outletId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _allCategories = [];
            _error = "Outlet ID not found.";
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/categories?outletId=$outletId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allCategories = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCategories {
    List<Map<String, dynamic>> categories = _allCategories;

    if (_searchQuery.isNotEmpty) {
      categories = categories.where((category) {
        final name = category['name']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    return categories;
  }

  void _navigateToAddCategory() {
    // FIX: Use MaterialPageRoute to pass the outletId
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
      builder: (_) => TambahKategoriPage(outletId: widget.outletId),
    ))
        .then((result) {
      if (result == true) _fetchCategories();
    });
  }

  void _navigateToEditCategory(Map<String, dynamic> category) {
    // FIX: Use MaterialPageRoute to pass outletId and category data
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
      builder: (_) => TambahKategoriPage(
        kategori: category,
        outletId: widget.outletId,
      ),
    ))
        .then((result) {
      if (result == true) _fetchCategories();
    });
  }

  Future<void> _handleDelete(String categoryId, String categoryName) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/categories/$categoryId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _allCategories.removeWhere((cat) => cat['id'] == categoryId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Kategori "$categoryName" berhasil dihapus'),
              backgroundColor: Colors.green),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Gagal menghapus: ${errorData['message'] ?? 'Error server'}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String categoryName, String categoryId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Konfirmasi Hapus'),
          content:
          Text('Apakah Anda yakin ingin menghapus kategori "$categoryName"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleDelete(categoryId, categoryName);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalItems = _filteredCategories.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> categoriesOnCurrentPage =
    _filteredCategories.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile),
                      const SizedBox(height: 24),
                      _buildFilterActions(isMobile),
                      const SizedBox(height: 24),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Text('Gagal memuat data: $_error',
                                style: const TextStyle(color: Colors.red)),
                          ),
                        )
                      else if (isMobile)
                          _buildCategoryListMobile(categoriesOnCurrentPage)
                        else
                          _buildCategoryTable(categoriesOnCurrentPage),
                      const SizedBox(height: 24),
                      if (!_isLoading && _error == null && !isMobile)
                        _buildPagination(totalItems, totalPages),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title = const Text(
      'Daftar Kategori',
      style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
    );

    final button = ElevatedButton.icon(
      onPressed: _navigateToAddCategory,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Tambah Kategori', style: TextStyle(fontSize: 15)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF279E9E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: button),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          title,
          button,
        ],
      );
    }
  }

  Widget _buildFilterActions(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 250,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari kategori...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) => setState(() {
          _searchQuery = value;
          _currentPage = 1;
        }),
      ),
    );
  }

  Widget _buildCategoryListMobile(List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('Tidak ada kategori ditemukan.')));
    }

    return ListView.separated(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCardMobile(category);
      },
    );
  }

  Widget _buildCategoryCardMobile(Map<String, dynamic> category) {
    final String categoryName = category['name'] ?? 'N/A';
    final String categoryId = category['id'];
    final String urutan = category['order']?.toString() ?? 'N/A';
    final String jumlahProduk = '0';

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Urutan: $urutan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 24,
                  child: PopupMenuButton<String>(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (String value) {
                      if (value == 'ubah') {
                        _navigateToEditCategory(category);
                      } else if (value == 'hapus') {
                        _showDeleteConfirmationDialog(
                            context, categoryName, categoryId);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                      _buildPopupMenuItem(
                          value: 'ubah',
                          text: 'Ubah',
                          icon: Icons.edit_outlined),
                      _buildPopupMenuItem(
                          value: 'hapus',
                          text: 'Hapus',
                          icon: Icons.delete_outline,
                          isDestructive: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: Colors.grey[700], size: 20),
                const SizedBox(width: 12),
                Text('Jumlah Produk:',
                    style: TextStyle(color: Colors.grey[700])),
                const Spacer(),
                Text(jumlahProduk,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTable(List<Map<String, dynamic>> categories) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(children: [
              const SizedBox(width: 8),
              Expanded(
                  flex: 4,
                  child: Text('NAMA KATEGORI', style: _tableHeaderStyle())),
              Expanded(
                  flex: 2, child: Text('URUTAN', style: _tableHeaderStyle())),
              Expanded(
                  flex: 2,
                  child: Text('JUMLAH PRODUK', style: _tableHeaderStyle())),
              const SizedBox(width: 48),
            ]),
          ),
          const Divider(height: 1, color: Colors.grey),
          if (categories.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Tidak ada kategori ditemukan.'))
          else
            ...categories
                .map((category) => _buildCategoryTableRow(category))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryTableRow(Map<String, dynamic> category) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Expanded(
                  flex: 4,
                  child: Text(category['name'] ?? 'N/A',
                      style: _tableBodyStyle())),
              Expanded(
                  flex: 2,
                  child: Text(category['order']?.toString() ?? 'N/A',
                      style: _tableBodyStyle())),
              Expanded(
                  flex: 2,
                  child: Text('0', style: _tableBodyStyle())),
              SizedBox(
                width: 48,
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (String value) {
                    if (value == 'ubah') {
                      _navigateToEditCategory(category);
                    } else if (value == 'hapus') {
                      _showDeleteConfirmationDialog(
                          context, category['name'], category['id']);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                    _buildPopupMenuItem(
                        value: 'ubah',
                        text: 'Ubah',
                        icon: Icons.edit_outlined),
                    _buildPopupMenuItem(
                        value: 'hapus',
                        text: 'Hapus',
                        icon: Icons.delete_outline,
                        isDestructive: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(
            height: 1, indent: 24, endIndent: 24, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      {required String value,
        required String text,
        required IconData icon,
        bool isDestructive = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: isDestructive ? Colors.red : Colors.black54),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(color: isDestructive ? Colors.red : null)),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() {
    return TextStyle(
        fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);
  }

  TextStyle _tableBodyStyle() {
    return const TextStyle(fontSize: 14, color: Colors.black87);
  }

  Widget _buildPagination(int totalItems, int totalPages) {
    if (totalItems == 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Ditampilkan ${((_currentPage - 1) * _itemsPerPage + 1).clamp(1, totalItems)} - ${(_currentPage * _itemsPerPage).clamp(1, totalItems)} dari $totalItems data',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed:
          _currentPage > 1 ? () => setState(() => _currentPage--) : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFF279E9E),
              borderRadius: BorderRadius.circular(8)),
          child: Text('$_currentPage',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: _currentPage < totalPages
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }
}