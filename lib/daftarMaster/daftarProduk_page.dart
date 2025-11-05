import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/crud/tambahProduk_page.dart';
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
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _kategoriOptions = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String? _selectedCategoryId;
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchProductsAndCategoriesForOutlet(widget.outletId);
  }

  Future<void> _fetchProductsAndCategoriesForOutlet(String outletId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _allProducts = [];
    });

    try {
      // Fetch categories based on the active outlet
      final categories = await _apiService.getCategories(outletId: outletId);
      _kategoriOptions = [
        {'id': 'semua', 'name': 'Semua Kategori'},
        ...categories
      ];

      // Fetch products based on the active outlet
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
    final totalItems = products.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double webBreakpoint = 720.0;

        if (constraints.maxWidth > webBreakpoint) {
          return _buildWebLayout(context, products, totalItems, totalPages);
        } else {
          return _buildMobileLayout(context, products, totalItems, totalPages);
        }
      },
    );
  }

  Widget _buildWebLayout(BuildContext context,
      List<Map<String, dynamic>> products, int totalItems, int totalPages) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderWeb(),
              const SizedBox(height: 24),
              _buildFilterAndActionButtonWeb(),
              const SizedBox(height: 24),
              _buildProductTableWeb(products),
              const SizedBox(height: 24),
              _buildPaginationWeb(totalItems, totalPages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWeb() {
    return Row(
      children: [
        const Text(
          'Daftar Produk',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _navigateToAddProduct,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Tambah Produk', style: TextStyle(fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndActionButtonWeb() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // REMOVED: Outlet Dropdown is no longer needed here
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
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategoryId = newValue;
                  _currentPage = 1;
                });
              },
              items: _kategoriOptions
                  .map<DropdownMenuItem<String>>((Map<String, dynamic> value) {
                return DropdownMenuItem<String>(
                  value: value['id'],
                  child: Text(value['name']),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductTableWeb(List<Map<String, dynamic>> products) {
    final int totalItems = products.length;
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> productsOnCurrentPage =
    products.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                    flex: 3,
                    child: Text('NAMA PRODUK', style: _tableHeaderStyle())),
                Expanded(
                    flex: 2, child: Text('SKU', style: _tableHeaderStyle())),
                Expanded(
                    flex: 2,
                    child: Text('KATEGORI', style: _tableHeaderStyle())),
                Expanded(
                    flex: 2,
                    child: Text('HARGA BELI', style: _tableHeaderStyle())),
                Expanded(
                    flex: 2,
                    child: Text('HARGA JUAL', style: _tableHeaderStyle())),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            )
          else if (productsOnCurrentPage.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Tidak ada produk ditemukan.'),
            )
          else
            ...productsOnCurrentPage
                .map((product) => _buildProductTableRowWeb(product))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildProductTableRowWeb(Map<String, dynamic> product) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(product['name'] ?? 'N/A', style: _tableBodyStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text(product['sku'] ?? 'N/A', style: _tableBodyStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text(_getCategoryName(product['categoryId'] ?? ''),
                    style: _tableBodyStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text(_formatCurrency(product['costPrice'] ?? 0),
                    style: _tableBodyStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text(_formatCurrency(product['sellingPrice'] ?? 0),
                    style: _tableBodyStyle()),
              ),
              SizedBox(
                width: 48,
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (String value) {
                    switch (value) {
                      case 'ubah':
                        _navigateToEditProduct(product);
                        break;
                      case 'hapus':
                        _showDeleteConfirmationDialog(
                            context, product['id'], product['name']);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'ubah',
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
                      value: 'hapus',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
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

  TextStyle _tableHeaderStyle() {
    return TextStyle(
        fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);
  }

  TextStyle _tableBodyStyle() {
    return const TextStyle(fontSize: 14, color: Colors.black87);
  }

  Widget _buildPaginationWeb(int totalItems, int totalPages) {
    if (totalItems == 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
                  items: <int>[10, 20, 50, 100]
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
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
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

  Widget _buildMobileLayout(BuildContext context,
      List<Map<String, dynamic>> products, int totalItems, int totalPages) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Daftar Produk',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchProductsAndCategoriesForOutlet(widget.outletId),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddProduct,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Tambah Produk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF279E9E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            _buildFilterAndSearchMobile(),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: _buildProductListMobile(products),
              ),
            _buildPaginationMobile(totalItems, totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterAndSearchMobile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        children: [
          // REMOVED: Outlet Dropdown
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk (nama atau SKU)...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: Colors.white,
                value: _selectedCategoryId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategoryId = newValue;
                    _currentPage = 1;
                  });
                },
                items: _kategoriOptions
                    .map<DropdownMenuItem<String>>((Map<String, dynamic> value) {
                  return DropdownMenuItem<String>(
                    value: value['id'],
                    child: Text(value['name']),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListMobile(List<Map<String, dynamic>> products) {
    final int totalItems = products.length;
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> productsOnCurrentPage =
    products.sublist(startIndex, endIndex);

    if (productsOnCurrentPage.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
              _searchQuery.isEmpty && _selectedCategoryId == 'semua'
                  ? 'Belum ada produk.'
                  : 'Tidak ada produk ditemukan.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
      itemCount: productsOnCurrentPage.length,
      itemBuilder: (context, index) {
        final product = productsOnCurrentPage[index];
        return _buildProductCardMobile(product);
      },
    );
  }

  Widget _buildProductCardMobile(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
                        product['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${product['sku'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: PopupMenuButton<String>(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (String value) {
                      switch (value) {
                        case 'ubah':
                          _navigateToEditProduct(product);
                          break;
                        case 'hapus':
                          _showDeleteConfirmationDialog(
                              context, product['id'], product['name']);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'ubah',
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
                        value: 'hapus',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRowMobile(
              Icons.category_outlined,
              'Kategori',
              _getCategoryName(product['categoryId'] ?? ''),
            ),
            const SizedBox(height: 10),
            _buildDetailRowMobile(
              Icons.shopping_bag_outlined,
              'Harga Beli',
              _formatCurrency(product['costPrice'] ?? 0),
            ),
            const SizedBox(height: 10),
            _buildDetailRowMobile(
              Icons.sell_outlined,
              'Harga Jual',
              _formatCurrency(product['sellingPrice'] ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRowMobile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Text(
          '$title:',
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF333333)),
        ),
      ],
    );
  }

  Widget _buildPaginationMobile(int totalItems, int totalPages) {
    if (totalItems == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${((_currentPage - 1) * _itemsPerPage + 1).clamp(1, totalItems)} - ${math.min(_currentPage * _itemsPerPage, totalItems)} dari $totalItems',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                disabledColor: Colors.grey[300],
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                disabledColor: Colors.grey[300],
              ),
            ],
          ),
        ],
      ),
    );
  }
}