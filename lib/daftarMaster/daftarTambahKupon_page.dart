import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaftarTambahKuponPage extends StatefulWidget {
  const DaftarTambahKuponPage({super.key});

  @override
  State<DaftarTambahKuponPage> createState() => _DaftarTambahKuponPageState();
}

class _DaftarTambahKuponPageState extends State<DaftarTambahKuponPage> {
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  final List<Map<String, dynamic>> _allCoupons = [
    { "kode": "GILA10K", "nama": "Diskon Gila", "besaranTipe": "rupiah", "besaranNilai": 10000, "durasi": "N/A", "outlet": "Kashierku Pusat", "status": "Baru" },
    { "kode": "GAJIAN25", "nama": "Promo Gajian", "besaranTipe": "persen", "besaranNilai": 25, "durasi": "N/A", "outlet": "Semua Outlet", "status": "Digunakan" },
    { "kode": "OKTOBERFEST", "nama": "Spesial Oktober", "besaranTipe": "persen", "besaranNilai": 15, "durasi": "N/A", "outlet": "Kashierku Cabang A", "status": "Baru" },
    { "kode": "LAMA01", "nama": "Kupon Hangus", "besaranTipe": "rupiah", "besaranNilai": 5000, "durasi": "N/A", "outlet": "Kashierku Cabang B", "status": "Kedaluwarsa" },
  ];

  List<Map<String, dynamic>> get _filteredCoupons {
    List<Map<String, dynamic>> coupons = _allCoupons;
    if (_searchQuery.isNotEmpty) {
      coupons = coupons.where((coupon) {
        final name = (coupon['nama'] as String? ?? '').toLowerCase();
        final code = (coupon['kode'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || code.contains(query);
      }).toList();
    }
    return coupons;
  }

  String _formatCurrency(int amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  String _formatBesaran(Map<String, dynamic> coupon) => coupon['besaranTipe'] == 'persen' ? '${coupon['besaranNilai']}%' : _formatCurrency(coupon['besaranNilai'] ?? 0);
  String _formatDurasi(Map<String, dynamic> coupon) => coupon['durasi'] ?? 'N/A';

  void _navigateToAddCoupon() {
    Navigator.of(context, rootNavigator: true).pushNamed('/tambah-kupon');
  }

 @override
  Widget build(BuildContext context) {
    final totalItems = _filteredCoupons.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final couponsOnCurrentPage = _filteredCoupons.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 950;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 600 : 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    const SizedBox(height: 24),
                    _buildFilterBar(),
                    const SizedBox(height: 24),
                    isMobile
                        ? _buildMobileCouponList(couponsOnCurrentPage)
                        : _buildDesktopCouponTable(couponsOnCurrentPage),
                    if (!isMobile) ...[
                      const Divider(height: 32),
                      _buildPaginationFooter(totalItems, totalPages),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI WIDGET BUILDERS ---
  Widget _buildHeader(bool isMobile) {
    return isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tambah Kupon', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToAddCoupon,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Tambah Kupon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF279E9E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Daftar Kupon', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _navigateToAddCoupon,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Tambah Kupon'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 12.0,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            decoration: _inputDecoration(hint: 'Cari nama/kode kupon...', prefixIcon: const Icon(Icons.search)),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white, // White background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!), // With a grey border
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text('01 Okt 2025 - 31 Okt 2025', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCouponTable(List<Map<String, dynamic>> coupons) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!)
      ),
      child: Column(
        children: [
          _buildDesktopTableHeader(),
          const Divider(height: 1, color: Colors.grey),
          if (coupons.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Text('Tidak ada kupon ditemukan.'))
          else
            ...coupons.map((coupon) => _buildTableRow(coupon)).toList(),
        ],
      ),
    );
  }

  Widget _buildDesktopTableHeader() {
    TextStyle headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(children: [
        Expanded(flex: 3, child: Text('KODE KUPON', style: headerStyle)),
        Expanded(flex: 3, child: Text('NAMA KUPON', style: headerStyle)),
        Expanded(flex: 2, child: Text('BESARAN', style: headerStyle)),
        Expanded(flex: 3, child: Text('DURASI', style: headerStyle)),
        Expanded(flex: 2, child: Text('OUTLET', style: headerStyle)),
        Expanded(flex: 2, child: Text('STATUS', style: headerStyle)),
        const SizedBox(width: 48),
      ]),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> coupon) {
    TextStyle cellStyle = const TextStyle(fontSize: 14, color: Colors.black87);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(flex: 3, child: Text(coupon['kode'] ?? 'N/A', style: cellStyle)),
        Expanded(flex: 3, child: Text(coupon['nama'] ?? 'N/A', style: cellStyle)),
        Expanded(flex: 2, child: Text(_formatBesaran(coupon), style: cellStyle)),
        Expanded(flex: 3, child: Text(_formatDurasi(coupon), style: cellStyle)),
        Expanded(flex: 2, child: Text(coupon['outlet'] ?? 'N/A', style: cellStyle)),
        Expanded(flex: 2, child: _buildStatusChip(coupon['status'] ?? 'N/A')),
        _buildPopupMenuButton(coupon),
      ]),
    );
  }

  Widget _buildMobileCouponList(List<Map<String, dynamic>> coupons) {
    if (coupons.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: Text('Tidak ada kupon ditemukan.')));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coupons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _buildMobileCard(coupons[index]),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> coupon) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(coupon['nama'] ?? 'N/A', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Kode: ${coupon['kode'] ?? 'N/A'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ]),
              ),
              _buildPopupMenuButton(coupon),
            ]),
            const Divider(height: 24),
            _buildInfoRow(Icons.sell_outlined, 'Besaran', _formatBesaran(coupon)),
            _buildInfoRow(Icons.date_range_outlined, 'Durasi', _formatDurasi(coupon)),
            _buildInfoRow(Icons.storefront_outlined, 'Outlet', coupon['outlet'] ?? 'N/A'),
            Row(children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const Spacer(),
              _buildStatusChip(coupon['status'] ?? 'N/A'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ]),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Baru': chipColor = Colors.green; break;
      case 'Digunakan': chipColor = Colors.blue; break;
      case 'Kedaluwarsa': chipColor = Colors.red; break;
      default: chipColor = Colors.grey;
    }
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildPopupMenuButton(Map<String, dynamic> coupon) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        icon: const Icon(Icons.more_horiz, color: Colors.grey),
        onSelected: (String value) {},
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          _buildPopupMenuItem(value: 'ubah', text: 'Ubah', icon: Icons.edit_outlined),
          _buildPopupMenuItem(value: 'hapus', text: 'Hapus', icon: Icons.delete_outline, isDestructive: true),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({required String value, required String text, required IconData icon, bool isDestructive = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.black54),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: isDestructive ? Colors.red : null)),
      ]),
    );
  }

  Widget _buildPaginationFooter(int totalItems, int totalPages) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 16),
        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
        color: _currentPage > 1 ? Colors.black87 : Colors.grey,
      ),
      Container(
        width: 36, height: 36, alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFF279E9E), borderRadius: BorderRadius.circular(8)),
        child: Text('$_currentPage', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward_ios, size: 16),
        onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
        color: _currentPage < totalPages ? Colors.black87 : Colors.grey,
      ),
    ]);
  }

  // --- CHANGED: This function defines the style for the filter fields ---
  InputDecoration _inputDecoration({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      isDense: true,
      filled: true,
      fillColor: Colors.white, // White background
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder( // Default border
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder( // Border when not focused
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder( // Border when focused
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF279E9E), width: 1.5),
      ),
    );
  }
}