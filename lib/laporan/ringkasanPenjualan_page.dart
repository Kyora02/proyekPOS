import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RingkasanPenjualanPage extends StatefulWidget {
  const RingkasanPenjualanPage({super.key});

  @override
  State<RingkasanPenjualanPage> createState() => _RingkasanPenjualanPageState();
}

class _RingkasanPenjualanPageState extends State<RingkasanPenjualanPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF279E9E),
            colorScheme:
            const ColorScheme.light(primary: Color(0xFF279E9E)),
            buttonTheme:
            const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  final NumberFormat _currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final Map<String, dynamic> _summaryData = {
    'totalPendapatan': 1250000,
    'biayaPromosi': 50000,
    'totalPenjualan': 1200000,
    'penjualanBersih': 1100000,
    'totalLabaKotor': 300000,
  };

  final Map<String, dynamic> _detailData = {
    'pendapatan': {
      'penjualanKotor': 1200000,
      'ongkosKirim': 20000,
      'biayaPelayanan': 15000,
      'biayaPelayananMDR': 10000,
      'pembulatan': 0,
      'pajak': 0,
      'lainnya': 5000,
    },
    'biayaPromosi': {
      'promoPembelian': 10000,
      'promoProduk': 15000,
      'komplimen': 25000,
    },
    'biayaAdministrasi': {
      'biayaAdministrasi': 10000,
    },
    'penjualanBersih': {
      'totalPenjualan': 1200000,
      'pengembalian': 100000,
    },
    'labaKotor': {
      'penjualanBersihLaba': 1100000,
      'biayaMDR': 20000,
      'hpp': 780000,
      'komisi': 0,
    }
  };

  int _calculateTotal(Map<String, dynamic> sectionData) {
    return sectionData.values.fold(0, (sum, item) => sum + (item as int));
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isMobile),
                const SizedBox(height: 24),
                _buildDateAndExport(context, isMobile),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Terakhir diperbarui: beberapa detik yang lalu',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryCards(isMobile),
                const SizedBox(height: 32),
                const Text(
                  'Rincian Ringkasan Penjualan',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333)),
                ),
                const SizedBox(height: 20),
                if (isMobile)
                  _buildDetailedSummaryMobile()
                else
                  _buildDetailedSummaryDesktop(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      children: [
        if (isMobile)
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF333333)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        const Text(
          'Ringkasan Penjualan',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333)),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Lihat detail ringkasan penjualan Anda.',
          child: Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildDateAndExport(BuildContext context, bool isMobile) {
    final formattedStartDate = DateFormat('dd MMM yyyy').format(_startDate);
    final formattedEndDate = DateFormat('dd MMM yyyy').format(_endDate);

    final datePicker = OutlinedButton.icon(
      onPressed: () => _selectDateRange(context),
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text('$formattedStartDate - $formattedEndDate'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[800],
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    final exportButton = ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.cloud_download_outlined, size: 18),
      label: const Text('Ekspor Laporan'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF279E9E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          datePicker,
          const SizedBox(height: 12),
          exportButton,
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          datePicker,
          exportButton,
        ],
      );
    }
  }

  Widget _buildSummaryCards(bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.0 : 1.3,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        String title;
        String value;
        Color color;
        IconData icon = Icons.info_outline;

        switch (index) {
          case 0:
            title = 'Total Pendapatan';
            value = _currencyFormatter.format(_summaryData['totalPendapatan']);
            color = const Color(0xFF279E9E); // Kashierku green
            break;
          case 1:
            title = 'Biaya Promosi';
            value = _currencyFormatter.format(_summaryData['biayaPromosi']);
            color = const Color(0xFFFFC107); // Kuning
            break;
          case 2:
            title = 'Total Penjualan';
            value = _currencyFormatter.format(_summaryData['totalPenjualan']);
            color = const Color(0xFF2196F3); // Biru
            break;
          case 3:
            title = 'Penjualan Bersih';
            value = _currencyFormatter.format(_summaryData['penjualanBersih']);
            color = const Color(0xFFE91E63); // Merah Muda
            break;
          case 4:
            title = 'Total Laba Kotor';
            value = _currencyFormatter.format(_summaryData['totalLabaKotor']);
            color = const Color(0xFF9C27B0); // Ungu
            break;
          default:
            title = '';
            value = '';
            color = Colors.grey;
        }

        return _SummaryCard(
          title: title,
          value: value,
          color: color,
          icon: icon,
        );
      },
    );
  }

  Widget _buildDetailedSummaryMobile() {
    return Column(
      children: [
        _Section(
          title: 'PENDAPATAN',
          formatter: _currencyFormatter,
          children: [
            _DetailRow(
                label: 'Penjualan Kotor',
                value: _detailData['pendapatan']['penjualanKotor'],
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Ongkos Kirim',
                value: _detailData['pendapatan']['ongkosKirim'],
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Biaya Pelayanan',
                value: _detailData['pendapatan']['biayaPelayanan'],
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Biaya Pelayanan MDR',
                value: _detailData['pendapatan']['biayaPelayananMDR'],
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Pembulatan',
                value: _detailData['pendapatan']['pembulatan'],
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Pajak',
                value: _detailData['pendapatan']['pajak'],
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Lainnya',
                value: _detailData['pendapatan']['lainnya'],
                formatter: _currencyFormatter),
          ],
          totalValue: _calculateTotal(_detailData['pendapatan']),
          totalLabel: 'TOTAL PENDAPATAN',
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'BIAYA PROMOSI',
          formatter: _currencyFormatter,
          children: [
            _DetailRow(
                label: 'Promo Pembelian',
                value: _detailData['biayaPromosi']['promoPembelian'],
                isNegative: true,
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Promo Produk',
                value: _detailData['biayaPromosi']['promoProduk'],
                isNegative: true,
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Komplimen',
                value: _detailData['biayaPromosi']['komplimen'],
                isNegative: true,
                formatter: _currencyFormatter),
          ],
          totalValue: _calculateTotal(_detailData['biayaPromosi']),
          totalLabel: 'TOTAL BIAYA PROMOSI',
          isTotalNegative: true,
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'BIAYA ADMINISTRASI',
          formatter: _currencyFormatter,
          children: [
            _DetailRow(
                label: 'Biaya Administrasi',
                value: _detailData['biayaAdministrasi']['biayaAdministrasi'],
                isNegative: true,
                formatter: _currencyFormatter),
          ],
          totalValue: _calculateTotal(_detailData['biayaAdministrasi']),
          totalLabel: 'TOTAL BIAYA ADMINISTRASI',
          isTotalNegative: true,
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'PENJUALAN BERSIH',
          formatter: _currencyFormatter,
          children: [
            _DetailRow(
                label: 'Total Penjualan',
                value: _detailData['penjualanBersih']['totalPenjualan'],
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Pengembalian',
                value: _detailData['penjualanBersih']['pengembalian'],
                isNegative: true,
                formatter: _currencyFormatter),
          ],
          totalValue: _calculateTotal(_detailData['penjualanBersih']),
          totalLabel: 'TOTAL PENJUALAN BERSIH',
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'LABA KOTOR',
          formatter: _currencyFormatter,
          children: [
            _DetailRow(
                label: 'Penjualan Bersih',
                value: _detailData['labaKotor']['penjualanBersihLaba'],
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Biaya MDR',
                value: _detailData['labaKotor']['biayaMDR'],
                isNegative: true,
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'HPP',
                value: _detailData['labaKotor']['hpp'],
                isNegative: true,
                formatter: _currencyFormatter),
            _DetailRow(
                label: 'Komisi',
                value: _detailData['labaKotor']['komisi'],
                isNegative: true,
                formatter: _currencyFormatter),
          ],
          totalValue: _calculateTotal(_detailData['labaKotor']),
          totalLabel: 'TOTAL LABA KOTOR',
        ),
      ],
    );
  }

  Widget _buildDetailedSummaryDesktop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _Section(
                title: 'PENDAPATAN',
                formatter: _currencyFormatter,
                children: [
                  _DetailRow(
                      label: 'Penjualan Kotor',
                      value: _detailData['pendapatan']['penjualanKotor'],
                      formatter: _currencyFormatter),
                  _DetailRow(
                      label: 'Ongkos Kirim',
                      value: _detailData['pendapatan']['ongkosKirim'],
                      formatter: _currencyFormatter),
                  _DetailRow(
                      label: 'Biaya Pelayanan',
                      value: _detailData['pendapatan']['biayaPelayanan'],
                      formatter: _currencyFormatter),
                  _DetailRow(
                      label: 'Biaya Pelayanan MDR',
                      value: _detailData['pendapatan']['biayaPelayananMDR'],
                      formatter: _currencyFormatter),
                  _DetailRow(
                      label: 'Pembulatan',
                      value: _detailData['pendapatan']['pembulatan'],
                      formatter: _currencyFormatter),
                  _DetailRow(
                      label: 'Pajak',
                      value: _detailData['pendapatan']['pajak'],
                      formatter: _currencyFormatter),
                  _DetailRow(
                      label: 'Lainnya',
                      value: _detailData['pendapatan']['lainnya'],
                      formatter: _currencyFormatter),
                ],
                totalValue: _calculateTotal(_detailData['pendapatan']),
                totalLabel: 'TOTAL PENDAPATAN',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _Section(
                    title: 'BIAYA PROMOSI',
                    formatter: _currencyFormatter,
                    children: [
                      _DetailRow(
                          label: 'Promo Pembelian',
                          value: _detailData['biayaPromosi']['promoPembelian'],
                          isNegative: true,
                          formatter: _currencyFormatter),
                      _DetailRow(
                          label: 'Promo Produk',
                          value: _detailData['biayaPromosi']['promoProduk'],
                          isNegative: true,
                          formatter: _currencyFormatter),
                      _DetailRow(
                          label: 'Komplimen',
                          value: _detailData['biayaPromosi']['komplimen'],
                          isNegative: true,
                          formatter: _currencyFormatter),
                    ],
                    totalValue: _calculateTotal(_detailData['biayaPromosi']),
                    totalLabel: 'TOTAL BIAYA PROMOSI',
                    isTotalNegative: true,
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'PENJUALAN BERSIH',
                    formatter: _currencyFormatter,
                    children: [
                      _DetailRow(
                          label: 'Total Penjualan',
                          value: _detailData['penjualanBersih']['totalPenjualan'],
                          formatter: _currencyFormatter),
                      _DetailRow(
                          label: 'Pengembalian',
                          value: _detailData['penjualanBersih']['pengembalian'],
                          isNegative: true,
                          formatter: _currencyFormatter),
                    ],
                    totalValue: _calculateTotal(_detailData['penjualanBersih']),
                    totalLabel: 'TOTAL PENJUALAN BERSIH',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _Section(
                title: 'BIAYA ADMINISTRASI',
                formatter: _currencyFormatter,
                children: [
                  _DetailRow(
                      label: 'Biaya Administrasi',
                      value: _detailData['biayaAdministrasi']['biayaAdministrasi'],
                      isNegative: true,
                      formatter: _currencyFormatter),
                ],
                totalValue: _calculateTotal(_detailData['biayaAdministrasi']),
                totalLabel: 'TOTAL BIAYA ADMINISTRASI',
                isTotalNegative: true,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _Section(
                title: 'LABA KOTOR',
                formatter: _currencyFormatter,
                children: [
                  _DetailRow(
                      label: 'Penjualan Bersih',
                      value: _detailData['labaKotor']['penjualanBersihLaba'],
                      formatter: _currencyFormatter),
                  _DetailRow(
                      label: 'Biaya MDR',
                      value: _detailData['labaKotor']['biayaMDR'],
                      isNegative: true,
                      formatter: _currencyFormatter),
                  _DetailRow(
                      label: 'HPP',
                      value: _detailData['labaKotor']['hpp'],
                      isNegative: true,
                      formatter: _currencyFormatter),
                  _DetailRow(
                      label: 'Komisi',
                      value: _detailData['labaKotor']['komisi'],
                      isNegative: true,
                      formatter: _currencyFormatter),
                ],
                totalValue: _calculateTotal(_detailData['labaKotor']),
                totalLabel: 'TOTAL LABA KOTOR',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Informasi tentang $title',
                  child: Icon(icon, color: Colors.grey[400], size: 16),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333)),
                maxLines: 1,
              ),
            ),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final int totalValue;
  final String totalLabel;
  final bool isTotalNegative;
  final NumberFormat formatter;

  _Section({
    required this.title,
    required this.children,
    required this.totalValue,
    required this.totalLabel,
    required this.formatter,
    this.isTotalNegative = false,
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
              blurRadius: 10)
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
            isNegative: isTotalNegative,
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
            fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final int value;
  final NumberFormat formatter;
  final bool isNegative;

  _DetailRow({
    required this.label,
    required this.value,
    required this.formatter,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              if (label == 'Penjualan Kotor' ||
                  label == 'Penjualan Bersih' ||
                  label == 'Biaya Administrasi')
                Tooltip(
                  message: 'Informasi tentang $label',
                  child:
                  Icon(Icons.info_outline, color: Colors.grey[400], size: 16),
                ),
            ],
          ),
          Text(
            isNegative
                ? '( ${formatter.format(value)} )'
                : formatter.format(value),
            style: TextStyle(
              fontSize: 14,
              color: isNegative ? Colors.red[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final int value;
  final NumberFormat formatter;
  final bool isNegative;

  _TotalRow({
    required this.label,
    required this.value,
    required this.formatter,
    this.isNegative = false,
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
                color: Colors.black87),
          ),
          Text(
            isNegative
                ? '( ${formatter.format(value)} )'
                : formatter.format(value),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isNegative ? Colors.red[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}