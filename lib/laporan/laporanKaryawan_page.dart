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

class LaporanKaryawanPage extends StatefulWidget {
  final String outletId;
  const LaporanKaryawanPage({
    super.key,
    required this.outletId
  });

  @override
  State<LaporanKaryawanPage> createState() => _LaporanKaryawanPageState();
}

class _LaporanKaryawanPageState extends State<LaporanKaryawanPage> {
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
  int? _sortColumnIndex;
  bool _isAscending = false;

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

      final data = await _apiService.getEmployeePerformance(
        outletId: widget.outletId,
        startDate: start,
        endDate: end,
      );

      setState(() {
        _allData = data;
        _filteredData = data;
        _isLoading = false;
      });

      _filterData();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat laporan karyawan: $e')),
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
      final nama = item['nama'].toString().toLowerCase();
      final nip = item['nip'].toString().toLowerCase();

      final matchesQuery = query.isEmpty ||
          nama.contains(query) ||
          nip.contains(query);

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
          compareResult = (a['nama'] ?? '').compareTo(b['nama'] ?? '');
          break;
        case 1:
          compareResult = (a['nip'] ?? '').compareTo(b['nip'] ?? '');
          break;
        case 2:
          final num valA = a['totalTransactions'] ?? 0;
          final num valB = b['totalTransactions'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 3:
          final num valA = a['totalRevenue'] ?? 0;
          final num valB = b['totalRevenue'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 4:
          final num valA = a['totalItemsSold'] ?? 0;
          final num valB = b['totalItemsSold'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 5:
          final num valA = a['averageTransaction'] ?? 0;
          final num valB = b['averageTransaction'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 6:
          final num valA = a['workingDays'] ?? 0;
          final num valB = b['workingDays'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 7:
          final num valA = a['totalHours'] ?? 0;
          final num valB = b['totalHours'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 8:
          final num valA = a['lateCount'] ?? 0;
          final num valB = b['lateCount'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 9:
          final num valA = a['absentCount'] ?? 0;
          final num valB = b['absentCount'] ?? 0;
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

  Future<void> _exportToPdf() async {
    try {
      final doc = pw.Document();

      final font = await PdfGoogleFonts.nunitoExtraLight();
      final fontBold = await PdfGoogleFonts.nunitoExtraBold();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Laporan Kinerja Karyawan', style: pw.TextStyle(font: fontBold, fontSize: 24)),
                    pw.Text(
                      '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Nama', 'NIP', 'Transaksi', 'Revenue', 'Item Terjual', 'Rata-rata', 'Hari Kerja', 'Jam Kerja', 'Terlambat', 'Tidak Masuk'],
                data: _filteredData.map((item) {
                  return [
                    item['nama'] ?? '-',
                    item['nip'] ?? '-',
                    item['totalTransactions'].toString(),
                    _currencyFormatter.format(item['totalRevenue'] ?? 0),
                    item['totalItemsSold'].toString(),
                    _currencyFormatter.format(item['averageTransaction'] ?? 0),
                    item['workingDays'].toString(),
                    '${item['totalHours'] ?? 0} jam',
                    item['lateCount'].toString(),
                    item['absentCount'].toString(),
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
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.center,
                  7: pw.Alignment.center,
                  8: pw.Alignment.center,
                  9: pw.Alignment.center,
                },
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Revenue: ${_currencyFormatter.format(_filteredData.fold(0.0, (sum, item) => sum + (item['totalRevenue'] ?? 0)))}',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                ],
              ),
            ];
          },
        ),
      );

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
              constraints: const BoxConstraints(maxWidth: 1400),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Laporan Kinerja Karyawan',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(width: 8),
        isPortrait
            ? IconButton(
          onPressed: _filteredData.isEmpty ? null : () => _exportToPdf(),
          icon: const Icon(Icons.cloud_download_outlined),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            disabledBackgroundColor: Colors.grey[300],
          ),
        )
            : ElevatedButton.icon(
          onPressed: _filteredData.isEmpty ? null : () => _exportToPdf(),
          icon: const Icon(Icons.cloud_download_outlined, size: 18),
          label: const Text('Ekspor Laporan', style: TextStyle(fontSize: 14)),
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterData(),
        decoration: InputDecoration(
          hintText: 'Cari Nama, NIP...',
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
          constraints: const BoxConstraints(minWidth: 1300),
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
      columnSpacing: 30,
      horizontalMargin: 24,
      headingRowHeight: 50,
      dataRowMaxHeight: 72,
      dataRowMinHeight: 72,
      dividerThickness: 1,
      showBottomBorder: true,
      columns: [
        DataColumn(
          label: SizedBox(width: 120, child: Text('NAMA', style: headerStyle)),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 80, child: Text('NIP', style: headerStyle)),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Text('TRANSAKSI', style: headerStyle)),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 120, child: Text('REVENUE', style: headerStyle)),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Text('ITEM JUAL', style: headerStyle)),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 120, child: Text('RATA-RATA', style: headerStyle)),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Text('HARI KERJA', style: headerStyle)),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 100, child: Text('JAM KERJA', style: headerStyle)),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 90, child: Text('TERLAMBAT', style: headerStyle)),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: SizedBox(width: 110, child: Text('TDK MASUK', style: headerStyle)),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
      ],
      rows: data.map((item) {
        return DataRow(
          cells: [
            DataCell(SizedBox(width: 120, child: Text(
                item['nama'] ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444), fontWeight: FontWeight.w600)
            ))),
            DataCell(SizedBox(width: 80, child: Text(
                item['nip'] ?? '-',
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666))
            ))),
            DataCell(SizedBox(width: 90, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${item['totalTransactions'] ?? 0}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF1976D2), fontWeight: FontWeight.w600),
              ),
            )))),
            DataCell(SizedBox(width: 120, child: Text(
              _currencyFormatter.format(item['totalRevenue'] ?? 0),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2E7D32)),
            ))),
            DataCell(SizedBox(width: 100, child: Center(child: Text(
              '${item['totalItemsSold'] ?? 0}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
            )))),
            DataCell(SizedBox(width: 120, child: Text(
              _currencyFormatter.format(item['averageTransaction'] ?? 0),
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ))),
            DataCell(SizedBox(width: 90, child: Center(child: Text(
              '${item['workingDays'] ?? 0}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
            )))),
            DataCell(SizedBox(width: 100, child: Center(child: Text(
              '${item['totalHours'] ?? 0} jam',
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            )))),
            DataCell(SizedBox(width: 90, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (item['lateCount'] ?? 0) > 0 ? const Color(0xFFFFF3E0) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item['lateCount'] ?? 0}',
                style: TextStyle(
                  fontSize: 13,
                  color: (item['lateCount'] ?? 0) > 0 ? const Color(0xFFE65100) : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            )))),
            DataCell(SizedBox(width: 110, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (item['absentCount'] ?? 0) > 0 ? const Color(0xFFFFEBEE) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item['absentCount'] ?? 0}',
                style: TextStyle(
                  fontSize: 13,
                  color: (item['absentCount'] ?? 0) > 0 ? const Color(0xFFC62828) : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            )))),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ditampilkan $startItem - $endItem dari $totalItems karyawan',
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
                'Ditampilkan $startItem - $endItem dari $totalItems karyawan',
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_currentPage',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
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