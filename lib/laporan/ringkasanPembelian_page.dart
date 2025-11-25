import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service/api_service.dart';

class RingkasanPembelianPage extends StatefulWidget {
  final String outletId;
  const RingkasanPembelianPage({super.key, required this.outletId});

  @override
  State<RingkasanPembelianPage> createState() => _RingkasanPembelianPageState();
}

class _RingkasanPembelianPageState extends State<RingkasanPembelianPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  Map<String, dynamic>? _summaryData;
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService().getPurchaseSummary(
        outletId: widget.outletId,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _summaryData = data;
        _lastUpdated = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showDatePickerDialog(BuildContext context) {
    DateTime tempStartDate = _startDate;
    DateTime tempEndDate = _endDate;
    bool isSelectingStart = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isSelectingStart ? 'Pilih Tanggal Mulai' : 'Pilih Tanggal Akhir',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isSelectingStart = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelectingStart ? const Color(0xFF279E9E) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(tempStartDate),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelectingStart ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward, size: 20),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isSelectingStart = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isSelectingStart ? const Color(0xFF279E9E) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(tempEndDate),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !isSelectingStart ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CalendarDatePicker(
                      initialDate: isSelectingStart ? tempStartDate : tempEndDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2030),
                      onDateChanged: (DateTime date) {
                        setDialogState(() {
                          if (isSelectingStart) {
                            tempStartDate = date;
                            if (tempStartDate.isAfter(tempEndDate)) {
                              tempEndDate = tempStartDate;
                            }
                          } else {
                            tempEndDate = date;
                            if (tempEndDate.isBefore(tempStartDate)) {
                              tempStartDate = tempEndDate;
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _startDate = tempStartDate;
                              _endDate = tempEndDate;
                            });
                            Navigator.pop(context);
                            _loadData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF279E9E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Terapkan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
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
                  if (_lastUpdated != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Terakhir diperbarui: ${_getTimeAgo(_lastUpdated!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF279E9E),
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat data',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF279E9E),
                              ),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                      _buildSummaryCards(isMobile),
                      const SizedBox(height: 32),
                      const Text(
                        'Rincian Ringkasan Pembelian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isMobile)
                        _buildDetailedSummaryMobile()
                      else
                        _buildDetailedSummaryDesktop(),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'beberapa detik yang lalu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
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
          'Ringkasan Pembelian',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Lihat detail ringkasan pembelian dan pengeluaran.',
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
      onPressed: () => _showDatePickerDialog(context),
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
    if (_summaryData == null) return const SizedBox.shrink();

    final totalPembelianBahanBaku = _summaryData!['totalPembelianBahanBaku'] ?? 0;
    final jumlahTransaksiBahanBaku = _summaryData!['jumlahTransaksiBahanBaku'] ?? 0;
    final rataRataPerTransaksi = _summaryData!['rataRataPerTransaksi'] ?? 0;

    final cards = [
      {
        'title': 'Total Biaya (Pembelian)',
        'value': totalPembelianBahanBaku,
        'color': const Color(0xFF279E9E),
        'isCurrency': true
      },
      {
        'title': 'Pembelian Bahan Baku',
        'value': totalPembelianBahanBaku,
        'color': const Color(0xFFFFC107),
        'isCurrency': true
      },
      {
        'title': 'Jumlah Transaksi',
        'value': jumlahTransaksiBahanBaku,
        'color': const Color(0xFFE91E63),
        'isCurrency': false
      },
      {
        'title': 'Rata-rata / Transaksi',
        'value': rataRataPerTransaksi,
        'color': const Color(0xFF9C27B0),
        'isCurrency': true
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.5 : 2.1,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final val = cards[index]['value'] as num;
        final isCurr = cards[index]['isCurrency'] as bool;
        final formattedValue = isCurr ? _currencyFormatter.format(val) : '$val';

        return _SummaryCard(
          title: cards[index]['title'] as String,
          value: formattedValue,
          color: cards[index]['color'] as Color,
          icon: Icons.info_outline,
        );
      },
    );
  }

  Widget _buildDetailedSummaryMobile() {
    if (_summaryData == null) return const SizedBox.shrink();

    final totalPembelianBahanBaku = _summaryData!['totalPembelianBahanBaku'] ?? 0;
    final jumlahTransaksiBahanBaku = _summaryData!['jumlahTransaksiBahanBaku'] ?? 0;
    final rataRataPerTransaksi = _summaryData!['rataRataPerTransaksi'] ?? 0;

    return Column(
      children: [
        _Section(
          title: 'RINCIAN BAHAN BAKU',
          formatter: _currencyFormatter,
          children: [
            _DetailRow(
              label: 'Total Pembelian',
              value: totalPembelianBahanBaku,
              formatter: _currencyFormatter,
            ),
            _DetailRow(
              label: 'Jumlah Transaksi',
              value: jumlahTransaksiBahanBaku,
              formatter: NumberFormat.decimalPattern(),
              isNonCurrency: true,
            ),
            _DetailRow(
              label: 'Rata-rata Transaksi',
              value: rataRataPerTransaksi,
              formatter: _currencyFormatter,
            ),
          ],
          totalValue: totalPembelianBahanBaku,
          totalLabel: 'TOTAL BAHAN BAKU',
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'TOTAL PENGELUARAN',
          formatter: _currencyFormatter,
          children: [
            _DetailRow(
              label: 'Total Bahan Baku',
              value: totalPembelianBahanBaku,
              formatter: _currencyFormatter,
              isNegative: true,
            ),
          ],
          // Correct Logic: Total Overall Cost equals Raw Material Purchase
          totalValue: totalPembelianBahanBaku,
          totalLabel: 'TOTAL BIAYA KESELURUHAN',
          isTotalNegative: true,
        ),
      ],
    );
  }

  Widget _buildDetailedSummaryDesktop() {
    if (_summaryData == null) return const SizedBox.shrink();

    final totalPembelianBahanBaku = _summaryData!['totalPembelianBahanBaku'] ?? 0;
    final jumlahTransaksiBahanBaku = _summaryData!['jumlahTransaksiBahanBaku'] ?? 0;
    final rataRataPerTransaksi = _summaryData!['rataRataPerTransaksi'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _Section(
                title: 'RINCIAN BAHAN BAKU',
                formatter: _currencyFormatter,
                children: [
                  _DetailRow(
                    label: 'Total Pembelian',
                    value: totalPembelianBahanBaku,
                    formatter: _currencyFormatter,
                  ),
                  _DetailRow(
                    label: 'Jumlah Transaksi',
                    value: jumlahTransaksiBahanBaku,
                    formatter: NumberFormat.decimalPattern(),
                    isNonCurrency: true,
                  ),
                  _DetailRow(
                    label: 'Rata-rata Transaksi',
                    value: rataRataPerTransaksi,
                    formatter: _currencyFormatter,
                  ),
                ],
                totalValue: totalPembelianBahanBaku,
                totalLabel: 'TOTAL BAHAN BAKU',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _Section(
                title: 'TOTAL PENGELUARAN',
                formatter: _currencyFormatter,
                children: [
                  _DetailRow(
                    label: 'Total Bahan Baku',
                    value: totalPembelianBahanBaku,
                    formatter: _currencyFormatter,
                    isNegative: true,
                  ),
                ],
                // Correct Logic: Total Overall Cost equals Raw Material Purchase
                totalValue: totalPembelianBahanBaku,
                totalLabel: 'TOTAL BIAYA KESELURUHAN',
                isTotalNegative: true,
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

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: Colors.grey[300], size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              maxLines: 1,
            ),
            const Spacer(),
            Container(
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
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
  final num totalValue;
  final String totalLabel;
  final bool isTotalNegative;
  final NumberFormat formatter;

  const _Section({
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
  final num value;
  final NumberFormat formatter;
  final bool isNegative;
  final bool isNonCurrency;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.formatter,
    this.isNegative = false,
    this.isNonCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    String displayValue;
    if (isNonCurrency) {
      displayValue = formatter.format(value);
    } else {
      displayValue = isNegative ? '( ${formatter.format(value)} )' : formatter.format(value);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Text(
            displayValue,
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
  final num value;
  final NumberFormat formatter;
  final bool isNegative;

  const _TotalRow({
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
              color: Colors.black87,
            ),
          ),
          Text(
            isNegative ? '( ${formatter.format(value)} )' : formatter.format(value),
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