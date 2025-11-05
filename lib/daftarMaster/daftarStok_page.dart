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

        final matchesSearch =
            name.contains(query) || sku.contains(query);

        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _navigateToAddStock() async {
    // UPDATED: Use MaterialPageRoute to pass outletId
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => TambahStokPage(outletId: widget.outletId),
      ),
    );

    // Muat ulang data setelah kembali
    _fetchStock();
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
        ],
      ),
    );
  }
}