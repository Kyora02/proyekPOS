import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service//api_service.dart';

class RingkasanPembelianPage extends StatefulWidget {
  final String outletId;

  const RingkasanPembelianPage({
    Key? key,
    required this.outletId,
  }) : super(key: key);

  @override
  State<RingkasanPembelianPage> createState() => _RingkasanPembelianPageState();
}

class _RingkasanPembelianPageState extends State<RingkasanPembelianPage> {
  final ApiService _apiService = ApiService();
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Define common padding values
  static const double _horizontalPadding = 16.0;
  // New: Define left margin to push content away from the (assumed) sidebar
  static const double _leftMargin = 20.0;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  Map<String, dynamic>? _summaryData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getPurchaseSummary(
        outletId: widget.outletId,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _summaryData = data;
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
                    Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF279E9E),
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: isSelectingStart ? tempStartDate : tempEndDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
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
                            _fetchSummary();
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

  Widget _buildDateRangeButton() {
    return InkWell(
      onTap: () => _showDatePickerDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF279E9E)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New Widget: Wrap the body content with padding
  Widget _buildContent() {
    return Padding(
      // Apply left margin and remove the top/bottom padding from the main Column
      padding: const EdgeInsets.only(left: _leftMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Title Update: Increase the font size for the page title
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              'Ringkasan Pembelian',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24, // Increased font size
                color: Colors.black87,
              ),
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 0,
                  child: _buildDateRangeButton(),
                ),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF279E9E)))
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchSummary,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
                : _summaryData == null
                ? const Center(child: Text('Tidak ada data'))
                : _buildSummaryContent(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // Remove title from AppBar since we are moving it to the body for style
        title: const Text(''),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // Use the new _buildContent widget for the body
      body: _buildContent(),
    );
  }

  Widget _buildSummaryContent() {
    final totalBiayaKeseluruhan = _summaryData!['totalBiayaKeseluruhan'] ?? 0;
    final totalPembelianBahanBaku = _summaryData!['totalPembelianBahanBaku'] ?? 0;
    final jumlahTransaksiBahanBaku = _summaryData!['jumlahTransaksiBahanBaku'] ?? 0;
    final rataRataPerTransaksi = _summaryData!['rataRataPerTransaksi'] ?? 0;
    final totalBiayaProduk = _summaryData!['totalBiayaProduk'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: _horizontalPadding,
        right: _horizontalPadding,
        top: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Biaya Keseluruhan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(totalBiayaKeseluruhan),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Pembelian Bahan Baku'),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.shopping_cart,
            iconColor: Colors.orange,
            title: 'Total Pembelian Bahan Baku',
            value: currencyFormat.format(totalPembelianBahanBaku),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.receipt_long,
            iconColor: Colors.green,
            title: 'Jumlah Transaksi',
            value: '$jumlahTransaksiBahanBaku kali',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.analytics,
            iconColor: Colors.purple,
            title: 'Rata-rata per Transaksi',
            value: currencyFormat.format(rataRataPerTransaksi),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Biaya Produk (Cost Price)'),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.inventory_2,
            iconColor: Colors.red,
            title: 'Total Biaya Produk',
            value: currencyFormat.format(totalBiayaProduk),
            subtitle: 'Berdasarkan produk terjual × cost price',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Total biaya keseluruhan = Pembelian bahan baku + Biaya produk (HPP)',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}