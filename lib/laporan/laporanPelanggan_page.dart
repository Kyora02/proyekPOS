import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class LaporanPelangganPage extends StatefulWidget {
  final String outletId;

  const LaporanPelangganPage({
    super.key,
    required this.outletId,
  });

  @override
  State<LaporanPelangganPage> createState() => _LaporanPelangganPageState();
}

class _LaporanPelangganPageState extends State<LaporanPelangganPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _horizontalScrollController = ScrollController();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      final data = await _apiService.getCustomerSalesReports(
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
      final nama = (item['namaPelanggan'] ?? '').toString().toLowerCase();
      final noTelepon = (item['noTelepon'] ?? '').toString().toLowerCase();
      return query.isEmpty || nama.contains(query) || noTelepon.contains(query);
    }).toList();

    _sortData(filtered);

    setState(() {
      _filteredData = List<Map<String, dynamic>>.from(filtered);
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
          aValue = a['namaPelanggan'] ?? '';
          bValue = b['namaPelanggan'] ?? '';
          break;
        case 1:
          aValue = a['noTelepon'] ?? '';
          bValue = b['noTelepon'] ?? '';
          break;
        case 2:
          aValue = a['totalTransaksi'] ?? 0;
          bValue = b['totalTransaksi'] ?? 0;
          break;
        case 3:
          aValue = a['totalBelanja'] ?? 0;
          bValue = b['totalBelanja'] ?? 0;
          break;
        case 4:
          aValue = a['rataRataTransaksi'] ?? 0;
          bValue = b['rataRataTransaksi'] ?? 0;
          break;
        case 5:
          aValue = a['terakhirBelanja'] ?? 0;
          bValue = b['terakhirBelanja'] ?? 0;
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

  Future<DateTime?> _selectSingleDate({
    required BuildContext context,
    required DateTime initialDate,
    required String helpText,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      helpText: helpText,
      initialEntryMode: DatePickerEntryMode.calendar,
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
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final newStartDate = await _selectSingleDate(
      context: context,
      initialDate: _startDate,
      helpText: 'Pilih Tanggal Mulai',
    );

    if (newStartDate == null) return;

    final newEndDate = await _selectSingleDate(
      context: context,
      initialDate: _endDate.isBefore(newStartDate) ? newStartDate : _endDate,
      helpText: 'Pilih Tanggal Selesai',
    );

    if (newEndDate == null) return;

    DateTime finalStart = newStartDate.isAfter(newEndDate) ? newEndDate : newStartDate;
    DateTime finalEnd = newStartDate.isAfter(newEndDate) ? newStartDate : newEndDate;

    setState(() {
      _startDate = finalStart;
      _endDate = finalEnd;
    });

    _fetchData();
  }

  Future<void> _exportReport() async {
    try {
      final doc = pw.Document();
      final totalSales = _calculateTotalSales();
      final totalTransactions = _calculateTotalTransactions();

      final font = await PdfGoogleFonts.nunitoExtraLight();
      final fontBold = await PdfGoogleFonts.nunitoExtraBold();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Laporan Pelanggan', style: pw.TextStyle(font: fontBold, fontSize: 24)),
                    pw.Text(
                      '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Nama Pelanggan', 'No. Telepon', 'Total Transaksi', 'Total Belanja', 'Rata-rata', 'Terakhir Belanja'],
                data: _filteredData.map((item) {
                  final lastPurchase = DateTime.fromMillisecondsSinceEpoch(item['terakhirBelanja']);
                  return [
                    item['namaPelanggan'] ?? '-',
                    item['noTelepon'] ?? '-',
                    item['totalTransaksi'].toString(),
                    _currencyFormatter.format(item['totalBelanja'] ?? 0),
                    _currencyFormatter.format(item['rataRataTransaksi'] ?? 0),
                    DateFormat('dd MMM yyyy').format(lastPurchase),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF279E9E)),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerLeft,
                },
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Transaksi: $totalTransactions',
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Total Penjualan: ${_currencyFormatter.format(totalSales)}',
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                    ],
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

  double _calculateTotalSales() {
    return _filteredData.fold(0.0, (sum, item) => sum + (item['totalBelanja'] ?? 0));
  }

  int _calculateTotalTransactions() {
    return _filteredData.fold(0, (sum, item) => sum + (item['totalTransaksi'] as int? ?? 0));
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
                      : _buildWebTable(dataOnCurrentPage),
                  const SizedBox(height: 24),
                  if (!_isLoading && totalItems > 0) _buildTotalSummary(),
                  const SizedBox(height: 16),
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
          'Laporan Pelanggan',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333)),
        ),
        ElevatedButton.icon(
          onPressed: _filteredData.isEmpty ? null : _exportReport,
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
          hintText: 'Cari Nama atau No. Telepon...',
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
            child: DataTable(
              columnSpacing: 50,
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
                  label: SizedBox(width: 150, child: Text('NAMA PELANGGAN', style: _tableHeaderStyle())),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: SizedBox(width: 130, child: Text('NO. TELEPON', style: _tableHeaderStyle())),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: SizedBox(width: 110, child: Text('TOTAL TRANSAKSI', style: _tableHeaderStyle())),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: SizedBox(width: 130, child: Text('TOTAL BELANJA', style: _tableHeaderStyle())),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: SizedBox(width: 140, child: Text('RATA-RATA TRANSAKSI', style: _tableHeaderStyle())),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: SizedBox(width: 130, child: Text('TERAKHIR BELANJA', style: _tableHeaderStyle())),
                  onSort: _onSort,
                ),
              ],
              rows: data.map((item) {
                final lastPurchase = DateTime.fromMillisecondsSinceEpoch(item['terakhirBelanja']);
                return DataRow(
                  cells: [
                    DataCell(SizedBox(width: 150, child: Text(
                        item['namaPelanggan'] ?? '-',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
                    ))),
                    DataCell(SizedBox(width: 130, child: Text(
                        item['noTelepon'] ?? '-',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
                    ))),
                    DataCell(SizedBox(width: 110, child: Text(
                        item['totalTransaksi'].toString(),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
                    ))),
                    DataCell(SizedBox(width: 130, child: Text(
                      _currencyFormatter.format(item['totalBelanja'] ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444)),
                    ))),
                    DataCell(SizedBox(width: 140, child: Text(
                      _currencyFormatter.format(item['rataRataTransaksi'] ?? 0),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
                    ))),
                    DataCell(SizedBox(width: 130, child: Text(
                        DateFormat('dd MMM yyyy').format(lastPurchase),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
                    ))),
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

  Widget _buildTotalSummary() {
    final totalSales = _calculateTotalSales();
    final totalTransactions = _calculateTotalTransactions();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF279E9E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF279E9E).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart, color: Color(0xFF279E9E), size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Transaksi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalTransactions.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF279E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF279E9E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF279E9E).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFF279E9E), size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Penjualan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormatter.format(totalSales),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF279E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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