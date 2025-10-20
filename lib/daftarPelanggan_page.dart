import 'package:flutter/material.dart';

class DaftarPelangganPage extends StatefulWidget {
  const DaftarPelangganPage({super.key});

  @override
  State<DaftarPelangganPage> createState() => _DaftarPelangganPageState();
}

class _DaftarPelangganPageState extends State<DaftarPelangganPage> {
  // Dummy data
  final List<Map<String, dynamic>> _dummyCustomers = [
    {
      "nama": "Ahmad Subarjo",
      "alamat": "Jl. Pahlawan No. 10, Surabaya, Jawa Timur",
      "notelp": "081234567890",
      "jenisKelamin": "Laki-laki",
    },
    {
      "nama": "Siti Aminah",
      "alamat": "Jl. Tunjungan No. 55, Surabaya, Jawa Timur",
      "notelp": "089876543210",
      "jenisKelamin": "Perempuan",
    },
    // Add more customers here for testing
  ];

  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  List<Map<String, dynamic>> get _filteredCustomers {
    List<Map<String, dynamic>> customers = _dummyCustomers;
    if (_searchQuery.isNotEmpty) {
      customers = customers.where((customer) {
        final name = (customer['nama'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query);
      }).toList();
    }
    return customers;
  }

  void _navigateToAddCustomer() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Navigasi'),
        content: Text('Akan bernavigasi ke halaman "Tambah Pelanggan".'),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String customerName) async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Konfirmasi Hapus'),
            content: Text('Apakah Anda yakin ingin menghapus pelanggan "$customerName"?'),
            actions: <Widget>[
              TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Hapus'),
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pelanggan "$customerName" berhasil dihapus'), backgroundColor: Colors.green),
                  );
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth <= 800;
          final totalItems = _filteredCustomers.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();
          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
          final customersOnCurrentPage = _filteredCustomers.sublist(startIndex, endIndex);

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 24),
                _buildFilterActions(),
                const SizedBox(height: 24),
                isMobile
                    ? _buildMobileCustomerList(customersOnCurrentPage)
                    : _buildDesktopCustomerTable(customersOnCurrentPage),
                const SizedBox(height: 24),
                _buildPagination(totalItems, totalPages),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daftar Pelanggan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToAddCustomer,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Tambah Pelanggan'),
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
        const Text('Daftar Pelanggan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _navigateToAddCustomer,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Tambah Pelanggan', style: TextStyle(fontSize: 15)),
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

  Widget _buildFilterActions() {
    return SizedBox(
      width: 280, // Set a fixed width for mobile consistency
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari pelanggan...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildDesktopCustomerTable(List<Map<String, dynamic>> customers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildDesktopTableHeader(),
          const Divider(height: 1, color: Colors.grey),
          if (customers.isEmpty)
            const Padding(padding: EdgeInsets.all(24.0), child: Text('Tidak ada pelanggan ditemukan.'))
          else
            ...customers.map((customer) => _buildDesktopCustomerTableRow(customer)).toList(),
        ],
      ),
    );
  }

  Widget _buildMobileCustomerList(List<Map<String, dynamic>> customers) {
    if (customers.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: Text('Tidak ada pelanggan ditemukan.')));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // --- FIX 1: itemCount is added ---
      itemCount: customers.length,
      // --- FIX 2: separatorBuilder is added ---
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildMobileCustomerCard(customer);
      },
    );
  }

  Widget _buildMobileCustomerCard(Map<String, dynamic> customer) {
    return Card(
      elevation: 0,
      color: Colors.white,
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
                  child: Text(customer['nama'] ?? 'N/A', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildPopupMenuButton(customer),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on_outlined, customer['alamat'] ?? 'N/A'),
            _buildInfoRow(Icons.phone_outlined, customer['notelp'] ?? 'N/A'),
            _buildInfoRow(Icons.person_outline, customer['jenisKelamin'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
        ],
      ),
    );
  }

  Widget _buildDesktopTableHeader() {
    TextStyle headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(children: [
        Checkbox(value: false, onChanged: (val) {}),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Text('NAMA PELANGGAN', style: headerStyle)),
        Expanded(flex: 4, child: Text('ALAMAT', style: headerStyle)),
        Expanded(flex: 2, child: Text('NO. TELEPON', style: headerStyle)),
        Expanded(flex: 2, child: Text('JENIS KELAMIN', style: headerStyle)),
        const SizedBox(width: 48),
      ]),
    );
  }

  Widget _buildDesktopCustomerTableRow(Map<String, dynamic> customer) {
    TextStyle cellStyle = const TextStyle(fontSize: 14, color: Colors.black87);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Checkbox(value: false, onChanged: (val) {}),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(customer['nama'] ?? 'N/A', style: cellStyle)),
          Expanded(flex: 4, child: Text(customer['alamat'] ?? 'N/A', style: cellStyle)),
          Expanded(flex: 2, child: Text(customer['notelp'] ?? 'N/A', style: cellStyle)),
          Expanded(flex: 2, child: Text(customer['jenisKelamin'] ?? 'N/A', style: cellStyle)),
          _buildPopupMenuButton(customer),
        ]),
      ),
      const Divider(height: 1, indent: 24, endIndent: 24, color: Color(0xFFEEEEEE)),
    ]);
  }

  Widget _buildPopupMenuButton(Map<String, dynamic> customer) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        icon: const Icon(Icons.more_horiz),
        onSelected: (String value) {
          if (value == 'hapus') _showDeleteConfirmationDialog(context, customer['nama']);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          _buildPopupMenuItem(value: 'ubah', text: 'Ubah', icon: Icons.edit_outlined),
          _buildPopupMenuItem(value: 'lihat_transaksi', text: 'Lihat Daftar Transaksi Pelanggan', icon: Icons.receipt_long_outlined),
          _buildPopupMenuItem(value: 'lihat_detail', text: 'Lihat Detail Pelanggan', icon: Icons.person_search_outlined),
          const PopupMenuDivider(),
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

  Widget _buildPagination(int totalItems, int totalPages) {
    if (totalItems == 0) return const SizedBox.shrink();
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFF279E9E), borderRadius: BorderRadius.circular(8)),
        child: Text('$_currentPage', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
    ]);
  }
}