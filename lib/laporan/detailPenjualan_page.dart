import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'dart:math' as math;

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class DetailPenjualanPage extends StatefulWidget {
  final String outletId;
  const DetailPenjualanPage({
    super.key,
    required this.outletId
  });

  @override
  State<DetailPenjualanPage> createState() => _DetailPenjualanPageState();
}

class _DetailPenjualanPageState extends State<DetailPenjualanPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;

  int _currentPage = 1;
  int _itemsPerPage = 10;
  int? _sortColumnIndex = 1;
  bool _isAscending = false;

  final NumberFormat _currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

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

      final data = await _apiService.getSalesDetail(
        outletId: widget.outletId,
        startDate: start,
        endDate: end,
      );

      data.sort((a, b) {
        final DateTime dateA = a['timestamp'] ?? DateTime(0);
        final DateTime dateB = b['timestamp'] ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _allData = data;
        _filteredData = data;
        _isLoading = false;
      });

      _filterData();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data penjualan: $e')),
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
      final noTransaksi = item['noTransaksi'].toString().toLowerCase();
      final metodePembayaran = item['metodePembayaran'].toString().toLowerCase();
      final namaKaryawan = item['namaKaryawan']?.toString().toLowerCase() ?? '';
      final namaCustomer = item['namaCustomer']?.toString().toLowerCase() ?? '';

      final matchesQuery = query.isEmpty ||
          noTransaksi.contains(query) ||
          metodePembayaran.contains(query) ||
          namaKaryawan.contains(query) ||
          namaCustomer.contains(query);

      return matchesQuery;
    }).toList();

    if (_sortColumnIndex != null) {
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
          compareResult = (a['noTransaksi'] ?? '').compareTo(b['noTransaksi'] ?? '');
          break;
        case 1:
          final DateTime tA = a['timestamp'] ?? DateTime(0);
          final DateTime tB = b['timestamp'] ?? DateTime(0);
          compareResult = tA.compareTo(tB);
          break;
        case 2:
          compareResult = (a['namaKaryawan'] ?? '').compareTo(b['namaKaryawan'] ?? '');
          break;
        case 3:
          compareResult = (a['namaCustomer'] ?? '').compareTo(b['namaCustomer'] ?? '');
          break;
        case 4:
          compareResult = (a['metodePembayaran'] ?? '').compareTo(b['metodePembayaran'] ?? '');
          break;
        case 5:
          final num valA = a['totalPenjualan'] ?? 0;
          final num valB = b['totalPenjualan'] ?? 0;
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
    });
    _sortList(_filteredData, columnIndex, ascending);
  }

  double _calculateTotalPenjualan() {
    return _filteredData.fold(0.0, (sum, item) => sum + ((item['totalPenjualan'] ?? 0) as num).toDouble());
  }

  Future<void> _exportToPdf() async {
    try {
      final doc = pw.Document();

      final font = await PdfGoogleFonts.nunitoExtraLight();
      final fontBold = await PdfGoogleFonts.nunitoExtraBold();

      const int rowsPerPage = 25;
      final totalPages = (_filteredData.length / rowsPerPage).ceil();

      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final startIndex = pageIndex * rowsPerPage;
        final endIndex = math.min(startIndex + rowsPerPage, _filteredData.length);
        final pageData = _filteredData.sublist(startIndex, endIndex);

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Laporan Penjualan', style: pw.TextStyle(font: fontBold, fontSize: 24)),
                      pw.Text(
                        '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 2, color: const PdfColor.fromInt(0xFF279E9E)),
                  pw.SizedBox(height: 10),
                  pw.Expanded(
                    child: pw.Table.fromTextArray(
                      headers: ['No. Transaksi', 'Tanggal', 'Karyawan', 'Customer', 'Metode', 'Total'],
                      data: pageData.map((item) {
                        final DateTime dateVal = item['timestamp'] is DateTime
                            ? item['timestamp']
                            : DateTime.now();

                        return [
                          item['noTransaksi'] ?? '-',
                          _dateFormatter.format(dateVal),
                          item['namaKaryawan'] ?? '-',
                          item['namaCustomer'] ?? '-',
                          item['metodePembayaran'] ?? '-',
                          _currencyFormatter.format(item['totalPenjualan'] ?? 0),
                        ];
                      }).toList(),
                      headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 9),
                      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF279E9E)),
                      rowDecoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                      ),
                      cellStyle: pw.TextStyle(font: font, fontSize: 8),
                      cellAlignments: {
                        0: pw.Alignment.centerLeft,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.centerLeft,
                        3: pw.Alignment.centerLeft,
                        4: pw.Alignment.centerLeft,
                        5: pw.Alignment.centerRight,
                      },
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Halaman ${pageIndex + 1} dari $totalPages',
                        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
                      ),
                      if (pageIndex == totalPages - 1)
                        pw.Text(
                          'Total: ${_currencyFormatter.format(_calculateTotalPenjualan())}',
                          style: pw.TextStyle(font: fontBold, fontSize: 12, color: const PdfColor.fromInt(0xFF279E9E)),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor PDF: $e')),
        );
      }
    }
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
                  const SizedBox(height: 16),
                  if (!_isLoading && totalItems > 0) _buildTotalPenjualan(),
                  const SizedBox(height: 8),
                  if (!_isLoading && totalItems > 0) _buildPagination(totalItems, totalPages),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPenjualan() {
    final total = _calculateTotalPenjualan();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF279E9E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF279E9E).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long,
            color: Color(0xFF279E9E),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Total Penjualan: ${_currencyFormatter.format(total)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF279E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Detail Penjualan',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333)),
        ),
        ElevatedButton.icon(
          onPressed: _filteredData.isEmpty ? null : () => _exportToPdf(),
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

    final datePicker = SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _selectDateRange(context),
        icon: const Icon(Icons.calendar_today_outlined,
            size: 18, color: Color(0xFF279E9E)),
        label: Text('$formattedStartDate - $formattedEndDate'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[800],
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
      ),
    );

    final searchField = SizedBox(
      width: 280,
      height: 48,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterData(),
        decoration: InputDecoration(
          hintText: 'Cari No. Transaksi, Karyawan...',
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
      sortColumnIndex: _sortColumnIndex,
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
          label: SizedBox(width: 150, child: Text('NO. TRANSAKSI', style: headerStyle)),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 130, child: Text('TANGGAL', style: headerStyle)),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Text('KARYAWAN', style: headerStyle)),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Text('CUSTOMER', style: headerStyle)),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Text('METODE', style: headerStyle)),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 120, child: Text('TOTAL', style: headerStyle)),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
      ],
      rows: data.map((item) {
        final DateTime dateVal = item['timestamp'] is DateTime
            ? item['timestamp']
            : DateTime.now();

        return DataRow(
          cells: [
            DataCell(SizedBox(width: 150, child: Text(
                item['noTransaksi'] ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            ))),
            DataCell(SizedBox(width: 130, child: Text(
                _dateFormatter.format(dateVal),
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            ))),
            DataCell(SizedBox(width: 100, child: Text(
                item['namaKaryawan'] ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            ))),
            DataCell(SizedBox(width: 100, child: Text(
                item['namaCustomer'] ?? 'Umum',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            ))),
            DataCell(SizedBox(width: 100, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Text(
                item['metodePembayaran'] ?? '-',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600
                ),
              ),
            ))),
            DataCell(SizedBox(width: 120, child: Text(
              _currencyFormatter.format(item['totalPenjualan'] ?? 0),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444)),
            ))),
          ],
        );
      }).toList(),
    );
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