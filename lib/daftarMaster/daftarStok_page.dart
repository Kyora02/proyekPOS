import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/crud/tambahStok_page.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'dart:math' as math;

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
  final ScrollController _horizontalScrollController = ScrollController();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allStockFromServer = [];
  List<Map<String, dynamic>> _filteredStockList = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _filterDate;

  int? _sortColumnIndex;
  bool _sortAscending = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;

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
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchStock() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> data =
      await _apiService.getRawMaterials(widget.outletId);

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

        bool matchesSearch = name.contains(query);
        bool matchesDate = true;

        if (_filterDate != null && stock['date'] != null) {
          DateTime stockDate = DateTime.parse(stock['date']);
          matchesDate = stockDate.year == _filterDate!.year &&
              stockDate.month == _filterDate!.month &&
              stockDate.day == _filterDate!.day;
        }

        return matchesSearch && matchesDate;
      }).toList();
      _currentPage = 1;
    });
  }

  void _sortData(List<Map<String, dynamic>> stock) {
    if (_sortColumnIndex == null) {
      return;
    }
    stock.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      switch (_sortColumnIndex) {
        case 0:
          aValue = a['name'] ?? '';
          bValue = b['name'] ?? '';
          break;
        case 1:
          aValue = a['date'] ?? '';
          bValue = b['date'] ?? '';
          break;
        case 2:
          aValue = a['price'] ?? 0;
          bValue = b['price'] ?? 0;
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

  Future<void> _selectFilterDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _filterDate = picked;
        _filterStock();
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterDate = null;
      _filterStock();
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

  void _navigateToEditProduct(Map<String, dynamic> material) {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahStokPage(
          s: material,
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
                'Apakah Anda yakin ingin menghapus data "${stock['name']}"?'),
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
                    await _apiService.deleteRawMaterial(stock['id']);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                          Text('Data "${stock['name']}" berhasil dihapus'),
                          backgroundColor: Colors.green),
                    );
                    _fetchStock();
                  } catch (e) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Gagal menghapus data: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ],
          );
        });
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> currentStockList = _filteredStockList;
    _sortData(currentStockList);
    final int totalItems = currentStockList.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> stockOnCurrentPage =
    currentStockList.sublist(startIndex, endIndex);

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
                      'Daftar Bahan Baku',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddStock,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Tambah Bahan Baku'),
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
                _buildSearchAndFilter(),
                const SizedBox(height: 24),
                _buildStockList(stockOnCurrentPage),
                const SizedBox(height: 24),
                if (!_isLoading && _error == null)
                  _buildPagination(totalItems, totalPages),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari bahan baku...',
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
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => _selectFilterDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    color: _filterDate != null ? const Color(0xFF279E9E) : Colors.grey,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  _filterDate != null
                      ? DateFormat('dd/MM/yyyy').format(_filterDate!)
                      : 'Filter Tanggal',
                  style: TextStyle(
                    color: _filterDate != null ? const Color(0xFF279E9E) : Colors.grey[700],
                    fontWeight: _filterDate != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (_filterDate != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _clearDateFilter,
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  )
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockList(List<Map<String, dynamic>> stockOnCurrentPage) {
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
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalScrollController,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _isLoading
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(child: CircularProgressIndicator()),
          )
              : _error != null
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 48.0),
            child: Center(
              child: Text(
                _error!,
                style:
                const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          )
              : stockOnCurrentPage.isEmpty
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(
              child: Text(
                'Tidak ada data ditemukan.',
                style:
                TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
              : SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 150.0,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey[600]),
              dataTextStyle: const TextStyle(
                  fontSize: 14, color: Colors.black87),
              columns: [
                DataColumn(
                  label: const Text('NAMA BAHAN BAKU'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('TANGGAL PEMBELIAN'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('HARGA'),
                  numeric: true,
                  onSort: _onSort,
                ),
                const DataColumn(
                  label: Text('AKSI'),
                ),
              ],
              rows: stockOnCurrentPage.map((stock) {
                return DataRow(
                  cells: [
                    DataCell(Text(stock['name'] ?? 'N/A')),
                    DataCell(Text(_formatDate(stock['date'] ?? ''))),
                    DataCell(
                        Text(_formatCurrency(stock['price'] ?? 0))),
                    DataCell(_buildPopupMenuButton(stock)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
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