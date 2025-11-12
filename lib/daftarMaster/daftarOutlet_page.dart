import 'package:flutter/material.dart';
import 'package:proyekpos2/crud/tambahOutlet_page.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'dart:math' as math;

class DaftarOutletPage extends StatefulWidget {
  const DaftarOutletPage({super.key});

  @override
  State<DaftarOutletPage> createState() => _DaftarOutletPageState();
}

class _DaftarOutletPageState extends State<DaftarOutletPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _horizontalScrollController = ScrollController();
  List<Map<String, dynamic>> _allOutlets = [];
  bool _isLoading = true;

  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final outlets = await _apiService.getOutlets();
      if (mounted) {
        setState(() {
          _allOutlets = outlets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat outlet: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOutlets {
    List<Map<String, dynamic>> outlets = _allOutlets;
    if (_searchQuery.isNotEmpty) {
      outlets = outlets.where((outlet) {
        final name = (outlet['name'] as String? ?? '').toLowerCase();
        final address = (outlet['alamat'] as String? ?? '').toLowerCase();
        final city = (outlet['city'] as String? ?? '').toLowerCase();
        final owner = (outlet['ownerName'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            address.contains(query) ||
            city.contains(query) ||
            owner.contains(query);
      }).toList();
    }
    return outlets;
  }

  void _sortData(List<Map<String, dynamic>> outlets) {
    if (_sortColumnIndex == null) {
      return;
    }
    outlets.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      switch (_sortColumnIndex) {
        case 0:
          aValue = a['name'] ?? '';
          bValue = b['name'] ?? '';
          break;
        case 1:
          aValue = a['alamat'] ?? '';
          bValue = b['alamat'] ?? '';
          break;
        case 2:
          aValue = a['city'] ?? '';
          bValue = b['city'] ?? '';
          break;
        case 3:
          aValue = a['ownerName'] ?? '';
          bValue = b['ownerName'] ?? '';
          break;
        default:
          return 0;
      }
      int compare;
      if (aValue is String && bValue is String) {
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

  void _navigateToAddOutlet() {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => const TambahOutletPage(),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchData();
      }
    });
  }

  void _navigateToEditOutlet(Map<String, dynamic> outlet) {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahOutletPage(outlet: outlet),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchData();
      }
    });
  }

  Future<void> _showDeleteConfirmationDialog(Map<String, dynamic> outlet) async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Konfirmasi Hapus'),
            content: Text(
                'Apakah Anda yakin ingin menghapus outlet "${outlet['name']}"?'),
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
                    await _apiService.deleteOutlet(outlet['id']);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                          Text('Outlet "${outlet['name']}" berhasil dihapus'),
                          backgroundColor: Colors.green),
                    );
                    _fetchData();
                  } catch (e) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Gagal menghapus outlet: $e'),
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final outlets = _filteredOutlets;
    _sortData(outlets);
    final totalItems = outlets.length;
    final totalPages =
    (totalItems / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();

    if (_currentPage > totalPages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentPage = totalPages;
          });
        }
      });
      if (totalPages == 0) {
        _currentPage = 1;
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final outletsOnCurrentPage = outlets.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildFilterBar(),
                    const SizedBox(height: 24),
                    _buildDesktopOutletTable(outletsOnCurrentPage),
                    if (!_isLoading) ...[
                      const SizedBox(height: 24),
                      _buildPagination(totalItems, totalPages),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Daftar Outlet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _navigateToAddOutlet,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Tambah Outlet'),
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

  Widget _buildFilterBar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari outlet...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) => setState(() {
          _searchQuery = value;
          _currentPage = 1;
        }),
      ),
    );
  }

  Widget _buildDesktopOutletTable(List<Map<String, dynamic>> outlets) {
    if (outlets.isEmpty) {
      return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!)),
          child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Tidak ada outlet ditemukan.'))));
    }

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!)),
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalScrollController,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 160.0,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingTextStyle: _tableHeaderStyle(),
              dataTextStyle: _tableBodyStyle(),
              columns: [
                DataColumn(label: const Text('NAMA'), onSort: _onSort),
                DataColumn(label: const Text('ALAMAT'), onSort: _onSort),
                DataColumn(label: const Text('KOTA'), onSort: _onSort),
                DataColumn(label: const Text('OWNER'), onSort: _onSort),
                DataColumn(label: const Text('AKSI')),
              ],
              rows: outlets.map((outlet) {
                return DataRow(
                  cells: [
                    DataCell(Text(outlet['name'] ?? 'N/A')),
                    DataCell(Text(outlet['alamat'] ?? 'N/A')),
                    DataCell(Text(outlet['city'] ?? 'N/A')),
                    DataCell(Text(outlet['ownerName'] ?? 'N/A')),
                    DataCell(_buildPopupMenuButton(outlet)),
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

  Widget _buildPopupMenuButton(Map<String, dynamic> outlet) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        icon: const Icon(Icons.more_horiz, color: Colors.grey),
        onSelected: (String value) {
          if (value == 'ubah') {
            _navigateToEditOutlet(outlet);
          } else if (value == 'hapus') {
            _showDeleteConfirmationDialog(outlet);
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

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required String text,
    required IconData icon,
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.black54),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: isDestructive ? Colors.red : null)),
      ]),
    );
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
        ),
      ],
    );
  }
}