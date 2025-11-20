import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:proyekpos2/service/api_service.dart';

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
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;

  int? _sortColumnIndex;
  bool _isAscending = true;

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

  Future<void> _exportToPdf() async {
    try {
      final doc = pw.Document();

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
                    pw.Text('Laporan Penjualan', style: pw.TextStyle(font: fontBold, fontSize: 24)),
                    pw.Text(
                      '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['No. Transaksi', 'Tanggal', 'Karyawan', 'Customer', 'Metode Bayar', 'Total'],
                data: _filteredData.map((item) {
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
                headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF279E9E)),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Periode Ini: ${_currencyFormatter.format(_filteredData.fold(0.0, (sum, item) => sum + (item['totalPenjualan'] ?? 0)))}',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isMobile),
                    const SizedBox(height: 24),
                    _buildFilterActions(context, isMobile),
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
                        : _buildResponsiveTable(_filteredData),
                    const SizedBox(height: 24),
                    if (!_isLoading) _buildPagination(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF333333)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            const Text(
              'Detail Penjualan',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
          ],
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

  Widget _buildFilterActions(BuildContext context, bool isMobile) {
    final formattedStartDate = DateFormat('dd MMM yyyy').format(_startDate);
    final formattedEndDate = DateFormat('dd MMM yyyy').format(_endDate);

    final datePicker = OutlinedButton.icon(
      onPressed: () => _selectDateRange(context),
      icon: const Icon(Icons.calendar_today_outlined,
          size: 18, color: Color(0xFF279E9E)),
      label: Text('$formattedStartDate - $formattedEndDate'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[800],
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    final searchField = SizedBox(
      width: isMobile ? double.infinity : 320,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterData(),
        decoration: InputDecoration(
          hintText: 'Cari No. Transaksi, Karyawan, Pelanggan...',
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

    return isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchField,
        const SizedBox(height: 16),
        datePicker,
      ],
    )
        : SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          searchField,
          const SizedBox(width: 16),
          datePicker,
        ],
      ),
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
      columnSpacing: 35,
      horizontalMargin: 24,
      headingRowHeight: 50,
      dataRowMaxHeight: 72,
      dataRowMinHeight: 72,
      dividerThickness: 1,
      showBottomBorder: true,
      columns: [
        DataColumn(
          label: Text('NO. TRANSAKSI', style: headerStyle),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('TANGGAL', style: headerStyle),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('KARYAWAN', style: headerStyle),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('CUSTOMER', style: headerStyle),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('METODE', style: headerStyle),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('TOTAL', style: headerStyle),
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
            DataCell(Text(
                item['noTransaksi'] ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            )),
            DataCell(Text(
                _dateFormatter.format(dateVal),
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            )),
            DataCell(Text(
                item['namaKaryawan'] ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            )),
            DataCell(Text(
                item['namaCustomer'] ?? 'Umum',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            )),
            DataCell(Container(
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
            )),
            DataCell(Text(
              _currencyFormatter.format(item['totalPenjualan'] ?? 0),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF444444)),
            )),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Ditampilkan 1 - ${_filteredData.length} dari ${_allData.length} data',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              size: 16, color: Color(0xFF279E9E)),
          onPressed: null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFF279E9E),
              borderRadius: BorderRadius.circular(8)),
          child: const Text('1',
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios,
              size: 16, color: Color(0xFF279E9E)),
          onPressed: null,
        ),
      ],
    );
  }
}