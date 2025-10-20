import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DaftarProdukPage extends StatefulWidget {
  const DaftarProdukPage({super.key});

  @override
  State<DaftarProdukPage> createState() => _DaftarProdukPageState();
}

class _DaftarProdukPageState extends State<DaftarProdukPage> {
  final List<Map<String, dynamic>> _dummyProducts = [
    {
      "productName": "Kopi Susu Gula Aren",
      "sku": "KS-001",
      "sellingPrice": 22000,
      "costPrice": 10000,
      "stock": 50,
      "category": "Minuman Kopi",
    },
    {
      "productName": "Americano",
      "sku": "AM-001",
      "sellingPrice": 18000,
      "costPrice": 7000,
      "stock": 35,
      "category": "Minuman Kopi",
    },
  ];

  String _searchQuery = '';
  String? _selectedCategory;
  int _currentPage = 1;
  int _itemsPerPage = 10;

  final List<String> _categories = [
    'Semua Kategori',
    'Minuman Kopi',
    'Makanan',
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> products = _dummyProducts;

    if (_searchQuery.isNotEmpty) {
      products = products.where((product) {
        final name = product['productName']?.toLowerCase() ?? '';
        final sku = product['sku']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || sku.contains(query);
      }).toList();
    }

    if (_selectedCategory != null && _selectedCategory != 'Semua Kategori') {
      products = products.where((product) {
        return product['category'] == _selectedCategory;
      }).toList();
    }

    return products;
  }

  void _navigateToAddProduct() {
    Navigator.of(context, rootNavigator: true).pushNamed('/tambah-produk');
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String productName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Konfirmasi Hapus'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Apakah Anda yakin ingin menghapus produk "$productName"?'),
                const SizedBox(height: 8),
                const Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(fontWeight: FontWeight.bold)),
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
                // TODO: Implementasikan logika penghapusan data di sini (misal dari database)
                Navigator.of(context).pop(); // Tutup dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Produk "$productName" berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final int totalItems = _filteredProducts.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();

    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> productsOnCurrentPage =
    _filteredProducts.sublist(startIndex, endIndex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
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
              _buildProductTable(productsOnCurrentPage),
              const SizedBox(height: 24),
              _buildPagination(totalItems, totalPages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
        // Tombol Tambah Produk
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
        // Category Dropdown
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
              // --- THIS IS THE FIX ---
              dropdownColor: Colors.white,
              // --- END OF FIX ---
              value: _selectedCategory ?? _categories.first,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  _currentPage = 1;
                });
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filter "$label" dipilih: $selected'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      },
      selectedColor: const Color(0xFF279E9E),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.transparent : Colors.grey[300]!,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildProductTable(List<Map<String, dynamic>> products) {
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
          // Header tabel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Checkbox(value: false, onChanged: (val) {}),
                const SizedBox(width: 8),
                Expanded(
                    flex: 3,
                    child: Text('NAMA PRODUK',
                        style: _tableHeaderStyle())),
                Expanded(
                    flex: 2, child: Text('SKU', style: _tableHeaderStyle())),
                Expanded(
                    flex: 2,
                    child: Text('KATEGORI',
                        style: _tableHeaderStyle())),
                Expanded(
                    flex: 2,
                    child: Text('HARGA BELI',
                        style: _tableHeaderStyle())),
                Expanded(
                    flex: 2,
                    child: Text('HARGA JUAL',
                        style: _tableHeaderStyle())),
                Expanded(
                    flex: 1, child: Text('STOK', style: _tableHeaderStyle())),
                const SizedBox(width: 48), // Untuk menu ellipsis
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),

          // Baris data produk
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Tidak ada produk ditemukan.'),
            )
          else
            ...products.map((product) => _buildProductTableRow(product)).toList(),
        ],
      ),
    );
  }

  Widget _buildProductTableRow(Map<String, dynamic> product) {
    String formatCurrency(int amount) {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(value: false, onChanged: (val) {}),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(product['productName'] ?? 'N/A',
                    style: _tableBodyStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text(product['sku'] ?? 'N/A', style: _tableBodyStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text(product['category'] ?? 'N/A',
                    style: _tableBodyStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text(formatCurrency(product['costPrice'] ?? 0),
                    style: _tableBodyStyle()),
              ),
              Expanded(
                flex: 2,
                child: Text(formatCurrency(product['sellingPrice'] ?? 0),
                    style: _tableBodyStyle()),
              ),
              Expanded(
                flex: 1,
                child: Text(product['stock']?.toString() ?? '0',
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ubah: ${product['productName']}')),
                        );
                        break;
                      case 'hapus':
                        _showDeleteConfirmationDialog(context, product['productName']);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'ubah',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: Colors.black54),
                          SizedBox(width: 12),
                          Text('Ubah'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'hapus',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
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
        const Divider(height: 1, indent: 24, endIndent: 24, color: Color(0xFFEEEEEE)),
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

  Widget _buildPagination(int totalItems, int totalPages) {
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
                  items: <int>[10, 20, 50, 100].map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text('Ditampilkan ${(
                (_currentPage - 1) * _itemsPerPage + 1
            ).clamp(1, totalItems)} - ${(
                _currentPage * _itemsPerPage
            ).clamp(1, totalItems)} dari $totalItems data',
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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