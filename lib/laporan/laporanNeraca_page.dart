import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service/api_service.dart';

class LaporanNeracaPage extends StatefulWidget {
  final String outletId;

  const LaporanNeracaPage({Key? key, required this.outletId}) : super(key: key);

  @override
  State<LaporanNeracaPage> createState() => _LaporanNeracaPageState();
}

class _LaporanNeracaPageState extends State<LaporanNeracaPage> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? balanceSheetData;
  bool isLoading = false;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadBalanceSheet();
  }

  Future<void> _loadBalanceSheet() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService().getBalanceSheet(
        outletId: widget.outletId,
        date: selectedDate,
      );
      setState(() {
        balanceSheetData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _loadBalanceSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF279E9E)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDateSelector(),
            const SizedBox(height: 24),
            if (balanceSheetData == null)
              const Center(child: Text('Tidak ada data'))
            else ...[
              _buildAssetsSection(),
              const SizedBox(height: 24),
              _buildLiabilitiesSection(),
              const SizedBox(height: 24),
              _buildEquitySection(),
              const SizedBox(height: 24),
              _buildBalanceCheck(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'Laporan Neraca',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Posisi keuangan per tanggal tertentu',
          child: Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _selectDate,
        icon: const Icon(Icons.calendar_today_outlined, size: 18),
        label: Text('Per Tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate)}'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[800],
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAssetsSection() {
    final assets = balanceSheetData!['assets'];
    final currentAssets = assets['currentAssets'];

    return _Section(
      title: 'ASET (HARTA)',
      totalLabel: 'TOTAL ASET',
      totalValue: assets['totalAssets'],
      formatter: currencyFormat,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text('Aset Lancar', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF279E9E))),
        ),
        _DetailRow(label: 'Kas/Bank', value: currentAssets['cash'], formatter: currencyFormat),
        _DetailRow(label: 'Persediaan Barang', value: currentAssets['inventory'], formatter: currencyFormat),
        _DetailRow(label: 'Piutang', value: currentAssets['accountsReceivable'], formatter: currencyFormat),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(),
        ),
        _DetailRow(label: 'Total Aset Lancar', value: assets['totalCurrentAssets'], formatter: currencyFormat, isBold: true),
      ],
    );
  }

  Widget _buildLiabilitiesSection() {
    final liabilities = balanceSheetData!['liabilities'];
    final currentLiabilities = liabilities['currentLiabilities'];

    return _Section(
      title: 'KEWAJIBAN (HUTANG)',
      totalLabel: 'TOTAL KEWAJIBAN',
      totalValue: liabilities['totalLiabilities'],
      formatter: currencyFormat,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text('Kewajiban Lancar', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF279E9E))),
        ),
        _DetailRow(label: 'Gaji Belum Dibayar', value: currentLiabilities['unpaidSalaries'], formatter: currencyFormat),
        _DetailRow(label: 'Hutang Supplier', value: currentLiabilities['accountsPayable'], formatter: currencyFormat),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(),
        ),
        _DetailRow(label: 'Total Kewajiban Lancar', value: liabilities['totalCurrentLiabilities'], formatter: currencyFormat, isBold: true),
      ],
    );
  }

  Widget _buildEquitySection() {
    final equity = balanceSheetData!['equity'];

    return _Section(
      title: 'MODAL (EKUITAS)',
      totalLabel: 'TOTAL MODAL',
      totalValue: equity['totalEquity'],
      formatter: currencyFormat,
      children: [
        _DetailRow(label: 'Modal Pemilik', value: equity['ownerCapital'], formatter: currencyFormat),
        _DetailRow(label: 'Laba Ditahan', value: equity['retainedEarnings'], formatter: currencyFormat),
        _DetailRow(label: 'Laba Periode Berjalan', value: equity['currentPeriodProfit'], formatter: currencyFormat),
      ],
    );
  }

  Widget _buildBalanceCheck() {
    final balanceCheck = balanceSheetData!['balanceCheck'];
    final isBalanced = balanceCheck['balanced'] as bool;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
        border: Border.all(
          color: isBalanced ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _SectionHeader(title: 'PEMERIKSAAN NERACA'),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Aset:', style: TextStyle(fontSize: 14)),
                    Text(
                      currencyFormat.format(balanceCheck['totalAssets']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Kewajiban + Modal:', style: TextStyle(fontSize: 14)),
                    Text(
                      currencyFormat.format(balanceCheck['totalLiabilitiesAndEquity']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isBalanced ? Icons.check_circle : Icons.error,
                      color: isBalanced ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBalanced ? 'NERACA SEIMBANG' : 'NERACA TIDAK SEIMBANG',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isBalanced ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final dynamic totalValue;
  final String totalLabel;
  final NumberFormat formatter;

  const _Section({
    required this.title,
    required this.children,
    required this.totalValue,
    required this.totalLabel,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          ...children,
          _TotalRow(
            label: totalLabel,
            value: totalValue,
            formatter: formatter,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final NumberFormat formatter;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.formatter,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            formatter.format(value ?? 0),
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final NumberFormat formatter;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            formatter.format(value ?? 0),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}