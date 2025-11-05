import 'package:flutter/material.dart';
import 'package:proyekpos2/crud/tambahKaryawan_page.dart';
import 'package:proyekpos2/service/api_service.dart';

class DaftarKaryawanPage extends StatefulWidget {
  final String outletId;

  const DaftarKaryawanPage({
    super.key,
    required this.outletId,
  });
  @override
  State<DaftarKaryawanPage> createState() => _DaftarKaryawanPageState();
}

class _DaftarKaryawanPageState extends State<DaftarKaryawanPage> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _allKaryawan = [];
  bool _isLoading = true;
  String? _error;
  String _activeOutletName = "Outlet";

  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchKaryawan();
  }

  Future<void> _fetchKaryawan() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final karyawanList = await _apiService.getKaryawan(outletId: widget.outletId);

      if (karyawanList.isNotEmpty) {
        _activeOutletName = karyawanList.first['outlet'] ?? 'Outlet';
      }

      if (mounted) {
        setState(() {
          _allKaryawan = karyawanList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredKaryawan {
    List<Map<String, dynamic>> karyawanList = _allKaryawan;

    if (_searchQuery.isNotEmpty) {
      karyawanList = karyawanList.where((karyawan) {
        final name = (karyawan['nama'] as String? ?? '').toLowerCase();
        final nip = (karyawan['nip'] as String? ?? '').toLowerCase();
        final email = (karyawan['email'] as String? ?? '').toLowerCase();
        final phone = (karyawan['notelp'] as String? ?? '').toLowerCase();
        final status = (karyawan['status'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            nip.contains(query) ||
            email.contains(query) ||
            phone.contains(query) ||
            status.contains(query);
      }).toList();
    }
    return karyawanList;
  }

  void _navigateToAddKaryawan() {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahKaryawanPage(
          outletId: widget.outletId,
          outletName: _activeOutletName,
        ),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchKaryawan();
      }
    });
  }

  void _navigateToEditKaryawan(Map<String, dynamic> karyawan) {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahKaryawanPage(
          karyawan: karyawan,
          outletId: widget.outletId,
          outletName: _activeOutletName,
        ),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchKaryawan();
      }
    });
  }

  Future<void> _handleDelete(String id, String name) async {
    try {
      await _apiService.deleteKaryawan(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Karyawan "$name" berhasil dihapus'),
              backgroundColor: Colors.green),
        );
        _fetchKaryawan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String name, String id) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus "$name"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleDelete(id, name);
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredKaryawan;
    final totalItems = filteredList.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final karyawanOnCurrentPage =
    filteredList.sublist(startIndex, endIndex);

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
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Text('Gagal memuat data: $_error',
                              style: const TextStyle(color: Colors.red)),
                        ),
                      )
                    else
                      isMobile
                          ? _buildMobileKaryawanList(karyawanOnCurrentPage)
                          : _buildDesktopKaryawanTable(karyawanOnCurrentPage),
                    if (!_isLoading && _error == null && totalItems > 0) ...[
                      const Divider(height: 32),
                      _buildPaginationFooter(
                          totalItems, totalPages, startIndex, endIndex),
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
        const Text('Daftar Karyawan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToAddKaryawan,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Tambah Karyawan'),
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
        const Text('Daftar Karyawan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _navigateToAddKaryawan,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Tambah Karyawan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari karyawan...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) => setState(() {
          _searchQuery = value;
          _currentPage = 1;
        }),
      ),
    );
  }

  Widget _buildDesktopKaryawanTable(List<Map<String, dynamic>> karyawanList) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: [
          _buildDesktopTableHeader(),
          const Divider(height: 1, color: Colors.grey),
          if (karyawanList.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text('Tidak ada karyawan ditemukan.'))
          else
            ...karyawanList
                .map((karyawan) => _buildTableRow(karyawan))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildDesktopTableHeader() {
    TextStyle headerStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(children: [
        Expanded(flex: 3, child: Text('NAMA', style: headerStyle)),
        Expanded(flex: 2, child: Text('NIP', style: headerStyle)),
        Expanded(flex: 3, child: Text('EMAIL', style: headerStyle)),
        Expanded(flex: 2, child: Text('NOTELP', style: headerStyle)),
        Expanded(flex: 2, child: Text('OUTLET', style: headerStyle)),
        Expanded(flex: 1, child: Text('STATUS', style: headerStyle)),
        const SizedBox(width: 48),
      ]),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> karyawan) {
    TextStyle cellStyle = const TextStyle(fontSize: 14, color: Colors.black87);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            flex: 3, child: Text(karyawan['nama'] ?? 'N/A', style: cellStyle)),
        Expanded(
            flex: 2, child: Text(karyawan['nip'] ?? 'N/A', style: cellStyle)),
        Expanded(
            flex: 3, child: Text(karyawan['email'] ?? 'N/A', style: cellStyle)),
        Expanded(
            flex: 2, child: Text(karyawan['notelp'] ?? 'N/A', style: cellStyle)),
        Expanded(
            flex: 2, child: Text(karyawan['outlet'] ?? 'N/A', style: cellStyle)),
        Expanded(flex: 1, child: _buildStatusWidget(karyawan['status'])),
        _buildPopupMenuButton(karyawan),
      ]),
    );
  }

  Widget _buildMobileKaryawanList(List<Map<String, dynamic>> karyawanList) {
    if (karyawanList.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: Text('Tidak ada karyawan ditemukan.')));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: karyawanList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _buildMobileCard(karyawanList[index]),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> karyawan) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withAlpha(20),
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
                          Text(karyawan['nama'] ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('NIP: ${karyawan['nip'] ?? 'N/A'}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600])),
                        ]),
                  ),
                  _buildPopupMenuButton(karyawan),
                ]),
            const Divider(height: 24),
            _buildInfoRow(Icons.email_outlined, 'Email',
                text: karyawan['email'] ?? 'N/A'),
            _buildInfoRow(Icons.phone_outlined, 'Notelp',
                text: karyawan['notelp'] ?? 'N/A'),
            _buildInfoRow(Icons.store_outlined, 'Outlet',
                text: karyawan['outlet'] ?? 'N/A'),
            _buildInfoRow(Icons.toggle_on_outlined, 'Status',
                valueWidget: _buildStatusWidget(karyawan['status'])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget(String? status) {
    final bool isActive = status == 'Aktif';
    final Color bgColor = isActive ? Colors.green.shade50 : Colors.red.shade50;
    final Color borderColor =
    isActive ? Colors.green.shade100 : Colors.red.shade100;
    final Color textColor =
    isActive ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor)),
      child: Text(
        status ?? 'N/A',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label,
      {String? text, Widget? valueWidget}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.black54)),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(
                    text ?? 'N/A',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.end,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenuButton(Map<String, dynamic> karyawan) {
    return SizedBox(
      width: 48,
      child: PopupMenuButton<String>(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        icon: const Icon(Icons.more_horiz, color: Colors.grey),
        onSelected: (String value) {
          if (value == 'ubah') {
            _navigateToEditKaryawan(karyawan);
          } else if (value == 'hapus') {
            _showDeleteConfirmationDialog(context, karyawan['nama'], karyawan['id']);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          _buildPopupMenuItem(
              value: 'ubah', text: 'Ubah', icon: Icons.edit_outlined),
          _buildPopupMenuItem(
              value: 'hapus',
              text: 'Hapus',
              icon: Icons.delete_outline,
              isDestructive: true),
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

  Widget _buildPaginationFooter(
      int totalItems, int totalPages, int startIndex, int endIndex) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(
        'Ditampilkan ${totalItems == 0 ? 0 : startIndex + 1} - $endIndex dari $totalItems data',
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      const Spacer(),
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
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
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