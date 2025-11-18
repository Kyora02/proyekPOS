import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'service/api_service.dart';
import 'login_page.dart';

class KaryawanDashboardPage extends StatefulWidget {
  final Map<String, dynamic> karyawanData;
  final String karyawanId;

  const KaryawanDashboardPage({
    super.key,
    required this.karyawanData,
    required this.karyawanId,
  });

  @override
  State<KaryawanDashboardPage> createState() => _KaryawanDashboardPageState();
}

class _KaryawanDashboardPageState extends State<KaryawanDashboardPage> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _cartItems = [];

  bool _isLoading = true;
  String _selectedCategoryId = 'all';

  double _subtotal = 0.0;
  double _pajak = 0.0;
  double _total = 0.0;
  final double _pajakRate = 0.10;

  final Color _primaryColor = const Color(0xFF00A3A3);
  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final String outletId = widget.karyawanData['outletId'] ?? '';

      if (outletId.isEmpty) throw Exception("Outlet ID tidak ditemukan");

      final results = await Future.wait([
        _apiService.getCategories(outletId: outletId),
        _apiService.getProducts(outletId: outletId),
      ]);

      setState(() {
        _categories = results[0];
        _allProducts = results[1];
        _filteredProducts = _allProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      if (categoryId == 'all') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((p) => p['categoryId'] == categoryId)
            .toList();
      }
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final String id = product['_id'] ?? product['id'];
      final String name = product['name'] ?? 'Produk';
      final double price = (product['sellingPrice'] ?? 0).toDouble();

      int index = _cartItems.indexWhere((item) => item['id'] == id);

      if (index != -1) {
        _cartItems[index]['quantity']++;
      } else {
        _cartItems.add({
          'id': id,
          'nama': name,
          'harga': price,
          'quantity': 1,
        });
      }
      _calculateTotals();
    });
  }

  void _incrementQuantity(int index) {
    setState(() {
      _cartItems[index]['quantity']++;
      _calculateTotals();
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_cartItems[index]['quantity'] > 1) {
        _cartItems[index]['quantity']--;
      } else {
        _cartItems.removeAt(index);
      }
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    for (var item in _cartItems) {
      subtotal += (item['harga'] * item['quantity']);
    }
    setState(() {
      _subtotal = subtotal;
      _pajak = _subtotal * _pajakRate;
      _total = _subtotal + _pajak;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    }
  }

  void _showPaymentDialog() {
    if (_cartItems.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Text('Total: ${_currencyFormat.format(_total)}\n\nLanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () {
              setState(() {
                _cartItems.clear();
                _calculateTotals();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaksi Berhasil!')),
              );
            },
            child:
            const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMobileCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border:
                      Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Keranjang',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cartItems.isEmpty
                        ? const Center(child: Text("Keranjang Kosong"))
                        : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item['nama'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(_currencyFormat.format(
                                item['harga'] * item['quantity'])),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    _decrementQuantity(index);
                                    setSheetState(() {});
                                  },
                                ),
                                Text('${item['quantity']}'),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline,
                                      color: _primaryColor),
                                  onPressed: () {
                                    _incrementQuantity(index);
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(_currencyFormat.format(_total),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _primaryColor))
                            ]),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showPaymentDialog();
                            },
                            child: const Text('BAYAR'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String namaKaryawan = widget.karyawanData['nama'] ?? 'Karyawan';

    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir : $namaKaryawan'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: (val) {
              setState(() {
                _filteredProducts = _allProducts
                    .where((p) =>
                p['name']
                    .toString()
                    .toLowerCase()
                    .contains(val.toLowerCase()) &&
                    (_selectedCategoryId == 'all' ||
                        p['categoryId'] == _selectedCategoryId))
                    .toList();
              });
            },
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildMobileCategoryChip('all', 'Semua'),
              ..._categories.map((cat) => _buildMobileCategoryChip(
                  cat['_id'] ?? '', cat['name'] ?? 'No Name')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredProducts.isEmpty
              ? const Center(child: Text("Tidak ada produk"))
              : GridView.builder(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) =>
                _buildProductCard(_filteredProducts[index]),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Total", style: TextStyle(fontSize: 12)),
                  Text(
                    _currencyFormat.format(_total),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showMobileCartSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.shopping_cart),
                label: Text('Keranjang (${_cartItems.length})'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[100],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  color: Colors.white,
                  child: const Text("Kategori",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildCategoryTile('all', 'Semua Produk'),
                      // FIX: Check for 'id' first, then '_id'
                      ..._categories.map((cat) => _buildCategoryTile(
                          cat['id'] ?? cat['_id'] ?? '',
                          cat['name'] ?? 'No Name')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0, horizontal: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filteredProducts = _allProducts
                          .where((p) =>
                      p['name']
                          .toString()
                          .toLowerCase()
                          .contains(val.toLowerCase()) &&
                          (_selectedCategoryId == 'all' ||
                              p['categoryId'] == _selectedCategoryId))
                          .toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: _filteredProducts.isEmpty
                    ? const Center(child: Text("Tidak ada produk"))
                    : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(_filteredProducts[index]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!))),
                  child: const Text('Keranjang',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          title: Text(item['nama'],
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(_currencyFormat
                              .format(item['harga'] * item['quantity'])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () => _decrementQuantity(index),
                                constraints: const BoxConstraints(),
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('${item['quantity']}'),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: _primaryColor),
                                onPressed: () => _incrementQuantity(index),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildCartSummary(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCategoryChip(String id, String name) {
    final bool isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        selectedColor: _primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? _primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) _filterProducts(id);
        },
      ),
    );
  }

  Widget _buildCategoryTile(String id, String name) {
    final bool isSelected = _selectedCategoryId == id;
    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? _primaryColor : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white,
      onTap: () => _filterProducts(id),
      leading: isSelected
          ? Icon(Icons.check_circle, size: 18, color: _primaryColor)
          : null,
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final double price = (product['sellingPrice'] ?? 0).toDouble();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _addToCart(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[200],
                width: double.infinity,
                child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(price),
                    style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Subtotal'),
            Text(_currencyFormat.format(_subtotal))
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Pajak (10%)'),
            Text(_currencyFormat.format(_pajak))
          ]),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(_currencyFormat.format(_total),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _primaryColor))
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _showPaymentDialog,
              child: const Text('BAYAR'),
            ),
          ),
        ],
      ),
    );
  }
}