import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'package:proyekpos2/crud/tambahkupon_page.dart';
import 'dart:math' as math;

class DaftarKuponPage extends StatefulWidget {
  final String outletId;

  const DaftarKuponPage({
    super.key,
    required this.outletId,
  });

  @override
  State<DaftarKuponPage> createState() => _DaftarKuponPageState();
}

class _DaftarKuponPageState extends State<DaftarKuponPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _horizontalScrollController = ScrollController();
  List<Map<String, dynamic>> _kuponList = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String? _selectedStatus = 'Semua Status';

  final List<String> _statusOptions = ['Semua Status', 'Aktif', 'Tidak Aktif'];

  int _currentPage = 1;
  int _itemsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final kupons = await _apiService.getKupon(outletId: widget.outletId);

      if (mounted) {
        setState(() {
          _kuponList = kupons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat data: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  String _formatBesaran(Map<String, dynamic> coupon) {
    String type = coupon['tipeNilai'] ?? '';
    num value = coupon['nilai'] ?? 0;
    if (type == 'percent') {
      return '$value%';
    }
    return _formatCurrency(value);
  }

  DateTime? _parseFirestoreDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is String) {
      return DateTime.tryParse(dateValue);
    }
    if (dateValue is Map) {
      final seconds = dateValue['_seconds'] ?? dateValue['seconds'];
      if (seconds != null) {
        final nanoseconds =
            dateValue['_nanoseconds'] ?? dateValue['nanoseconds'] ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          (seconds as int) * 1000 + (nanoseconds as int) ~/ 1000000,
        );
      }
    }
    return null;
  }

  String _formatDurasi(Map<String, dynamic> coupon) {
    try {
      final startDate = _parseFirestoreDate(coupon['tanggalMulai']);
      final endDate = _parseFirestoreDate(coupon['tanggalSelesai']);

      if (startDate == null || endDate == null) {
        return 'N/A';
      }

      final format = DateFormat('dd MMM yyyy', 'id_ID');
      return '${format.format(startDate)} - ${format.format(endDate)}';
    } catch (e) {
      return 'N/A';
    }
  }

  List<Map<String, dynamic>> get _filteredCoupons {
    List<Map<String, dynamic>> coupons = _kuponList;

    if (_searchQuery.isNotEmpty) {
      coupons = coupons.where((coupon) {
        final name = coupon['nama']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    if (_selectedStatus == 'Aktif') {
      coupons = coupons.where((coupon) => coupon['status'] == true).toList();
    } else if (_selectedStatus == 'Tidak Aktif') {
      coupons = coupons.where((coupon) => coupon['status'] == false).toList();
    }
    return coupons;
  }

  void _sortData(List<Map<String, dynamic>> items) {
    if (_sortColumnIndex == null) {
      return;
    }
    items.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      switch (_sortColumnIndex) {
        case 0:
          aValue = a['nama'] ?? '';
          bValue = b['nama'] ?? '';
          break;
        case 1:
          aValue = a['nilai'] ?? 0;
          bValue = b['nilai'] ?? 0;
          break;
        case 2:
          aValue = _parseFirestoreDate(a['tanggalMulai']);
          bValue = _parseFirestoreDate(b['tanggalMulai']);
          break;
        case 3:
          aValue = a['status'] ?? false;
          bValue = b['status'] ?? false;
          break;
        default:
          return 0;
      }
      int compare;
      if (aValue is num && bValue is num) {
        compare = aValue.compareTo(bValue);
      } else if (aValue is String && bValue is String) {
        compare = aValue.compareTo(bValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        compare = aValue.compareTo(bValue);
      } else if (aValue is bool && bValue is bool) {
        compare = (aValue ? 1 : 0).compareTo(bValue ? 1 : 0);
      } else {
        compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _navigateToAddKupon() {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahKuponPage(outletId: widget.outletId),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchData();
      }
    });
  }

  void _navigateToEditKupon(Map<String, dynamic> kupon) {
    Navigator.of(context, rootNavigator: true)
        .push(
      MaterialPageRoute(
        builder: (context) => TambahKuponPage(
          kupon: kupon,
          outletId: widget.outletId,
        ),
      ),
    )
        .then((success) {
      if (success == true) {
        _fetchData();
      }
    });
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, Map<String, dynamic> coupon) async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Konfirmasi Hapus'),
            content: Text(
                'Apakah Anda yakin ingin menghapus kupon "${coupon['nama']}"?'),
            actions: <Widget>[
              TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(dialogContext).pop()),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Hapus'),
                onPressed: () async {
                  try {
                    await _apiService.deleteKupon(coupon['id']);
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                          Text('Kupon "${coupon['nama']}" berhasil dihapus'),
                          backgroundColor: Colors.green),
                    );
                    _fetchData();
                  } catch (e) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Gagal menghapus kupon: $e'),
                          backgroundColor: Colors.red),
                    );
                  }
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
        final List<Map<String, dynamic>> coupons = _filteredCoupons;
        _sortData(coupons);

        final int totalItems = coupons.length;
        final int totalPages =
        (totalItems / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();

        if (_currentPage > totalPages && totalPages > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentPage = totalPages;
              });
            }
          });
          return const Center(child: CircularProgressIndicator());
        }

        final int startIndex = (_currentPage - 1) * _itemsPerPage;
        final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
        final List<Map<String, dynamic>> couponsOnCurrentPage =
        (totalItems > 0) ? coupons.sublist(startIndex, endIndex) : [];

        final isMobile = constraints.maxWidth <= 850;
        final pagePadding = isMobile ? 16.0 : 32.0;

        return Scaffold(
          backgroundColor: isMobile ? Colors.grey[100] : Colors.grey[50],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    const SizedBox(height: 24),
                    _buildFilterActions(),
                    const SizedBox(height: 24),
                    _buildCouponTable(
                        couponsOnCurrentPage, constraints),
                    const SizedBox(height: 24),
                    if (totalItems > 0)
                      _buildPagination(totalItems, totalPages),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title = const Text(
      'Daftar Kupon',
      style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
    );

    final button = ElevatedButton.icon(
      onPressed: _navigateToAddKupon,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Tambah Kupon', style: TextStyle(fontSize: 15)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF279E9E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: button),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          title,
          button,
        ],
      );
    }
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
              hintText: 'Cari nama kupon...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) => setState(() {
              _searchQuery = value;
              _currentPage = 1;
            }),
          ),
        ),
        _buildDropdownFilter(
          value: _selectedStatus,
          items: _statusOptions,
          onChanged: (newValue) => setState(() {
            _selectedStatus = newValue;
            _currentPage = 1;
          }),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(
      {required String? value,
        required List<String> items,
        required ValueChanged<String?> onChanged}) {
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
          dropdownColor: Colors.white,
          onChanged: onChanged,
          items: items
              .map<DropdownMenuItem<String>>((String value) =>
              DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 14)),
              ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCouponTable(
      List<Map<String, dynamic>> coupons, BoxConstraints constraints) {
    final bool isMobile = constraints.maxWidth <= 850;

    Widget content;

    if (isMobile) {
      if (coupons.isEmpty) {
        content = const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Text('Tidak ada kupon ditemukan.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        );
      } else {
        content = ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: coupons.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _buildMobileCouponCard(coupons[index]),
        );
      }
    } else {
      if (coupons.isEmpty) {
        content = const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text('Tidak ada kupon ditemukan.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        );
      } else {
        content = Scrollbar(
          thumbVisibility: true,
          controller: _horizontalScrollController,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 115.0,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingTextStyle: _tableHeaderStyle(),
              dataTextStyle: _tableBodyStyle(),
              columns: [
                DataColumn(label: const Text('NAMA KUPON'), onSort: _onSort),
                DataColumn(label: const Text('BESARAN'), onSort: _onSort),
                DataColumn(label: const Text('DURASI'), onSort: _onSort),
                DataColumn(label: const Text('STATUS'), onSort: _onSort),
                DataColumn(label: const Text('AKSI')),
              ],
              rows: coupons.map((coupon) {
                return DataRow(
                  cells: [
                    DataCell(Text(coupon['nama'] ?? 'N/A')),
                    DataCell(Text(_formatBesaran(coupon))),
                    DataCell(Text(_formatDurasi(coupon))),
                    DataCell(_buildStatusChip(coupon['status'] ?? false)),
                    DataCell(_buildPopupMenuButton(coupon)),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isMobile ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isMobile
            ? []
            : [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10)
        ],
      ),
      child: content,
    );
  }

  Widget _buildMobileCouponCard(Map<String, dynamic> coupon) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
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
                      Text(coupon['nama'] ?? 'N/A',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                _buildPopupMenuButton(coupon),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.sell_outlined, 'Besaran: ${_formatBesaran(coupon)}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.date_range_outlined, _formatDurasi(coupon)),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.storefront_outlined, coupon['outletName'] ?? 'N/A'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                _buildStatusChip(coupon['status'] ?? false),
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
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
      ],
    );
  }

  Widget _buildStatusChip(bool isActive) {
    Color chipColor = isActive ? Colors.green : Colors.red;
    String text = isActive ? 'Aktif' : 'Tidak Aktif';
    return Chip(
      label: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
        color: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        icon: const Icon(Icons.more_horiz),
        onSelected: (String value) {
          if (value == 'hapus') {
            _showDeleteConfirmationDialog(context, coupon);
          } else if (value == 'ubah') {
            _navigateToEditKupon(coupon);
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

  PopupMenuItem<String> _buildPopupMenuItem(
      {required String value,
        required String text,
        required IconData icon,
        bool isDestructive = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: isDestructive ? Colors.red : Colors.black54),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(color: isDestructive ? Colors.red : null)),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle() => TextStyle(
      fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]);
  TextStyle _tableBodyStyle() =>
      const TextStyle(fontSize: 14, color: Colors.black87);

  Widget _buildPagination(int totalItems, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('Tampilkan:', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _itemsPerPage,
                  onChanged: (int? newValue) {
                    setState(() {
                      _itemsPerPage = newValue!;
                      _currentPage = 1;
                    });
                  },
                  items: <int>[10, 20, 50, 100]
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Ditampilkan ${((_currentPage - 1) * _itemsPerPage + 1).clamp(1, totalItems)} - ${math.min(_currentPage * _itemsPerPage, totalItems)} dari $totalItems data',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFF279E9E),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('$_currentPage',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null),
          ],
        ),
      ],
    );
  }
}