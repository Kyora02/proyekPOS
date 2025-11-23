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
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _showTopSelling = false;
  String? _selectedCategoryId;

  int _currentPage = 1;
  int _itemsPerPage = 10;
  int? _sortColumnIndex;
  bool _isAscending = true;

  final NumberFormat _currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      final results = await Future.wait([
        _apiService.getProductSalesReports(
          outletId: widget.outletId,
          startDate: start,
          endDate: end,
        ),
        _apiService.getCategories(outletId: widget.outletId),
      ]);

      setState(() {
        _allData = results[0];
        _categories = results[1];
        _filteredData = _allData;
        _isLoading = false;
      });

      _filterData();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
      setState(() {
        _isLoading = false;
        _allData = [];
        _filteredData = [];
      });
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> filtered = _allData.where((item) {
      final produk = item['produk'].toString().toLowerCase();
      final sku = item['sku'].toString().toLowerCase();
      final kategori = item['kategori'].toString().toLowerCase();
      final jenisProduk = item['jenisProduk'].toString().toLowerCase();

      final matchesQuery = query.isEmpty ||
          produk.contains(query) ||
          sku.contains(query) ||
          kategori.contains(query) ||
          jenisProduk.contains(query);

      final matchesCategory = _selectedCategoryId == null ||
          item['categoryId'] == _selectedCategoryId;

      return matchesQuery && matchesCategory;
    }).toList();

    if (_showTopSelling) {
      filtered.sort((a, b) => (b['jumlah'] as num).compareTo(a['jumlah'] as num));
      filtered = filtered.take(10).toList();
    } else if (_sortColumnIndex != null) {
      _sortList(filtered, _sortColumnIndex!, _isAscending);
    }

    setState(() {
      _filteredData = filtered;
      _currentPage = 1;
    });
  }

  void _sortList(List<Map<String, dynamic>> list, int columnIndex, bool ascending) {
    list.sort((a, b) {
      int compareResult = 0;

      switch (columnIndex) {
        case 0:
          compareResult = (a['produk'] ?? '').compareTo(b['produk'] ?? '');
          break;
        case 1:
          compareResult = (a['sku'] ?? '').compareTo(b['sku'] ?? '');
          break;
        case 2:
          compareResult = (a['kategori'] ?? '').compareTo(b['kategori'] ?? '');
          break;
        case 3:
          final num valA = a['jumlah'] ?? 0;
          final num valB = b['jumlah'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 4:
          final num valA = a['penjualanRp'] ?? 0;
          final num valB = b['penjualanRp'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 5:
          final num valA = a['persentaseJumlah'] ?? 0;
          final num valB = b['persentaseJumlah'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
      }

      return ascending ? compareResult : -compareResult;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _showTopSelling = false;
    });
    _sortList(_filteredData, columnIndex, ascending);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime? newStartDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF279E9E),
              onPrimary: Colors.white,
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

    if (newStartDate == null) return;

    final DateTime? newEndDate = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(newStartDate) ? _endDate : newStartDate,
      firstDate: newStartDate,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF279E9E),
              onPrimary: Colors.white,
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

    if (newEndDate == null) return;

    setState(() {
      _startDate = newStartDate;
      _endDate = newEndDate;
    });

    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _filteredData.length;
    final totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 9999);
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final dataOnCurrentPage = _filteredData.sublist(startIndex, endIndex);

    return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
                    : _buildResponsiveTable(dataOnCurrentPage),
                const SizedBox(height: 24),
                if (!_isLoading && totalItems > 0) _buildPagination(totalItems, totalPages),
              ],
            ),
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
          onPressed: _filteredData.isEmpty ? null : () {},
          icon: const Icon(Icons.cloud_download_outlined, size: 18),
          label: const Text('Ekspor Laporan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    final categoryFilter = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategoryId,
          hint: const Text('Semua Kategori'),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF279E9E)),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategoryId = newValue;
            });
            _filterData();
          },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Semua Kategori'),
            ),
            ..._categories.map<DropdownMenuItem<String?>>((category) {
              return DropdownMenuItem<String?>(
                value: category['id'],
                child: Text(category['name'] ?? 'Tanpa Nama'),
              );
            }).toList(),
          ],
        ),
      ),
    );

    final topSellingToggle = FilterChip(
      label: const Text('Produk Terlaris'),
      selected: _showTopSelling,
      onSelected: (bool selected) {
        setState(() {
          _showTopSelling = selected;
          if (selected) {
            _sortColumnIndex = null;
          }
        });
        _filterData();
      },
      selectedColor: const Color(0xFF279E9E).withOpacity(0.2),
      checkmarkColor: const Color(0xFF279E9E),
      labelStyle: TextStyle(
        color: _showTopSelling ? const Color(0xFF279E9E) : Colors.grey[700],
        fontWeight: _showTopSelling ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: _showTopSelling ? const Color(0xFF279E9E) : Colors.grey[300]!,
      ),
    );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        searchField,
        datePicker,
        categoryFilter,
        topSellingToggle,
      ],
    );
  }

  Widget _buildResponsiveTable(List<Map<String, dynamic>> data) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          constraints: const BoxConstraints(minWidth: 1000),
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
            child: _buildDataTable(data),
          ),
        ),
      ),
    );
  }

  DataTable _buildDataTable(List<Map<String, dynamic>> data) {
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: Colors.grey[600],
      letterSpacing: 0.5,
    );

    return DataTable(
      sortColumnIndex: _showTopSelling ? null : _sortColumnIndex,
      sortAscending: _isAscending,
      columnSpacing: 50,
      horizontalMargin: 24,
      headingRowHeight: 50,
      dataRowMaxHeight: 72,
      dataRowMinHeight: 72,
      dividerThickness: 1,
      showBottomBorder: true,
      columns: [
        DataColumn(
          label: SizedBox(width: 150, child: Text('PRODUK', style: headerStyle)),
          onSort: _showTopSelling ? null : (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Text('SKU', style: headerStyle)),
          onSort: _showTopSelling ? null : (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 120, child: Text('KATEGORI', style: headerStyle)),
          onSort: _showTopSelling ? null : (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 80, child: Text('JUMLAH', style: headerStyle)),
          numeric: true,
          onSort: _showTopSelling ? null : (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 120, child: Text('PENJUALAN', style: headerStyle)),
          numeric: true,
          onSort: _showTopSelling ? null : (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Text('JUMLAH (%)', style: headerStyle)),
          numeric: true,
          onSort: _showTopSelling ? null : (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
      ],
      rows: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return DataRow(
          color: _showTopSelling && index < 3
              ? MaterialStateProperty.all(
              index == 0 ? Colors.amber.shade50 :
              index == 1 ? Colors.grey.shade100 :
              Colors.orange.shade50
          )
              : null,
          cells: [
            DataCell(
              Row(
                children: [
                  if (_showTopSelling && index < 3)
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.amber :
                        index == 1 ? Colors.grey :
                        Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      item['produk'] ?? '-',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(SizedBox(width: 100, child: Text(
                item['sku'] ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            ))),
            DataCell(SizedBox(width: 120, child: Text(
                item['kategori'] ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            ))),
            DataCell(SizedBox(width: 80, child: Text(
                item['jumlah'].toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            ))),
            DataCell(SizedBox(width: 120, child: Text(
              _currencyFormatter.format(item['penjualanRp'] ?? 0),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444)),
            ))),
            DataCell(SizedBox(width: 100, child: Text(
                '${(item['persentaseJumlah'] as num).toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            ))),
          ],
        );
      }).toList(),
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
              icon: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF279E9E)),
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
              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF279E9E)),
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