import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/crud/tambahProduk_page.dart';
import 'package:proyekpos2/detail/detailProduk_page.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'dart:math' as math;

class DaftarProdukPage extends StatefulWidget {
  final String outletId;
  const DaftarProdukPage({
    super.key,
    required this.outletId,
  });
  @override
  State<DaftarProdukPage> createState() => _DaftarProdukPageState();
}

class _DaftarProdukPageState extends State<DaftarProdukPage> {
  final _apiService = ApiService();
  final ScrollController _horizontalScrollController = ScrollController();
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _kategoriOptions = [];
  bool _isLoading = true;
  String? _error;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  String _searchQuery = '';
  String? _selectedCategoryId;

  String _statusFilter = 'all';

  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchProductsAndCategoriesForOutlet(widget.outletId);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductsAndCategoriesForOutlet(String outletId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _allProducts = [];
    });

    try {
      final categories = await _apiService.getCategories(outletId: outletId);
      _kategoriOptions = [
        {'id': 'semua', 'name': 'Semua Kategori'},
        ...categories
      ];

      final products = await _apiService.getProducts(outletId: outletId);

      if (mounted) {
        setState(() {
          _allProducts = products;
          _selectedCategoryId = 'semua';
          _currentPage = 1;
          _isLoading = false;
        });
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

  void _sortData(List<Map<String, dynamic>> products) {
    if (_sortColumnIndex == null) {
      return;
    }

    products.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortColumnIndex) {
        case 0:
          aValue = a['name'] ?? '';
          bValue = b['name'] ?? '';
          break;
        case 1:
          aValue = a['sku'] ?? '';
          bValue = b['sku'] ?? '';
          break;
        case 2:
          aValue = _getCategoryName(a['categoryId'] ?? '');
          bValue = _getCategoryName(b['categoryId'] ?? '');
          break;
        case 3:
          aValue = a['stok'] ?? 0;
          bValue = b['stok'] ?? 0;
          break;
        case 4:
          aValue = a['costPrice'] ?? 0;
          bValue = b['costPrice'] ?? 0;
          break;
        case 5:
          aValue = a['sellingPrice'] ?? 0;
          bValue = b['sellingPrice'] ?? 0;
          break;
        case 6:
          aValue = (a['showInMenu'] ?? true) ? 1 : 0;
          bValue = (b['showInMenu'] ?? true) ? 1 : 0;
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

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> products = _allProducts;

    if (_searchQuery.isNotEmpty) {
      products = products.where((product) {
        final name = product['name']?.toLowerCase() ?? '';
        final sku = product['sku']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || sku.contains(query);
      }).toList();
    }

    if (_selectedCategoryId != null && _selectedCategoryId != 'semua') {
      products = products.where((product) {
        return product['categoryId'] == _selectedCategoryId;
      }).toList();
    }

    if (_statusFilter == 'show') {
      products = products.where((p) => p['showInMenu'] == true || p['showInMenu'] == null).toList();
    } else if (_statusFilter == 'hide') {
      products = products.where((p) => p['showInMenu'] == false).toList();
    }

    return products;
  }

  String _getCategoryName(String categoryId) {
    try {
      return _kategoriOptions
          .firstWhere((cat) => cat['id'] == categoryId)['name'];
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  void _navigateToAddProduct() {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
      builder: (_) => TambahProdukPage(outletId: widget.outletId),
    ))
        .then((success) {
      if (success == true) {
        _fetchProductsAndCategoriesForOutlet(widget.outletId);
      }
    });
  }

  void _navigateToEditProduct(Map<String, dynamic> product) {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
      builder: (_) => TambahProdukPage(
        product: product,
        outletId: widget.outletId,
      ),
    ))
        .then((success) {
      if (success == true) {
        _fetchProductsAndCategoriesForOutlet(widget.outletId);
      }
    });
  }

  Future<void> _handleDelete(String productId, String productName) async {
    try {
      await _apiService.deleteProduct(productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Produk "$productName" berhasil dihapus'),
              backgroundColor: Colors.green),
        );
        _fetchProductsAndCategoriesForOutlet(widget.outletId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String productId, String productName) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Konfirmasi Hapus'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda yakin ingin menghapus produk "$productName"?'),
                const SizedBox(height: 8),
                const Text('Tindakan ini tidak dapat dibatalkan.',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleDelete(productId, productName);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Gagal memuat data: $_error',
                style: const TextStyle(color: Colors.red)),
          ));
    }

    final products = _filteredProducts;
    _sortData(products);
    final totalItems = products.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () => _fetchProductsAndCategoriesForOutlet(widget.outletId),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilterAndActionButton(),
                  const SizedBox(height: 24),
                  _buildProductTable(products),
                  const SizedBox(height: 24),
                  _buildPagination(totalItems, totalPages),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Daftar Produk',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(width: 8),
        isMobile
            ? IconButton(
          onPressed: _navigateToAddProduct,
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
        )
            : ElevatedButton.icon(
          onPressed: _navigateToAddProduct,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tambah Produk', style: TextStyle(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndActionButton() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 1;
              });
            },
          ),
        ),
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              value: _selectedCategoryId,
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategoryId = newValue;
                  _currentPage = 1;
                });
              },
              items: _kategoriOptions.map<DropdownMenuItem<String>>(
                      (Map<String, dynamic> value) {
                    return DropdownMenuItem<String>(
                      value: value['id'],
                      child: Text(value['name'], overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
            ),
          ),
        ),
        Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              value: _statusFilter,
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  _statusFilter = newValue!;
                  _currentPage = 1;
                });
              },
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua Status', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'show', child: Text('Tampil di Menu', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'hide', child: Text('Sembunyi', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductTable(List<Map<String, dynamic>> products) {
    final int totalItems = products.length;
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> productsOnCurrentPage =
    products.sublist(startIndex, endIndex);

    if (productsOnCurrentPage.isEmpty) {
      final String message = _searchQuery.isNotEmpty
          ? 'Tidak ada produk ditemukan.'
          : 'Belum ada produk.';

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0),
          child: Center(child: Text(message)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
              columnSpacing: 80.0,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingTextStyle: _tableHeaderStyle(),
              dataTextStyle: _tableBodyStyle(),
              columns: [
                DataColumn(
                  label: const Text('NAMA PRODUK'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('SKU'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('KATEGORI'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('STOK'),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('HARGA MODAL'),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('HARGA JUAL'),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('STATUS'),
                  onSort: _onSort,
                ),
                const DataColumn(
                  label: Text('AKSI'),
                ),
              ],
              rows: productsOnCurrentPage.map((product) {
                final bool isShown = product['showInMenu'] ?? true;
                return DataRow(
                  cells: [
                    DataCell(Text(product['name'] ?? 'N/A')),
                    DataCell(Text(product['sku'] ?? 'N/A')),
                    DataCell(
                        Text(_getCategoryName(product['categoryId'] ?? ''))),
                    DataCell(Text((product['stok'] ?? 0).toString())),
                    DataCell(Text(_formatCurrency(product['costPrice'] ?? 0))),
                    DataCell(
                        Text(_formatCurrency(product['sellingPrice'] ?? 0))),

                    DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: isShown ? Colors.green[50] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isShown ? Colors.green[200]! : Colors.grey[300]!)
                          ),
                          child: Text(
                            isShown ? 'Aktif' : 'Tidak Aktif',
                            style: TextStyle(
                                color: isShown ? Colors.green[700] : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        )
                    ),

                    DataCell(
                      PopupMenuButton<String>(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (String value) {
                          switch (value) {
                            case 'Ubah':
                              _navigateToEditProduct(product);
                              break;
                            case 'Detail':
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => DetailProdukPage(
                                    product: product,
                                    categoryName: _getCategoryName(product['categoryId'] ?? ''),
                                  ),
                                ),
                              );
                              break;
                            case 'Hapus':
                              _showDeleteConfirmationDialog(
                                  context, product['id'], product['name']);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'Ubah',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 20, color: Colors.black54),
                                SizedBox(width: 12),
                                Text('Ubah'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                              value: 'Detail',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20, color: Colors.black54),
                                  SizedBox(width: 12),
                                  Text('Detail'),
                                ],
                              )
                          ),
                          const PopupMenuItem<String>(
                            value: 'Hapus',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Hapus',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
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

  TextStyle _tableHeaderStyle() {
    return TextStyle(
        fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);
  }

  TextStyle _tableBodyStyle() {
    return const TextStyle(fontSize: 14, color: Colors.black87);
  }

  Widget _buildPagination(int totalItems, int totalPages) {
    if (totalItems == 0) return const SizedBox.shrink();

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final int startItem = ((_currentPage - 1) * _itemsPerPage + 1).clamp(1, totalItems);
    final int endItem = math.min(_currentPage * _itemsPerPage, totalItems);

    if (isMobile) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tampilkan:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      dropdownColor: Colors.white,
                      value: _itemsPerPage,
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ditampilkan $startItem - $endItem dari $totalItems data',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: _currentPage > 1 ? const Color(0xFF279E9E) : Colors.grey[400],
                ),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF279E9E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _currentPage < totalPages ? const Color(0xFF279E9E) : Colors.grey[400],
                ),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
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
                    dropdownColor: Colors.white,
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
                'Ditampilkan $startItem - $endItem dari $totalItems data',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Row(
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_currentPage',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: _currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}