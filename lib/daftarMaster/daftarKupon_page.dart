import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'package:proyekpos2/crud/tambahKupon_page.dart';
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

  final List<String> _statusOptions = ['Semua Status', 'Aktif', 'Tidak Aktif', 'Kadaluarsa'];

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

  String _getCouponStatus(Map<String, dynamic> coupon) {
    final endDate = _parseFirestoreDate(coupon['tanggalSelesai']);
    final bool isActive = coupon['status'] ?? false;

    if (endDate != null && DateTime.now().isAfter(endDate)) {
      return 'expired';
    }

    return isActive ? 'active' : 'inactive';
  }

  List<Map<String, dynamic>> get _filteredCoupons {
    List<Map<String, dynamic>> coupons = _kuponList;

    if (_searchQuery.isNotEmpty) {
      coupons = coupons.where((coupon) {
        final name = coupon['nama']?.toLowerCase() ?? '';
        final code = coupon['kodeKupon']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || code.contains(query);
      }).toList();
    }

    if (_selectedStatus == 'Aktif') {
      coupons = coupons.where((coupon) => _getCouponStatus(coupon) == 'active').toList();
    } else if (_selectedStatus == 'Tidak Aktif') {
      coupons = coupons.where((coupon) => _getCouponStatus(coupon) == 'inactive').toList();
    } else if (_selectedStatus == 'Kadaluarsa') {
      coupons = coupons.where((coupon) => _getCouponStatus(coupon) == 'expired').toList();
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
          aValue = a['kodeKupon'] ?? '';
          bValue = b['kodeKupon'] ?? '';
          break;
        case 2:
          aValue = a['nilai'] ?? 0;
          bValue = b['nilai'] ?? 0;
          break;
        case 3:
          aValue = _parseFirestoreDate(a['tanggalMulai']);
          bValue = _parseFirestoreDate(b['tanggalMulai']);
          break;
        case 4:
          aValue = _getCouponStatus(a);
          bValue = _getCouponStatus(b);
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

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
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
                    _buildCouponTable(couponsOnCurrentPage),
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

  Widget _buildHeader() {
    final title = const Text(
      'Daftar Kupon',
      style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
    );

    final button = ElevatedButton.icon(
      onPressed: _navigateToAddKupon,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Tambah Kupon', style: TextStyle(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF279E9E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        title,
        const Spacer(),
        button,
      ],
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
              hintText: 'Cari nama atau kode kupon...',
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

  Widget _buildCouponTable(List<Map<String, dynamic>> coupons) {
    Widget content;

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
            columnSpacing: 100.0,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            headingTextStyle: _tableHeaderStyle(),
            dataTextStyle: _tableBodyStyle(),
            columns: [
              DataColumn(label: const Text('NAMA KUPON'), onSort: _onSort),
              DataColumn(label: const Text('KODE KUPON'), onSort: _onSort),
              DataColumn(label: const Text('BESARAN'), onSort: _onSort),
              DataColumn(label: const Text('MASA BERLAKU'), onSort: _onSort),
              DataColumn(label: const Text('STATUS'), onSort: _onSort),
              DataColumn(label: const Text('AKSI')),
            ],
            rows: coupons.map((coupon) {
              return DataRow(
                cells: [
                  DataCell(Text(coupon['nama'] ?? 'N/A')),
                  DataCell(Text(coupon['kodeKupon'] ?? '-')),
                  DataCell(Text(_formatBesaran(coupon))),
                  DataCell(Text(_formatDurasi(coupon))),
                  DataCell(_buildStatusChip(_getCouponStatus(coupon))),
                  DataCell(_buildPopupMenuButton(coupon)),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10)
        ],
      ),
      child: content,
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String text;

    switch (status) {
      case 'active':
        chipColor = Colors.green;
        text = 'Aktif';
        break;
      case 'inactive':
        chipColor = Colors.orange;
        text = 'Tidak Aktif';
        break;
      case 'expired':
        chipColor = Colors.red;
        text = 'Kadaluarsa';
        break;
      default:
        chipColor = Colors.grey;
        text = 'Unknown';
    }

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
    if (totalItems == 0) return const SizedBox.shrink();

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final int startItem = ((_currentPage - 1) * _itemsPerPage + 1).clamp(1, totalItems);
    final int endItem = math.min(_currentPage * _itemsPerPage, totalItems);

    if (isMobile) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tampilkan:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      dropdownColor: Colors.white,
                      value: _itemsPerPage,
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      onChanged: (int? newValue) {
                        setState(() {
                          _itemsPerPage = newValue!;
                          _currentPage = 1;
                        });
                      },
                      items: <int>[10, 20, 50]
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ditampilkan $startItem - $endItem dari $totalItems data',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: _currentPage > 1 ? const Color(0xFF279E9E) : Colors.grey[400],
                ),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF279E9E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _currentPage < totalPages ? const Color(0xFF279E9E) : Colors.grey[400],
                ),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
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
                    dropdownColor: Colors.white,
                    value: _itemsPerPage,
                    onChanged: (int? newValue) {
                      setState(() {
                        _itemsPerPage = newValue!;
                        _currentPage = 1;
                      });
                    },
                    items: <int>[10, 20, 50]
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
                'Ditampilkan $startItem - $endItem dari $totalItems data',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed:
              _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
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
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}