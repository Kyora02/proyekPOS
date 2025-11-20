import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class DaftarAbsensiPage extends StatefulWidget {
  final String outletId;

  const DaftarAbsensiPage({
    super.key,
    required this.outletId,
  });

  @override
  State<DaftarAbsensiPage> createState() => _DaftarAbsensiPageState();
}

class _DaftarAbsensiPageState extends State<DaftarAbsensiPage> {
  final ScrollController _horizontalScrollController = ScrollController();

  // Dummy data for UI visualization
  final List<Map<String, dynamic>> _allAbsensi = [
    {
      'id': '1',
      'name': 'Darren',
      'date': DateTime.now(),
      'clockIn': DateTime.now().subtract(const Duration(hours: 8)),
      'clockOut': DateTime.now(),
      'status': 'Hadir',
    },
    {
      'id': '2',
      'name': 'Budi',
      'date': DateTime.now(),
      'clockIn': DateTime.now().subtract(const Duration(hours: 9)),
      'clockOut': null,
      'status': 'Bekerja',
    },
    {
      'id': '3',
      'name': 'Siti',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'clockIn': DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      'clockOut': DateTime.now().subtract(const Duration(days: 1, hours: 0)),
      'status': 'Telat',
    },
  ];

  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredAbsensi {
    List<Map<String, dynamic>> items = _allAbsensi;
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final name = item['name']?.toLowerCase() ?? '';
        final status = item['status']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || status.contains(query);
      }).toList();
    }
    return items;
  }

  void _sortData(List<Map<String, dynamic>> items) {
    if (_sortColumnIndex == null) return;
    items.sort((a, b) {
      dynamic aValue = a.values.elementAt(_sortColumnIndex!);
      dynamic bValue = b.values.elementAt(_sortColumnIndex!);

      if (aValue is String && bValue is String) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      return 0;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = _filteredAbsensi;
    _sortData(items);
    final int totalItems = items.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final List<Map<String, dynamic>> itemsOnCurrentPage =
    items.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
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
                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
                      else if (_error != null)
                        Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                      else
                        _buildTable(itemsOnCurrentPage),
                      const SizedBox(height: 24),
                      _buildPagination(totalItems, totalPages),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final title = const Text(
      'Daftar Absensi',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
    );

    final button = ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Absen Manual', style: TextStyle(fontSize: 15)),
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
        children: [title, const SizedBox(height: 16), SizedBox(width: double.infinity, child: button)],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [title, button],
      );
    }
  }

  Widget _buildFilterActions() {
    return SizedBox(
      width: 250,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari absensi...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) => setState(() {
          _searchQuery = value;
          _currentPage = 1;
        }),
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
        child: const Center(child: Text('Tidak ada data absensi.')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10)],
      ),
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalScrollController,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 80.0,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            dataTextStyle: const TextStyle(fontSize: 14, color: Colors.black87),
            columns: [
              DataColumn(label: const Text('NAMA'), onSort: _onSort),
              DataColumn(label: const Text('TANGGAL'), onSort: _onSort),
              DataColumn(label: const Text('JAM MASUK'), onSort: _onSort),
              DataColumn(label: const Text('JAM KELUAR'), onSort: _onSort),
              DataColumn(label: const Text('STATUS'), onSort: _onSort),
              const DataColumn(label: Text('AKSI')),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item['name'])),
                  DataCell(Text(DateFormat('dd MMM yyyy').format(item['date']))),
                  DataCell(Text(DateFormat('HH:mm').format(item['clockIn']))),
                  DataCell(Text(item['clockOut'] != null ? DateFormat('HH:mm').format(item['clockOut']) : '-')),
                  DataCell(_buildStatusChip(item['status'])),
                  DataCell(
                    PopupMenuButton<String>(
                      color: Colors.white,
                      icon: const Icon(Icons.more_horiz),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.info_outline, size: 20, color: Colors.black54), SizedBox(width: 8), Text('Detail')])),
                        const PopupMenuItem(value: 'hapus', child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'hadir':
        bgColor = Colors.green.shade50;
        textColor = Colors.green;
        break;
      case 'telat':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange;
        break;
      case 'bekerja':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPagination(int totalItems, int totalPages) {
    if (totalItems == 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('Tampilkan:', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _itemsPerPage,
                  items: [10, 20, 50].map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                  onChanged: (val) => setState(() { _itemsPerPage = val!; _currentPage = 1; }),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text('Ditampilkan ${((_currentPage - 1) * _itemsPerPage + 1).clamp(1, totalItems)} - ${math.min(_currentPage * _itemsPerPage, totalItems)} dari $totalItems data', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF279E9E), borderRadius: BorderRadius.circular(8)),
              child: Text('$_currentPage', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
          ],
        ),
      ],
    );
  }
}