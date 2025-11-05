import 'package:flutter/material.dart';
import 'package:proyekpos2/crud/tambahStok_page.dart';
import 'package:proyekpos2/service/api_service.dart';

class DaftarStokPage extends StatefulWidget {
  final String outletId;

  const DaftarStokPage({
    super.key,
    required this.outletId,
  });
  @override
  State<DaftarStokPage> createState() => _DaftarStokPageState();
}

class _DaftarStokPageState extends State<DaftarStokPage> {
  final TextEditingController _searchController = TextEditingController();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allStockFromServer = [];
  List<Map<String, dynamic>> _filteredStockList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStock();
    _searchController.addListener(_filterStock);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStock);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStock() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> data =
      await _apiService.getAllStock(outletId: widget.outletId);

      setState(() {
        _allStockFromServer = data;
        _filterStock();
      });
    } catch (e) {
      setState(() {
        _error = "Terjadi kesalahan: ${e.toString()}";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterStock() {
    setState(() {
      _filteredStockList = _allStockFromServer.where((stock) {
        final query = _searchController.text.toLowerCase();
        final name = stock['name']?.toLowerCase() ?? '';
        final sku = stock['sku']?.toLowerCase() ?? '';

        final matchesSearch = name.contains(query) || sku.contains(query);

        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _navigateToAddStock() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => TambahStokPage(outletId: widget.outletId),
      ),
    );
    _fetchStock();
  }

  void _navigateToEditProduct(Map<String, dynamic> productStock) {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahStokPage(
          s: productStock,
          outletId: widget.outletId,
        ),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchStock();
      }
    });
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, Map<String, dynamic> stock) async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Konfirmasi Hapus'),
            content: Text(
                'Apakah Anda yakin ingin menghapus produk "${stock['name']}"? Ini akan menghapus produk dari semua outlet.'),
            actions: <Widget>[
              TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(dialogContext).pop()),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Hapus'),
                onPressed: () async {
                  try {
                    // Gunakan 'id' dari stok (yang merupakan productId)
                    await _apiService.deleteProduct(stock['id']);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                          Text('Produk "${stock['name']}" berhasil dihapus'),
                          backgroundColor: Colors.green),
                    );
                    _fetchStock();
                  } catch (e) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Gagal menghapus produk: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Stok',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddStock,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Tambah Stok'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF279E9E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSearchbar(),
                const SizedBox(height: 24),
                _buildStockList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchbar() {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari stok...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStockList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildStockTableHeader(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              )
            else if (_filteredStockList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(
                    child: Text(
                      'Tidak ada stok ditemukan.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._filteredStockList
                    .map((stock) => _buildStockItem(stock))
                    .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStockTableHeader() {
    TextStyle headerStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('SKU', style: headerStyle)),
          Expanded(flex: 3, child: Text('NAMA PRODUK', style: headerStyle)),
          Expanded(flex: 2, child: Text('KATEGORI', style: headerStyle)),
          Expanded(flex: 1, child: Text('STOK', style: headerStyle)),
          const SizedBox(width: 48), // RUANG UNTUK TOMBOL AKSI
        ],
      ),
    );
  }

  Widget _buildStockItem(Map<String, dynamic> stock) {
    TextStyle cellStyle = const TextStyle(fontSize: 14, color: Colors.black87);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(stock['sku'] ?? 'N/A', style: cellStyle)),
          Expanded(
              flex: 3, child: Text(stock['name'] ?? 'N/A', style: cellStyle)),
          Expanded(
              flex: 2,
              child: Text(stock['kategori'] ?? 'N/A', style: cellStyle)),
          Expanded(
              flex: 1,
              child: Text(stock['stok']?.toString() ?? '0', style: cellStyle)),
          _buildPopupMenuButton(stock),
        ],
      ),
    );
  }

  Widget _buildPopupMenuButton(Map<String, dynamic> stock) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        color: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        icon: const Icon(Icons.more_horiz),
        onSelected: (String value) {
          if (value == 'hapus') {
            _showDeleteConfirmationDialog(context, stock);
          } else if (value == 'ubah') {
            _navigateToEditProduct(stock);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          _buildPopupMenuItem(
              value: 'ubah', text: 'Ubah', icon: Icons.edit_outlined),
          _buildPopupMenuItem(
              value: 'hapus',
              text: 'Hapus',
              icon: Icons.delete_outline,
              isDestructive: true),
        ],
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
}