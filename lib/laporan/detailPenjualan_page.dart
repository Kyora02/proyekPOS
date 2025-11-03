import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailPenjualanPage extends StatefulWidget {
  const DetailPenjualanPage({super.key});

  @override
  State<DetailPenjualanPage> createState() => _DetailPenjualanPageState();
}

class _DetailPenjualanPageState extends State<DetailPenjualanPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  final List<Map<String, dynamic>> _dummyData = [
    {
      'noTransaksi': 'TRX-001',
      'outlet': 'Cabang Pusat',
      'totalPenjualan': 150000,
      'metodePembayaran': 'QRIS',
      'timestamp': DateTime(2025, 10, 30, 14, 30),
      'customer': 'John Doe',
    },
    {
      'noTransaksi': 'TRX-002',
      'outlet': 'Cabang Selatan',
      'totalPenjualan': 75000,
      'metodePembayaran': 'Tunai',
      'timestamp': DateTime(2025, 10, 30, 12, 15),
      'customer': 'Walk-in',
    },
    {
      'noTransaksi': 'TRX-003',
      'outlet': 'Cabang Pusat',
      'totalPenjualan': 220000,
      'metodePembayaran': 'Debit',
      'timestamp': DateTime(2025, 10, 29, 11, 05),
      'customer': 'Jane Smith',
    },
    {
      'noTransaksi': 'TRX-004',
      'outlet': 'Cabang Utara',
      'totalPenjualan': 510000,
      'metodePembayaran': 'Transfer',
      'timestamp': DateTime(2025, 10, 28, 18, 45),
      'customer': 'Robert Brown',
    },
    {
      'noTransaksi': 'TRX-005',
      'outlet': 'Cabang Timur',
      'totalPenjualan': 90000,
      'metodePembayaran': 'QRIS',
      'timestamp': DateTime(2025, 10, 27, 09, 00),
      'customer': 'Alice Wonderland',
    },
  ];

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
      firstDate: newStartDate, // Tanggal akhir tidak bisa sebelum tanggal mulai
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _dummyData.where((item) {
      final query = _searchController.text.toLowerCase();
      final noTransaksi = item['noTransaksi'].toString().toLowerCase();
      final outlet = item['outlet'].toString().toLowerCase();
      final metodePembayaran = item['metodePembayaran'].toString().toLowerCase();
      final customer = item['customer'].toString().toLowerCase();
      final date = item['timestamp'] as DateTime;

      final matchesQuery = query.isEmpty ||
          noTransaksi.contains(query) ||
          outlet.contains(query) ||
          metodePembayaran.contains(query) ||
          customer.contains(query);

      final matchesDate =
          date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              date.isBefore(_endDate.add(const Duration(days: 1)));

      return matchesQuery && matchesDate;
    }).toList();

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
                    if (isMobile)
                      _buildMobileList(filteredData)
                    else
                      _buildWebTable(filteredData),
                    const SizedBox(height: 24),
                    if (!isMobile) _buildPagination(),
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
          onPressed: () {},
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
      width: isMobile ? double.infinity : 280,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Cari No. Transaksi, Outlet, Pelanggan...',
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        searchField,
        const SizedBox(width: 16),
        datePicker,
      ],
    );
  }

  Widget _buildWebTable(List<Map<String, dynamic>> data) {
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
        children: [
          _buildTableHeader(),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Tidak ada data penjualan ditemukan.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) => _buildTableRow(data[index]),
              separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 24,
                  endIndent: 24,
                  color: Color(0xFFEEEEEE)),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('NO. TRANSAKSI', style: _tableHeaderStyle())),
          Expanded(
              flex: 2, child: Text('OUTLET', style: _tableHeaderStyle())),
          Expanded(
              flex: 2,
              child: Text('METODE PEMBAYARAN', style: _tableHeaderStyle())),
          Expanded(
              flex: 2,
              child: Text('TOTAL PENJUALAN',
                  style: _tableHeaderStyle(), textAlign: TextAlign.right)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(item['noTransaksi'], style: _tableBodyStyle())),
          Expanded(
              flex: 2, child: Text(item['outlet'], style: _tableBodyStyle())),
          Expanded(
              flex: 2,
              child: Text(item['metodePembayaran'], style: _tableBodyStyle())),
          Expanded(
              flex: 2,
              child: Text(_currencyFormatter.format(item['totalPenjualan']),
                  style: _tableBodyStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right)),
          SizedBox(
            width: 48,
            child: PopupMenuButton<String>(
              color: Colors.white,
              icon: const Icon(Icons.more_horiz, color: Color(0xFF279E9E)),
              onSelected: (value) {},
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'lihat_detail',
                  child: Text('Lihat Detail'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Text('Tidak ada data penjualan ditemukan.')),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) => _buildMobileCard(data[index]),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['noTransaksi'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFormatter.format(item['timestamp']),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: Colors.white,
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF279E9E)),
                  onSelected: (value) {},
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'lihat_detail',
                      child: Text('Lihat Detail'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.store_outlined, 'Outlet', item['outlet']),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.credit_card_outlined, 'Metode Bayar',
                item['metodePembayaran']),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Penjualan:',
                    style: TextStyle(color: Colors.black87)),
                Text(
                  _currencyFormatter.format(item['totalPenjualan']),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF279E9E)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: Colors.grey[700])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() {
    return TextStyle(
        fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700]);
  }

  TextStyle _tableBodyStyle({FontWeight fontWeight = FontWeight.normal}) {
    return TextStyle(
        fontSize: 14, color: Colors.black87, fontWeight: fontWeight);
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Ditampilkan 1 - 5 dari 5 data',
          style: TextStyle(color: Colors.grey),
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