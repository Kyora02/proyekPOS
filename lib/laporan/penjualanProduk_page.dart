import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'dart:math' as math;
import 'dart:ui';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class PenjualanProdukPage extends StatefulWidget {
  final String outletId;
  const PenjualanProdukPage({
    super.key,
    required this.outletId,
  });
  @override
  State<PenjualanProdukPage> createState() => _PenjualanProdukPageState();
}

class _PenjualanProdukPageState extends State<PenjualanProdukPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;

  int _currentPage = 1;
  int _itemsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  final NumberFormat _currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      final data = await _apiService.getProductSalesReports(
        outletId: widget.outletId,
        startDate: start,
        endDate: end,
      );
      setState(() {
        _allData = data;
        _filterData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    final filtered = _allData.where((item) {
      final produk = item['produk'].toString().toLowerCase();
      final sku = item['sku'].toString().toLowerCase();
      final kategori = item['kategori'].toString().toLowerCase();
      final jenisProduk = item['jenisProduk'].toString().toLowerCase();

      final matchesQuery = query.isEmpty ||
          produk.contains(query) ||
          sku.contains(query) ||
          kategori.contains(query) ||
          jenisProduk.contains(query);

      return matchesQuery;
    }).toList();

    _sortData(filtered);

    setState(() {
      _filteredData = filtered;
      _currentPage = 1;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _filterData();
    });
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
          aValue = a['produk'] ?? '';
          bValue = b['produk'] ?? '';
          break;
        case 1:
          aValue = a['sku'] ?? '';
          bValue = b['sku'] ?? '';
          break;
        case 2:
          aValue = a['kategori'] ?? '';
          bValue = b['kategori'] ?? '';
          break;
        case 3:
          aValue = a['jumlah'] ?? 0;
          bValue = b['jumlah'] ?? 0;
          break;
        case 4:
          aValue = a['penjualanRp'] ?? 0;
          bValue = b['penjualanRp'] ?? 0;
          break;
        case 5:
          aValue = a['persentaseJumlah'] ?? 0;
          bValue = b['persentaseJumlah'] ?? 0;
          break;
        default:
          return 0;
      }
      int compare;
      if (aValue is String && bValue is String) {
        compare = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        compare = aValue.compareTo(bValue);
      } else {
        compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF279E9E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF279E9E),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _filteredData.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 9999);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final dataOnCurrentPage = _filteredData.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildFilterActions(context),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: Color(0xFF279E9E),
                    ),
                  ),
                )
                    : _buildWebTable(dataOnCurrentPage),
                const SizedBox(height: 24),
                if (!_isLoading) _buildPagination(totalItems, totalPages),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Penjualan Produk',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333)),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.cloud_download_outlined, size: 18),
          label: const Text('Ekspor Laporan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterActions(BuildContext context) {
    final formattedStartDate = DateFormat('dd MMM yyyy').format(_startDate);
    final formattedEndDate = DateFormat('dd MMM yyyy').format(_endDate);

    final datePicker = OutlinedButton.icon(
      onPressed: () => _selectDateRange(context),
      icon: const Icon(Icons.calendar_today_outlined,
          size: 18, color: Color(0xFF279E9E)),
      label: Text('$formattedStartDate - $formattedEndDate'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[800],
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );

    final searchField = SizedBox(
      width: 280,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterData(),
        decoration: InputDecoration(
          hintText: 'Cari Produk, SKU, Kategori...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF279E9E)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        searchField,
        datePicker,
      ],
    );
  }

  Widget _buildWebTable(List<Map<String, dynamic>> data) {
    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.grey[200],
              dataTableTheme: DataTableThemeData(
                headingRowColor: MaterialStateProperty.all(Colors.transparent),
                dataRowColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      return Colors.transparent;
                    }),
              ),
            ),
            child: DataTable(
              columnSpacing: 35.0,
              horizontalMargin: 24,
              headingRowHeight: 50,
              dataRowMaxHeight: 72,
              dataRowMinHeight: 72,
              dividerThickness: 1,
              showBottomBorder: true,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columns: [
                DataColumn(
                  label: Text('PRODUK', style: _tableHeaderStyle()),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: Text('SKU', style: _tableHeaderStyle()),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: Text('KATEGORI', style: _tableHeaderStyle()),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: Text('JUMLAH', style: _tableHeaderStyle()),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: Text('PENJUALAN', style: _tableHeaderStyle()),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: Text('JUMLAH (%)', style: _tableHeaderStyle()),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: Text('AKSI', style: _tableHeaderStyle()),
                ),
              ],
              rows: data.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                        item['produk'] ?? '-',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
                    )),
                    DataCell(Text(
                        item['sku'] ?? '-',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
                    )),
                    DataCell(Text(
                        item['kategori'] ?? '-',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
                    )),
                    DataCell(Text(
                        item['jumlah'].toString(),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
                    )),
                    DataCell(Text(
                      _currencyFormatter.format(item['penjualanRp'] ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444)),
                    )),
                    DataCell(Text(
                        '${(item['persentaseJumlah'] as num).toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
                    )),
                    DataCell(
                      const Icon(Icons.more_horiz, color: Colors.grey),
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

  TextStyle _tableHeaderStyle() {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.grey[600],
      letterSpacing: 0.5,
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