import 'package:flutter/material.dart';
import 'package:proyekpos2/crud/tambahPelanggan_page.dart';
import 'package:proyekpos2/service/api_service.dart';

class DaftarPelangganPage extends StatefulWidget {
  final String outletId;

  const DaftarPelangganPage({
    super.key,
    required this.outletId,
  });

  @override
  State<DaftarPelangganPage> createState() => _DaftarPelangganPageState();
}

class _DaftarPelangganPageState extends State<DaftarPelangganPage> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _allPelanggan = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchPelanggan();
  }

  Future<void> _fetchPelanggan() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pelanggan = await _apiService.getPelanggan(outletId: widget.outletId);
      if (mounted) {
        setState(() {
          _allPelanggan = pelanggan;
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

  List<Map<String, dynamic>> get _filteredPelanggan {
    List<Map<String, dynamic>> items = _allPelanggan;

    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final name = item['name']?.toLowerCase() ?? '';
        final phone = item['phone']?.toLowerCase() ?? '';
        final email = item['email']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            email.contains(query);
      }).toList();
    }

    return items;
  }

  void _navigateToAddPelanggan() {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahPelangganPage(outletId: widget.outletId),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchPelanggan();
      }
    });
  }

  void _navigateToEditPelanggan(Map<String, dynamic> pelanggan) {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahPelangganPage(
          pelanggan: pelanggan,
          outletId: widget.outletId,
        ),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchPelanggan();
      }
    });
  }

  Future<void> _handleDelete(String id, String name) async {
    try {
      await _apiService.deletePelanggan(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Pelanggan "$name" berhasil dihapus'),
              backgroundColor: Colors.green),
        );
        _fetchPelanggan();
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
      BuildContext context, String name, String id) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus "$name"?'),
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
                _handleDelete(id, name);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalItems = _filteredPelanggan.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> itemsOnCurrentPage =
    _filteredPelanggan.sublist(startIndex, endIndex);

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
                      _buildFilterActions(),
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
                        _buildPelangganTable(itemsOnCurrentPage),
                      const SizedBox(height: 24),
                      if (!_isLoading && _error == null)
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
      'Daftar Pelanggan',
      style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
    );

    final button = ElevatedButton.icon(
      onPressed: _navigateToAddPelanggan,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Tambah Pelanggan', style: TextStyle(fontSize: 15)),
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

  Widget _buildFilterActions() {
    return SizedBox(
      width: 250,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari pelanggan...',
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

  Widget _buildPelangganTable(List<Map<String, dynamic>> items) {
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
                  flex: 3,
                  child: Text('NAMA', style: _tableHeaderStyle())),
              Expanded(
                  flex: 3,
                  child: Text('EMAIL', style: _tableHeaderStyle())),
              Expanded(
                  flex: 4,
                  child: Text('ALAMAT', style: _tableHeaderStyle())),
              Expanded(
                  flex: 3,
                  child: Text('NOMOR TELEPON', style: _tableHeaderStyle())),
              Expanded(
                  flex: 2,
                  child: Text('JENIS KELAMIN', style: _tableHeaderStyle())),
              const SizedBox(width: 48),
            ]),
          ),
          const Divider(height: 1, color: Colors.grey),
          if (items.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Tidak ada pelanggan ditemukan.'))
          else
            ...items.map((item) => _buildPelangganTableRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildPelangganTableRow(Map<String, dynamic> item) {
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
                  child: Text(item['name'] ?? 'N/A', style: _tableBodyStyle())),
              Expanded(
                  flex: 3,
                  child: Text(item['email'] ?? 'N/A', style: _tableBodyStyle())),
              Expanded(
                  flex: 4,
                  child: Text(item['address'] ?? 'N/A', style: _tableBodyStyle())),
              Expanded(
                  flex: 3,
                  child: Text(item['phone'] ?? 'N/A', style: _tableBodyStyle())),
              Expanded(
                  flex: 2,
                  child: Text(item['gender'] ?? 'N/A', style: _tableBodyStyle())),
              SizedBox(
                width: 48,
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (String value) {
                    if (value == 'ubah') {
                      _navigateToEditPelanggan(item);
                    } else if (value == 'hapus') {
                      _showDeleteConfirmationDialog(
                          context, item['name'], item['id']);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                    _buildPopupMenuItem(
                        value: 'ubah',
                        text: 'Ubah',
                        icon: Icons.edit_outlined),
                    _buildPopupMenuItem(
                        value: 'detail',
                        text: 'detail',
                        icon: Icons.details_outlined),
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