import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PenjualanKategoriPage extends StatefulWidget {
  const PenjualanKategoriPage({super.key});

  @override
  State<PenjualanKategoriPage> createState() => _PenjualanKategoriPageState();
}

class _PenjualanKategoriPageState extends State<PenjualanKategoriPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');

  final List<Map<String, dynamic>> _dummyData = [
    {
      'kategori': 'Makanan',
      'jumlahProduk': 5,
      'produkPersen': 25.0,
      'penjualanRp': 2500000,
      'penjualanPersen': 40.0,
      'hppRp': 1000000,
      'timestamp': DateTime(2025, 10, 30),
    },
    {
      'kategori': 'Minuman',
      'jumlahProduk': 3,
      'produkPersen': 15.0,
      'penjualanRp': 1500000,
      'penjualanPersen': 30.0,
      'hppRp': 500000,
      'timestamp': DateTime(2025, 10, 29),
    },
    {
      'kategori': 'Snack',
      'jumlahProduk': 2,
      'produkPersen': 10.0,
      'penjualanRp': 1000000,
      'penjualanPersen': 20.0,
      'hppRp': 300000,
      'timestamp': DateTime(2025, 10, 28),
    },
    {
      'kategori': 'Dessert',
      'jumlahProduk': 1,
      'produkPersen': 5.0,
      'penjualanRp': 200000,
      'penjualanPersen': 10.0,
      'hppRp': 50000,
      'timestamp': DateTime(2025, 10, 27),
    },
  ];

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
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
      final kategori = item['kategori'].toString().toLowerCase();
      final date = item['timestamp'] as DateTime;

      final matchesQuery = query.isEmpty || kategori.contains(query);

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
                    if (!isMobile) _buildPagination(filteredData.length),
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
              'Penjualan Kategori',
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
          hintText: 'Cari Kategori...',
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
              child: Text('Tidak ada data penjualan kategori ditemukan.'),
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
          Expanded(flex: 3, child: Text('KATEGORI', style: _tableHeaderStyle())),
          Expanded(
              flex: 2,
              child: Text('JUMLAH PRODUK',
                  style: _tableHeaderStyle(), textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('PRODUK (%)',
                  style: _tableHeaderStyle(), textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text('PENJUALAN (RP)',
                  style: _tableHeaderStyle(), textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text('PENJUALAN (%)',
                  style: _tableHeaderStyle(), textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text('HPP (RP)',
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
              flex: 3, child: Text(item['kategori'], style: _tableBodyStyle())),
          Expanded(
              flex: 2,
              child: Text(item['jumlahProduk'].toString(),
                  style: _tableBodyStyle(), textAlign: TextAlign.center)),
          Expanded(
              flex: 2,
              child: Text('${item['produkPersen']}%',
                  style: _tableBodyStyle(), textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text(_currencyFormatter.format(item['penjualanRp']),
                  style: _tableBodyStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text('${item['penjualanPersen']}%',
                  style: _tableBodyStyle(), textAlign: TextAlign.right)),
          Expanded(
              flex: 2,
              child: Text(_currencyFormatter.format(item['hppRp']),
                  style: _tableBodyStyle(), textAlign: TextAlign.right)),
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
        child:
        Center(child: Text('Tidak ada data penjualan kategori ditemukan.')),
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
                        item['kategori'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jumlah Produk: ${item['jumlahProduk']}',
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
            _buildDetailRow(
                Icons.pie_chart_outline, 'Produk (%)', '${item['produkPersen']}%'),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.show_chart, 'Penjualan (%)',
                '${item['penjualanPersen']}%'),
            const SizedBox(height: 8),
            _buildDetailRow(
                Icons.money_off, 'HPP (RP)', _currencyFormatter.format(item['hppRp'])),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Penjualan:',
                    style: TextStyle(color: Colors.black87)),
                Text(
                  _currencyFormatter.format(item['penjualanRp']),
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

  Widget _buildPagination(int totalItems) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Ditampilkan 1 - $totalItems dari $totalItems data',
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