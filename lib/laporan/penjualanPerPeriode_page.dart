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

class LaporanPenjualanPerPeriodePage extends StatefulWidget {
  final String outletId;
  const LaporanPenjualanPerPeriodePage({
    super.key,
    required this.outletId
  });

  @override
  State<LaporanPenjualanPerPeriodePage> createState() => _LaporanPenjualanPerPeriodePageState();
}

class _LaporanPenjualanPerPeriodePageState extends State<LaporanPenjualanPerPeriodePage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _periodData = [];
  bool _isLoading = true;

  String _groupBy = 'day';

  double _totalRevenue = 0;
  int _totalTransactions = 0;
  double _avgTransaction = 0;
  int _totalProductsSold = 0;

  int? _sortColumnIndex;
  bool _isAscending = true;

  final NumberFormat _currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
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

      debugPrint('Fetching data for outlet: ${widget.outletId}');
      debugPrint('Date range: $start to $end');

      final data = await _apiService.getSalesDetail(
        outletId: widget.outletId,
        startDate: start,
        endDate: end,
      );

      debugPrint('Received ${data.length} transactions');

      setState(() {
        _allData = data;
        _isLoading = false;
      });

      _processData();

    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
        _allData = [];
        _periodData = [];
      });
    }
  }

  void _processData() {
    Map<String, Map<String, dynamic>> grouped = {};

    _totalRevenue = 0;
    _totalTransactions = 0;
    _totalProductsSold = 0;

    for (var item in _allData) {
      if (item['status'] != 'success' && item['status'] != 'settlement' && item['status'] != 'capture') {
        continue;
      }

      DateTime date;
      try {
        if (item['timestamp'] != null) {
          if (item['timestamp'] is int) {
            date = DateTime.fromMillisecondsSinceEpoch(item['timestamp']);
          } else if (item['timestamp'] is DateTime) {
            date = item['timestamp'];
          } else {
            date = DateTime.parse(item['timestamp'].toString());
          }
        } else {
          continue;
        }
      } catch (e) {
        debugPrint("Error parsing date: $e");
        continue;
      }

      String key;

      if (_groupBy == 'day') {
        key = DateFormat('yyyy-MM-dd').format(date);
      } else if (_groupBy == 'week') {
        final weekStart = date.subtract(Duration(days: date.weekday - 1));
        key = DateFormat('yyyy-MM-dd').format(weekStart);
      } else {
        key = DateFormat('yyyy-MM').format(date);
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'date': key,
          'dateDisplay': _formatDateDisplay(key, date),
          'totalSales': 0.0,
          'totalTransactions': 0,
          'totalProducts': 0,
          'paymentMethods': <String, int>{},
        };
      }

      final revenue = (item['totalPenjualan'] ?? item['grossAmount'] ?? 0).toDouble();
      grouped[key]!['totalSales'] = (grouped[key]!['totalSales'] as double) + revenue;
      grouped[key]!['totalTransactions'] = (grouped[key]!['totalTransactions'] as int) + 1;

      final items = item['items'] as List<dynamic>? ?? [];
      for (var product in items) {
        int qty = (product['quantity'] ?? product['qty'] ?? 0) is int
            ? (product['quantity'] ?? product['qty'] ?? 0)
            : ((product['quantity'] ?? product['qty'] ?? 0) as double).toInt();
        grouped[key]!['totalProducts'] = (grouped[key]!['totalProducts'] as int) + qty;
      }

      final paymentMethod = item['metodePembayaran'] ?? 'Unknown';
      Map<String, int> paymentMethods = grouped[key]!['paymentMethods'] as Map<String, int>;
      paymentMethods[paymentMethod] = (paymentMethods[paymentMethod] ?? 0) + 1;

      _totalRevenue += revenue;
      _totalTransactions += 1;
      _totalProductsSold += grouped[key]!['totalProducts'] as int;
    }

    _periodData = grouped.values.map((data) {
      final payments = data['paymentMethods'] as Map<String, int>;
      String dominantMethod = '-';
      if (payments.isNotEmpty) {
        dominantMethod = payments.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      final totalTrans = data['totalTransactions'] as int;
      final totalSales = data['totalSales'] as double;

      return {
        'date': data['date'],
        'dateDisplay': data['dateDisplay'],
        'totalSales': totalSales,
        'totalTransactions': totalTrans,
        'avgTransaction': totalTrans > 0 ? totalSales / totalTrans : 0.0,
        'totalProducts': data['totalProducts'],
        'dominantPayment': dominantMethod,
      };
    }).toList();

    _periodData.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    _avgTransaction = _totalTransactions > 0 ? _totalRevenue / _totalTransactions : 0;

    if (_sortColumnIndex != null) {
      _sortList(_periodData, _sortColumnIndex!, _isAscending);
    }

    setState(() {});
  }

  String _formatDateDisplay(String key, DateTime date) {
    if (_groupBy == 'day') {
      return DateFormat('dd MMM yyyy').format(date);
    } else if (_groupBy == 'week') {
      final start = date.subtract(Duration(days: date.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  void _sortList(List<Map<String, dynamic>> list, int columnIndex, bool ascending) {
    list.sort((a, b) {
      int compareResult = 0;

      switch (columnIndex) {
        case 0:
          compareResult = (a['date'] ?? '').compareTo(b['date'] ?? '');
          break;
        case 1:
          compareResult = (a['totalTransactions'] ?? 0).compareTo(b['totalTransactions'] ?? 0);
          break;
        case 2:
          final num valA = a['totalSales'] ?? 0;
          final num valB = b['totalSales'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 3:
          final num valA = a['avgTransaction'] ?? 0;
          final num valB = b['avgTransaction'] ?? 0;
          compareResult = valA.compareTo(valB);
          break;
        case 4:
          compareResult = (a['totalProducts'] ?? 0).compareTo(b['totalProducts'] ?? 0);
          break;
        case 5:
          compareResult = (a['dominantPayment'] ?? '').compareTo(b['dominantPayment'] ?? '');
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
    _sortList(_periodData, columnIndex, ascending);
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
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Laporan Penjualan Per Periode',
                        style: pw.TextStyle(font: fontBold, fontSize: 24)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfSummaryCard('Total Penjualan', _currencyFormatter.format(_totalRevenue), font, fontBold),
                  _buildPdfSummaryCard('Total Transaksi', '$_totalTransactions', font, fontBold),
                  _buildPdfSummaryCard('Rata-rata', _currencyFormatter.format(_avgTransaction), font, fontBold),
                  _buildPdfSummaryCard('Produk Terjual', '$_totalProductsSold', font, fontBold),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Periode', 'Transaksi', 'Total Penjualan', 'Rata-rata', 'Produk', 'Metode Bayar'],
                data: _periodData.map((item) {
                  return [
                    item['dateDisplay'] ?? '-',
                    '${item['totalTransactions']}',
                    _currencyFormatter.format(item['totalSales'] ?? 0),
                    _currencyFormatter.format(item['avgTransaction'] ?? 0),
                    '${item['totalProducts']}',
                    item['dominantPayment'] ?? '-',
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
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerLeft,
                },
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

  pw.Widget _buildPdfSummaryCard(String title, String value, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 12)),
        ],
      ),
    );
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
                    _buildSummaryCards(),
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
                        : _buildResponsiveTable(_periodData),
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
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Laporan Penjualan Per Periode',
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
          onPressed: _periodData.isEmpty ? null : () => _exportToPdf(),
          icon: const Icon(Icons.cloud_download_outlined),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            disabledBackgroundColor: Colors.grey[300],
          ),
        )
            : ElevatedButton.icon(
          onPressed: _periodData.isEmpty ? null : () => _exportToPdf(),
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

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Total Penjualan', _currencyFormatter.format(_totalRevenue), Icons.attach_money, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryCard('Total Transaksi', '$_totalTransactions', Icons.receipt_long, Colors.blue)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Rata-rata Transaksi', _currencyFormatter.format(_avgTransaction), Icons.trending_up, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryCard('Produk Terjual', '$_totalProductsSold', Icons.shopping_cart, Colors.purple)),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildSummaryCard('Total Penjualan', _currencyFormatter.format(_totalRevenue), Icons.attach_money, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Total Transaksi', '$_totalTransactions', Icons.receipt_long, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Rata-rata Transaksi', _currencyFormatter.format(_avgTransaction), Icons.trending_up, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard('Produk Terjual', '$_totalProductsSold', Icons.shopping_cart, Colors.purple)),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
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

    final groupBySelector = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGroupByButton('Harian', 'day'),
          _buildGroupByButton('Mingguan', 'week'),
          _buildGroupByButton('Bulanan', 'month'),
        ],
      ),
    );

    return isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        datePicker,
        const SizedBox(height: 16),
        groupBySelector,
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        datePicker,
        const SizedBox(width: 16),
        groupBySelector,
      ],
    );
  }

  Widget _buildGroupByButton(String label, String value) {
    final bool isSelected = _groupBy == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _groupBy = value;
          });
          _processData();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF279E9E) : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Colors.grey[700],
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
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
      columnSpacing: 60,
      horizontalMargin: 24,
      headingRowHeight: 50,
      dataRowMaxHeight: 72,
      dataRowMinHeight: 72,
      dividerThickness: 1,
      showBottomBorder: true,
      columns: [
        DataColumn(
          label: Text('PERIODE', style: headerStyle),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('TRANSAKSI', style: headerStyle),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('TOTAL PENJUALAN', style: headerStyle),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('RATA-RATA', style: headerStyle),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('PRODUK', style: headerStyle),
          numeric: true,
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
        DataColumn(
          label: Text('METODE BAYAR', style: headerStyle),
          onSort: (columnIndex, ascending) => _onSort(columnIndex, ascending),
        ),
      ],
      rows: data.map((item) {
        return DataRow(
          cells: [
            DataCell(Text(
                item['dateDisplay'] ?? '-',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444), fontWeight: FontWeight.w600)
            )),
            DataCell(Text(
                '${item['totalTransactions']}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))
            )),
            DataCell(Text(
              _currencyFormatter.format(item['totalSales'] ?? 0),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF279E9E)),
            )),
            DataCell(Text(
              _currencyFormatter.format(item['avgTransaction'] ?? 0),
              style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
            )),
            DataCell(Text(
                '${item['totalProducts']}',
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
                item['dominantPayment'] ?? '-',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600
                ),
              ),
            )),
          ],
        );
      }).toList(),
    );
  }
}