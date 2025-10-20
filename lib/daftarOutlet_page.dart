import 'package:flutter/material.dart';

class DaftarOutletPage extends StatefulWidget {
  const DaftarOutletPage({super.key});

  @override
  State<DaftarOutletPage> createState() => _DaftarOutletPageState();
}

class _DaftarOutletPageState extends State<DaftarOutletPage> {
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  final List<Map<String, dynamic>> _allOutlets = [
    {
      "nama": "Kashierku Pusat",
      "alamat": "Jl. Merdeka No. 1, Jakarta Pusat",
      "kota": "Jakarta",
      "owner": "Budi Santoso"
    },
    {
      "nama": "Kashierku Cabang Surabaya",
      "alamat": "Jl. Pahlawan No. 10, Surabaya",
      "kota": "Surabaya",
      "owner": "Citra Dewi"
    },
  ];

  List<Map<String, dynamic>> get _filteredOutlets {
    List<Map<String, dynamic>> outlets = _allOutlets;
    if (_searchQuery.isNotEmpty) {
      outlets = outlets.where((outlet) {
        final name = (outlet['nama'] as String? ?? '').toLowerCase();
        final address = (outlet['alamat'] as String? ?? '').toLowerCase();
        final city = (outlet['kota'] as String? ?? '').toLowerCase();
        final owner = (outlet['owner'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            address.contains(query) ||
            city.contains(query) ||
            owner.contains(query);
      }).toList();
    }
    return outlets;
  }

  void _navigateToAddOutlet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke halaman Tambah Outlet...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _filteredOutlets.length;
    final totalPages = (_filteredOutlets.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final outletsOnCurrentPage = _filteredOutlets.sublist(startIndex, endIndex);

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
                        ? _buildMobileOutletList(outletsOnCurrentPage)
                        : _buildDesktopOutletTable(outletsOnCurrentPage),
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

  Widget _buildHeader(bool isMobile) {
    return isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daftar Outlet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToAddOutlet,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Tambah Outlet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF279E9E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Daftar Outlet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _navigateToAddOutlet,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Tambah Outlet'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: 280, // Same width as the customer list search bar
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari outlet...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildDesktopOutletTable(List<Map<String, dynamic>> outlets) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: [
          _buildDesktopTableHeader(),
          const Divider(height: 1, color: Colors.grey),
          if (outlets.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text('Tidak ada outlet ditemukan.'))
          else
            ...outlets.map((outlet) => _buildTableRow(outlet)).toList(),
        ],
      ),
    );
  }

  Widget _buildDesktopTableHeader() {
    TextStyle headerStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(children: [
        Checkbox(value: false, onChanged: (val) {}),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Text('NAMA', style: headerStyle)),
        Expanded(flex: 4, child: Text('ALAMAT', style: headerStyle)),
        Expanded(flex: 2, child: Text('KOTA', style: headerStyle)),
        Expanded(flex: 2, child: Text('OWNER', style: headerStyle)),
        const SizedBox(width: 48), // For the menu button
      ]),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> outlet) {
    TextStyle cellStyle = const TextStyle(fontSize: 14, color: Colors.black87);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Checkbox(value: false, onChanged: (val) {}),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Text(outlet['nama'] ?? 'N/A', style: cellStyle)),
        Expanded(
            flex: 4, child: Text(outlet['alamat'] ?? 'N/A', style: cellStyle)),
        Expanded(flex: 2, child: Text(outlet['kota'] ?? 'N/A', style: cellStyle)),
        Expanded(flex: 2, child: Text(outlet['owner'] ?? 'N/A', style: cellStyle)),
        _buildPopupMenuButton(outlet),
      ]),
    );
  }

  Widget _buildMobileOutletList(List<Map<String, dynamic>> outlets) {
    if (outlets.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: Text('Tidak ada outlet ditemukan.')));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: outlets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _buildMobileCard(outlets[index]),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> outlet) {
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
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(outlet['nama'] ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Owner: ${outlet['owner'] ?? 'N/A'}',
                              style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ]),
                  ),
                  _buildPopupMenuButton(outlet),
                ]),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on_outlined, 'Alamat', outlet['alamat'] ?? 'N/A'),
            _buildInfoRow(Icons.location_city_outlined, 'Kota', outlet['kota'] ?? 'N/A'),
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
        Text('$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ]),
    );
  }

  Widget _buildPopupMenuButton(Map<String, dynamic> outlet) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        icon: const Icon(Icons.more_horiz, color: Colors.grey),
        onSelected: (String value) {
          // Handle menu actions here
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          _buildPopupMenuItem(value: 'ubah', text: 'Ubah', icon: Icons.edit_outlined),
          _buildPopupMenuItem(value: 'hapus', text: 'Hapus', icon: Icons.delete_outline, isDestructive: true),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required String text,
    required IconData icon,
    bool isDestructive = false,
  }) {
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
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: const Color(0xFF279E9E),
            borderRadius: BorderRadius.circular(8)),
        child: Text('$_currentPage',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward_ios, size: 16),
        onPressed:
        _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
        color: _currentPage < totalPages ? Colors.black87 : Colors.grey,
      ),
    ]);
  }
}