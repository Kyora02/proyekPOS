import 'package:flutter/material.dart';
import 'package:proyekpos2/crud/tambahMeja.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'dart:math' as math;

class DaftarMejaPage extends StatefulWidget {
  final String outletId;

  const DaftarMejaPage({
    super.key,
    required this.outletId,
  });

  @override
  State<DaftarMejaPage> createState() => _DaftarMejaPageState();
}

class _DaftarMejaPageState extends State<DaftarMejaPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _horizontalScrollController = ScrollController();

  List<Map<String, dynamic>> _allTables = [];
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
    _fetchTables();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTables() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tables = await _apiService.getTables(outletId: widget.outletId);

      if (mounted) {
        setState(() {
          _allTables = tables;
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

  void _sortData(List<Map<String, dynamic>> tables) {
    if (_sortColumnIndex == null) {
      return;
    }
    tables.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      switch (_sortColumnIndex) {
        case 0:
          aValue = a['name'] ?? '';
          bValue = b['name'] ?? '';
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

  List<Map<String, dynamic>> get _filteredTables {
    List<Map<String, dynamic>> tables = _allTables;

    if (_searchQuery.isNotEmpty) {
      tables = tables.where((table) {
        final name = table['name']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    return tables;
  }

  void _navigateToAddTable() {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
      builder: (_) => TambahMejaPage(outletId: widget.outletId),
    ))
        .then((result) {
      if (result == true) _fetchTables();
    });
  }

  void _navigateToEditTable(Map<String, dynamic> table) {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
      builder: (_) => TambahMejaPage(
        meja: table,
        outletId: widget.outletId,
      ),
    ))
        .then((result) {
      if (result == true) _fetchTables();
    });
  }

  Future<void> _handleDelete(String tableId, String tableName) async {
    try {
      await _apiService.deleteTable(tableId);

      if (!mounted) return;

      setState(() {
        _allTables.removeWhere((table) => table['id'] == tableId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meja "$tableName" berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDownloadQR(String tableId, String tableName) async {
    try {
      final filePath = await _apiService.downloadTableQR(tableId, tableName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code berhasil disimpan di: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String tableName, String tableId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus meja "$tableName"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleDelete(tableId, tableName);
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

    final tables = _filteredTables;
    _sortData(tables);
    final int totalItems = tables.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _fetchTables,
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
                  _buildTableTable(tables),
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
            'Daftar Manajemen Meja',
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
          onPressed: _navigateToAddTable,
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
        )
            : ElevatedButton.icon(
          onPressed: _navigateToAddTable,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tambah Meja', style: TextStyle(fontSize: 14)),
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
              hintText: 'Cari meja...',
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
      ],
    );
  }

  Widget _buildTableTable(List<Map<String, dynamic>> tables) {
    final int totalItems = tables.length;
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> tablesOnCurrentPage =
    tables.sublist(startIndex, endIndex);

    if (tablesOnCurrentPage.isEmpty) {
      final String message = _searchQuery.isNotEmpty
          ? 'Tidak ada meja ditemukan.'
          : 'Belum ada meja.';

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
              columnSpacing: 100.0,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingTextStyle: _tableHeaderStyle(),
              dataTextStyle: _tableBodyStyle(),
              horizontalMargin: 20.0,
              columns: [
                DataColumn(
                  label: const Text('NAMA MEJA'),
                  onSort: _onSort,
                ),
                const DataColumn(
                  label: Text('AKSI'),
                ),
              ],
              rows: tablesOnCurrentPage.map((table) {
                final String tableName = table['name'] ?? 'N/A';
                final String tableId = table['id'];
                return DataRow(
                  cells: [
                    DataCell(Text(tableName)),
                    DataCell(
                      PopupMenuButton<String>(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (String value) {
                          if (value == 'ubah') {
                            _navigateToEditTable(table);
                          } else if (value == 'hapus') {
                            _showDeleteConfirmationDialog(
                                context, tableName, tableId);
                          } else if (value == 'download') {
                            _handleDownloadQR(tableId, tableName);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          _buildPopupMenuItem(
                              value: 'ubah',
                              text: 'Ubah',
                              icon: Icons.edit_outlined),
                          _buildPopupMenuItem(
                              value: 'download',
                              text: 'Download QR',
                              icon: Icons.qr_code_2_outlined),
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

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required String text,
    required IconData icon,
    bool isDestructive = false,
  }) {
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