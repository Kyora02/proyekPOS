import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaftarKuponPage extends StatefulWidget {
  const DaftarKuponPage({super.key});

  @override
  State<DaftarKuponPage> createState() => _DaftarKuponPageState();
}

class _DaftarKuponPageState extends State<DaftarKuponPage> {
  final List<Map<String, dynamic>> _dummyCoupons = [
    {
      "nama": "Diskon Gila",
      "kode": "GILA10K",
      "besaranTipe": "rupiah",
      "besaranNilai": 10000,
      "tanggalMulai": "2025-10-01",
      "tanggalSelesai": "2025-10-15",
      "status": "Baru",
      "outlet": "Kashierku Pusat"
    },
    {
      "nama": "Promo Gajian",
      "kode": "GAJIAN25",
      "besaranTipe": "persen",
      "besaranNilai": 25,
      "tanggalMulai": "2025-09-25",
      "tanggalSelesai": "2025-10-05",
      "status": "Digunakan",
      "outlet": "Semua Outlet"
    },
    {
      "nama": "Spesial Oktober",
      "kode": "OKTOBERFEST",
      "besaranTipe": "persen",
      "besaranNilai": 15,
      "tanggalMulai": "2025-10-10",
      "tanggalSelesai": "2025-10-31",
      "status": "Baru",
      "outlet": "Kashierku Cabang A"
    },
    {
      "nama": "Kupon Hangus",
      "kode": "LAMA01",
      "besaranTipe": "rupiah",
      "besaranNilai": 5000,
      "tanggalMulai": "2025-09-01",
      "tanggalSelesai": "2025-09-30",
      "status": "Kedaluwarsa",
      "outlet": "Kashierku Cabang B"
    },
  ];

  // State for filters
  String _searchQuery = '';
  String? _selectedStatus = 'Semua Status';
  String? _selectedOutlet = 'Semua Outlet';

  // Options for dropdowns
  final List<String> _statusOptions = ['Semua Status', 'Baru', 'Digunakan', 'Kedaluwarsa'];
  final List<String> _outletOptions = ['Semua Outlet', 'Kashierku Pusat', 'Kashierku Cabang A', 'Kashierku Cabang B'];


  int _currentPage = 1;
  final int _itemsPerPage = 10;

  String _formatCurrency(int amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  String _formatBesaran(Map<String, dynamic> coupon) {
    String type = coupon['besaranTipe'] ?? '';
    int value = coupon['besaranNilai'] ?? 0;
    if (type == 'persen') {
      return '$value%';
    }
    return _formatCurrency(value);
  }

  String _formatDurasi(Map<String, dynamic> coupon) {
    try {
      final startDate = DateFormat('yyyy-MM-dd').parse(coupon['tanggalMulai']);
      final endDate = DateFormat('yyyy-MM-dd').parse(coupon['tanggalSelesai']);
      final format = DateFormat('dd MMM yyyy', 'id_ID');
      return '${format.format(startDate)} - ${format.format(endDate)}';
    } catch (e) {
      return 'N/A';
    }
  }

  List<Map<String, dynamic>> get _filteredCoupons {
    List<Map<String, dynamic>> coupons = _dummyCoupons;

    if (_searchQuery.isNotEmpty) {
      coupons = coupons.where((coupon) {
        final name = coupon['nama']?.toLowerCase() ?? '';
        final code = coupon['kode']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || code.contains(query);
      }).toList();
    }

    if (_selectedStatus != null && _selectedStatus != 'Semua Status') {
      coupons = coupons.where((coupon) => coupon['status'] == _selectedStatus).toList();
    }

    if (_selectedOutlet != null && _selectedOutlet != 'Semua Outlet') {
      coupons = coupons.where((coupon) {
        return coupon['outlet'] == _selectedOutlet || coupon['outlet'] == 'Semua Outlet';
      }).toList();
    }

    return coupons;
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String couponName) {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Konfirmasi Hapus'),
            content: Text('Apakah Anda yakin ingin menghapus kupon "$couponName"?'),
            actions: <Widget>[
              TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Hapus'),
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kupon "$couponName" berhasil dihapus'), backgroundColor: Colors.green),
                  );
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int totalItems = _filteredCoupons.length;
        final int totalPages = (totalItems / _itemsPerPage).ceil();

        final int startIndex = (_currentPage - 1) * _itemsPerPage;
        final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final List<Map<String, dynamic>> couponsOnCurrentPage =
        _filteredCoupons.sublist(startIndex, endIndex);

        final isMobile = constraints.maxWidth <= 850;
        final pagePadding = isMobile ? 16.0 : 32.0;

        return Scaffold(
          backgroundColor: isMobile ? Colors.grey[100] : Colors.grey[50],
          body: SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildFilterActions(),
                    const SizedBox(height: 24),
                    _buildCouponTable(couponsOnCurrentPage, constraints),
                    const SizedBox(height: 24),
                    if (totalItems > 0) _buildPagination(totalItems, totalPages),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Daftar Kupon',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildFilterActions() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 12.0,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari nama/kode kupon...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) => setState(() { _searchQuery = value; _currentPage = 1; }),
          ),
        ),
        _buildDropdownFilter(
          value: _selectedStatus,
          items: _statusOptions,
          onChanged: (newValue) => setState(() { _selectedStatus = newValue; _currentPage = 1; }),
        ),
        _buildDropdownFilter(
          value: _selectedOutlet,
          items: _outletOptions,
          onChanged: (newValue) => setState(() { _selectedOutlet = newValue; _currentPage = 1; }),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter({ required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      width: 200,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          // --- THIS IS THE CHANGE ---
          dropdownColor: Colors.white,
          // --- END OF CHANGE ---
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
            value: value, child: Text(value, style: const TextStyle(fontSize: 14)),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildCouponTable(List<Map<String, dynamic>> coupons, BoxConstraints constraints) {
    final bool isMobile = constraints.maxWidth <= 850;

    Widget content;
    if (coupons.isEmpty) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48.0),
          child: Text('Tidak ada kupon ditemukan.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    } else if (isMobile) {
      content = ListView.separated(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: coupons.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildMobileCouponCard(coupons[index]),
      );
    } else {
      content = Column(
        children: [
          _buildDesktopTableHeader(),
          const Divider(height: 1, color: Colors.grey),
          ...coupons.map((coupon) => _buildDesktopCouponTableRow(coupon)).toList(),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isMobile ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isMobile ? [] : [ BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10)],
      ),
      child: content,
    );
  }

  Widget _buildMobileCouponCard(Map<String, dynamic> coupon) {
    return Card(
      color: Colors.white,
      elevation: 2, shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon['nama'] ?? 'N/A', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Kode: ${coupon['kode'] ?? 'N/A'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                _buildPopupMenuButton(coupon),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.sell_outlined, 'Besaran: ${_formatBesaran(coupon)}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.date_range_outlined, _formatDurasi(coupon)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.storefront_outlined, coupon['outlet'] ?? 'N/A'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                _buildStatusChip(coupon['status'] ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
      ],
    );
  }

  Widget _buildDesktopTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (val) {}), const SizedBox(width: 8),
          Expanded(flex: 2, child: Text('KODE KUPON', style: _tableHeaderStyle())),
          Expanded(flex: 3, child: Text('NAMA KUPON', style: _tableHeaderStyle())),
          Expanded(flex: 2, child: Text('BESARAN', style: _tableHeaderStyle())),
          Expanded(flex: 4, child: Text('DURASI', style: _tableHeaderStyle())),
          Expanded(flex: 3, child: Text('OUTLET', style: _tableHeaderStyle())),
          Expanded(flex: 2, child: Text('STATUS', style: _tableHeaderStyle())),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDesktopCouponTableRow(Map<String, dynamic> coupon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(value: false, onChanged: (val) {}), const SizedBox(width: 8),
              Expanded(flex: 2, child: Text(coupon['kode'] ?? 'N/A', style: _tableBodyStyle())),
              Expanded(flex: 3, child: Text(coupon['nama'] ?? 'N/A', style: _tableBodyStyle())),
              Expanded(flex: 2, child: Text(_formatBesaran(coupon), style: _tableBodyStyle())),
              Expanded(flex: 4, child: Text(_formatDurasi(coupon), style: _tableBodyStyle())),
              Expanded(flex: 3, child: Text(coupon['outlet'] ?? 'N/A', style: _tableBodyStyle())),
              Expanded(flex: 2, child: _buildStatusChip(coupon['status'] ?? 'N/A')),
              _buildPopupMenuButton(coupon),
            ],
          ),
        ),
        const Divider(height: 1, indent: 24, endIndent: 24, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor = Colors.white;
    switch (status) {
      case 'Baru': chipColor = Colors.green; break;
      case 'Digunakan': chipColor = Colors.blue; break;
      case 'Kedaluwarsa': chipColor = Colors.red; break;
      default: chipColor = Colors.grey;
    }
    return Chip(
      label: Text(status, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      labelPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPopupMenuButton(Map<String, dynamic> coupon) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        icon: const Icon(Icons.more_horiz),
        onSelected: (String value) {
          if (value == 'hapus') {
            _showDeleteConfirmationDialog(context, coupon['nama']);
          }
        },
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
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.black54),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: isDestructive ? Colors.red : null)),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() => TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);
  TextStyle _tableBodyStyle() => const TextStyle(fontSize: 14, color: Colors.black87);

  Widget _buildPagination(int totalItems, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF279E9E), borderRadius: BorderRadius.circular(8)),
          child: Text('$_currentPage', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
      ],
    );
  }
}