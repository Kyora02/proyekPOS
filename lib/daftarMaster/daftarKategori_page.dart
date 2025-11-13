import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyekpos2/crud/tambahKategori_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

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
  final ScrollController _horizontalScrollController = ScrollController();

  List<Map<String, dynamic>> _allCategories = [];
  bool _isLoading = true;
  String? _error;

  int? _sortColumnIndex;
  bool _sortAscending = true;
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
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

  void _sortData(List<Map<String, dynamic>> categories) {
    if (_sortColumnIndex == null) {
      return;
    }
    categories.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      switch (_sortColumnIndex) {
        case 0:
          aValue = a['name'] ?? '';
          bValue = b['name'] ?? '';
          break;
        case 1:
          aValue = a['order'] ?? 0;
          bValue = b['order'] ?? 0;
          break;
        case 2:
          aValue = a['productQty'] ?? 0;
          bValue = b['productQty'] ?? 0;
          break;
        default:
          return 0;
      }
      int compare;
      if (aValue is num && bValue is num) {
        compare = aValue.compareTo(bValue);
      } else if (aValue is String && bValue is String) {
        compare = aValue.compareTo(bValue);
      } else {
        compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
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
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
      builder: (_) => TambahKategoriPage(outletId: widget.outletId),
    ))
        .then((result) {
      if (result == true) _fetchCategories();
    });
  }

  void _navigateToEditCategory(Map<String, dynamic> category) {
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
    final categories = _filteredCategories;
    _sortData(categories);
    final int totalItems = categories.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _fetchCategories,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleHeader(),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
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
                  else
                    _buildCategoryTable(categories),
                  const SizedBox(height: 24),
                  if (!_isLoading && _error == null)
                    _buildPagination(totalItems, totalPages),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Daftar Kategori',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _navigateToAddCategory,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Tambah Kategori', style: TextStyle(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 250,
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

  Widget _buildCategoryTable(List<Map<String, dynamic>> categories) {
    final int totalItems = categories.length;
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> categoriesOnCurrentPage =
    categories.sublist(startIndex, endIndex);

    // --- PERUBAHAN DI SINI ---
    // Logika untuk menampilkan kotak kosong yang konsisten
    if (categoriesOnCurrentPage.isEmpty) {
      final String message = _searchQuery.isNotEmpty
          ? 'Tidak ada kategori ditemukan.'
          : 'Belum ada kategori.';

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Disesuaikan
          border: Border.all(color: Colors.grey[200]!), // Disesuaikan
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0), // Disesuaikan
          child: Center(child: Text(message)),
        ),
      );
    }

    // --- PERUBAHAN DI SINI ---
    // Menyesuaikan gaya container tabel (border, BUKAN shadow)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Disesuaikan
        border: Border.all(color: Colors.grey[200]!), // Disesuaikan
      ),
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalScrollController,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 230.0,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingTextStyle: _tableHeaderStyle(),
              dataTextStyle: _tableBodyStyle(),
              columns: [
                DataColumn(
                  label: const Text('NAMA KATEGORI'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: Center(child: const Text('URUTAN')),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: Center(child: const Text('JUMLAH PRODUK')),
                  onSort: _onSort,
                ),
                const DataColumn(
                  label: Text('AKSI'),
                ),
              ],
              rows: categoriesOnCurrentPage.map((category) {
                final String categoryName = category['name'] ?? 'N/A';
                final String categoryId = category['id'];
                return DataRow(
                  cells: [
                    DataCell(Text(categoryName)),
                    DataCell(Center(
                        child: Text(category['order']?.toString() ?? 'N/A'))),
                    DataCell(Center(
                        child: Text(category['productQty']?.toString() ?? '0'))),
                    DataCell(
                      PopupMenuButton<String>(
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
                );
              }).toList(),
            ),
          ),
        ),
      ),
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

    final Widget leftSide = Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Tampilkan:', style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _itemsPerPage,
              onChanged: (int? newValue) {
                setState(() {
                  _itemsPerPage = newValue!;
                  _currentPage = 1;
                });
              },
              items: <int>[10, 20, 50]
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Ditampilkan ${((_currentPage - 1) * _itemsPerPage + 1).clamp(1, totalItems)} - ${math.min(_currentPage * _itemsPerPage, totalItems)} dari $totalItems data',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );

    final Widget rightSide = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: leftSide),
        rightSide,
      ],
    );
  }
}