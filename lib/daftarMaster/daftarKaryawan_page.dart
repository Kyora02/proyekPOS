import 'package:flutter/material.dart';
import 'package:proyekpos2/crud/tambahKaryawan_page.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'dart:math' as math;

class DaftarKaryawanPage extends StatefulWidget {
  final String outletId;

  const DaftarKaryawanPage({
    super.key,
    required this.outletId,
  });
  @override
  State<DaftarKaryawanPage> createState() => _DaftarKaryawanPageState();
}



class _DaftarKaryawanPageState extends State<DaftarKaryawanPage> {
  final _apiService = ApiService();
  final ScrollController _horizontalScrollController = ScrollController();
  List<Map<String, dynamic>> _allKaryawan = [];
  bool _isLoading = true;
  String? _error;
  String _activeOutletName = "Outlet";

  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchKaryawan();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchKaryawan() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final karyawanList =
      await _apiService.getKaryawan(outletId: widget.outletId);

      if (karyawanList.isNotEmpty) {
        _activeOutletName = karyawanList.first['outlet'] ?? 'Outlet';
      }

      if (mounted) {
        setState(() {
          _allKaryawan = karyawanList;
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

  List<Map<String, dynamic>> get _filteredKaryawan {
    List<Map<String, dynamic>> karyawanList = _allKaryawan;

    if (_searchQuery.isNotEmpty) {
      karyawanList = karyawanList.where((karyawan) {
        final name = (karyawan['nama'] as String? ?? '').toLowerCase();
        final nip = (karyawan['nip'] as String? ?? '').toLowerCase();
        final email = (karyawan['email'] as String? ?? '').toLowerCase();
        final phone = (karyawan['notelp'] as String? ?? '').toLowerCase();
        final status = (karyawan['status'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            nip.contains(query) ||
            email.contains(query) ||
            phone.contains(query) ||
            status.contains(query);
      }).toList();
    }
    return karyawanList;
  }

  void _sortData(List<Map<String, dynamic>> items) {
    if (_sortColumnIndex == null) {
      return;
    }
    items.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      switch (_sortColumnIndex) {
        case 0:
          aValue = a['nama'] ?? '';
          bValue = b['nama'] ?? '';
          break;
        case 1:
          aValue = a['nip'] ?? '';
          bValue = b['nip'] ?? '';
          break;
        case 2:
          aValue = a['email'] ?? '';
          bValue = b['email'] ?? '';
          break;
        case 3:
          aValue = a['notelp'] ?? '';
          bValue = b['notelp'] ?? '';
          break;
        case 4:
          aValue = a['outlet'] ?? '';
          bValue = b['outlet'] ?? '';
          break;
        case 5:
          aValue = a['status'] ?? '';
          bValue = b['status'] ?? '';
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

  void _navigateToAddKaryawan() {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahKaryawanPage(
          outletId: widget.outletId,
          outletName: _activeOutletName,
        ),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchKaryawan();
      }
    });
  }

  void _navigateToEditKaryawan(Map<String, dynamic> karyawan) {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahKaryawanPage(
          karyawan: karyawan,
          outletId: widget.outletId,
          outletName: _activeOutletName,
        ),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchKaryawan();
      }
    });
  }

  Future<void> _handleDelete(String id, String name) async {
    try {
      await _apiService.deleteKaryawan(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Karyawan "$name" berhasil dihapus'),
              backgroundColor: Colors.green),
        );
        _fetchKaryawan();
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
    final filteredList = _filteredKaryawan;
    _sortData(filteredList);
    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final karyawanOnCurrentPage = filteredList.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
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
                  _buildDesktopKaryawanTable(karyawanOnCurrentPage),
                if (!_isLoading && _error == null) ...[
                  const SizedBox(height: 24),
                  _buildPaginationFooter(
                      totalItems, totalPages, startIndex, endIndex),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Daftar Karyawan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _navigateToAddKaryawan,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Tambah Karyawan'),
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
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari karyawan...',
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

  Widget _buildDesktopKaryawanTable(List<Map<String, dynamic>> karyawanList) {
    if (karyawanList.isEmpty) {
      return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!)),
          child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('Tidak ada karyawan ditemukan.'))));
    }

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!)),
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 100.0,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            headingTextStyle: _tableHeaderStyle(),
            dataTextStyle: _tableBodyStyle(),
            columns: [
              DataColumn(label: const Text('NAMA'), onSort: _onSort),
              DataColumn(label: const Text('NIP'), onSort: _onSort),
              DataColumn(label: const Text('EMAIL'), onSort: _onSort),
              DataColumn(label: const Text('NOTELP'), onSort: _onSort),
              DataColumn(label: const Text('OUTLET'), onSort: _onSort),
              DataColumn(label: const Text('STATUS'), onSort: _onSort),
              DataColumn(label: const Text('AKSI')),
            ],
            rows: karyawanList.map((karyawan) {
              return DataRow(
                cells: [
                  DataCell(Text(karyawan['nama'] ?? 'N/A')),
                  DataCell(Text(karyawan['nip'] ?? 'N/A')),
                  DataCell(Text(karyawan['email'] ?? 'N/A')),
                  DataCell(Text(karyawan['notelp'] ?? 'N/A')),
                  DataCell(Text(karyawan['outlet'] ?? 'N/A')),
                  DataCell(_buildStatusWidget(karyawan['status'])),
                  DataCell(_buildPopupMenuButton(karyawan)),
                ],
              );
            }).toList(),
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

  Widget _buildStatusWidget(String? status) {
    final bool isActive = status == 'Aktif';
    final Color bgColor = isActive ? Colors.green.shade50 : Colors.red.shade50;
    final Color borderColor =
    isActive ? Colors.green.shade100 : Colors.red.shade100;
    final Color textColor =
    isActive ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor)),
      child: Text(
        status ?? 'N/A',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPopupMenuButton(Map<String, dynamic> karyawan) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        icon: const Icon(Icons.more_horiz, color: Colors.grey),
        onSelected: (String value) {
          if (value == 'ubah') {
            _navigateToEditKaryawan(karyawan);
          } else if (value == 'hapus') {
            _showDeleteConfirmationDialog(
                context, karyawan['nama'], karyawan['id']);
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

  Widget _buildPaginationFooter(
      int totalItems, int totalPages, int startIndex, int endIndex) {
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