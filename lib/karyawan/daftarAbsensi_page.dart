import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:proyekpos2/service/api_service.dart';

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
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _allAbsensi = [];
  List<Map<String, dynamic>> _karyawanList = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final absensiData = await _apiService.getAbsensi(
          outletId: widget.outletId);
      final karyawanData = await _apiService.getKaryawan(
          outletId: widget.outletId);

      setState(() {
        _allAbsensi = absensiData;
        _karyawanList = karyawanData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAbsensi {
    List<Map<String, dynamic>> items = _allAbsensi;
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final name = item['karyawanName']?.toLowerCase() ?? '';
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
      dynamic aValue;
      dynamic bValue;

      switch (_sortColumnIndex) {
        case 0:
          aValue = a['karyawanName'] ?? '';
          bValue = b['karyawanName'] ?? '';
          break;
        case 1:
          aValue = a['date'] ?? '';
          bValue = b['date'] ?? '';
          break;
        case 2:
          aValue = a['jamMasuk'] ?? '';
          bValue = b['jamMasuk'] ?? '';
          break;
        case 3:
          aValue = a['jamKeluar'] ?? '';
          bValue = b['jamKeluar'] ?? '';
          break;
        case 4:
          aValue = a['status'] ?? '';
          bValue = b['status'] ?? '';
          break;
        default:
          return 0;
      }

      if (aValue is String && bValue is String) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(
            aValue);
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

  String _getStatusFromData(Map<String, dynamic> item) {
    final status = item['status'] ?? 'Bekerja';
    final totalJamKerja = item['totalJamKerja'];

    if (totalJamKerja == null) {
      return status;
    }

    final jamMasukStr = item['jamMasuk'];
    if (jamMasukStr != null) {
      final jamMasuk = DateTime.parse(jamMasukStr);
      final standardJamMasuk = DateTime(
          jamMasuk.year, jamMasuk.month, jamMasuk.day, 8, 0);

      if (jamMasuk.isAfter(standardJamMasuk.add(const Duration(minutes: 15)))) {
        return 'Telat';
      }
    }

    if (totalJamKerja > 8) {
      return 'Lembur';
    } else if (totalJamKerja < 8 && item['jamKeluar'] != null) {
      return 'Pulang Awal';
    }

    return status;
  }

  Future<void> _showManualAbsensiDialog() async {
    String? selectedKaryawanId;
    String? selectedKaryawanName;
    DateTime selectedDate = DateTime.now();
    TimeOfDay jamMasuk = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay? jamKeluar;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setDialogState) =>
                AlertDialog(
                  title: const Text('Absen Manual'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Karyawan',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedKaryawanId,
                          items: _karyawanList.map<DropdownMenuItem<String>>((
                              k) {
                            return DropdownMenuItem<String>(
                              value: k['id'].toString(),
                              child: Text(k['nama']?.toString() ?? ''),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedKaryawanId = val;
                              selectedKaryawanName =
                              _karyawanList.firstWhere((k) => k['id']
                                  .toString() == val)['nama'];
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Tanggal'),
                          subtitle: Text(
                              DateFormat('dd MMM yyyy').format(selectedDate)),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Jam Masuk'),
                          subtitle: Text(jamMasuk.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: jamMasuk,
                            );
                            if (picked != null) {
                              setDialogState(() => jamMasuk = picked);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Jam Keluar (Opsional)'),
                          subtitle: Text(
                              jamKeluar?.format(context) ?? 'Belum diisi'),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: jamKeluar ??
                                  const TimeOfDay(hour: 17, minute: 0),
                            );
                            if (picked != null) {
                              setDialogState(() => jamKeluar = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: selectedKaryawanId == null
                          ? null
                          : () => Navigator.pop(context, true),
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
          ),
    );

    if (result == true && selectedKaryawanId != null) {
      try {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
        final jamMasukStr = '${jamMasuk.hour.toString().padLeft(
            2, '0')}:${jamMasuk.minute.toString().padLeft(2, '0')}';
        final jamKeluarStr = jamKeluar != null
            ? '${jamKeluar!.hour.toString().padLeft(2, '0')}:${jamKeluar!.minute
            .toString().padLeft(2, '0')}'
            : null;

        await _apiService.createManualAbsensi(
          karyawanId: selectedKaryawanId!,
          karyawanName: selectedKaryawanName!,
          outletId: widget.outletId,
          date: dateStr,
          jamMasuk: jamMasukStr,
          jamKeluar: jamKeluarStr,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Absen manual berhasil dibuat')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDetailDialog(Map<String, dynamic> item) async {
    final jamMasuk = item['jamMasuk'] != null
        ? DateTime.parse(item['jamMasuk'])
        : null;
    final jamKeluar = item['jamKeluar'] != null ? DateTime.parse(
        item['jamKeluar']) : null;
    final totalJamKerja = item['totalJamKerja'];

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(item['karyawanName'] ?? ''),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Tanggal', item['date'] ?? '-'),
                _buildDetailRow('Jam Masuk', jamMasuk != null
                    ? DateFormat('HH:mm').format(jamMasuk)
                    : '-'),
                _buildDetailRow('Jam Keluar', jamKeluar != null
                    ? DateFormat('HH:mm').format(jamKeluar)
                    : '-'),
                _buildDetailRow('Total Jam Kerja',
                    totalJamKerja != null ? '$totalJamKerja jam' : '-'),
                _buildDetailRow('Status', _getStatusFromData(item)),
                if (item['isManual'] == true)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Chip(
                      label: Text('Manual Entry'),
                      backgroundColor: Colors.orange,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _deleteAbsensi(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text(
                'Apakah Anda yakin ingin menghapus absensi ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteAbsensi(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Absensi berhasil dihapus')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
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
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(48),
                                child: CircularProgressIndicator()))
                      else
                        if (_error != null)
                          Center(
                              child: Column(
                                children: [
                                  Text('Error: $_error',
                                      style: const TextStyle(
                                          color: Colors.red)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadData,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ))
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Daftar Absensi',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(width: 8),
        isMobile
            ? IconButton(
          onPressed: _showManualAbsensiDialog,
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
        )
            : ElevatedButton.icon(
          onPressed: _showManualAbsensiDialog,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Absen Manual', style: TextStyle(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterActions() {
    return SizedBox(
      width: 250,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari absensi...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) =>
            setState(() {
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
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!)),
        child: const Center(child: Text('Tidak ada data absensi.')),
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
            headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            dataTextStyle:
            const TextStyle(fontSize: 14, color: Colors.black87),
            columns: [
              DataColumn(label: const Text('NAMA'), onSort: _onSort),
              DataColumn(label: const Text('TANGGAL'), onSort: _onSort),
              DataColumn(label: const Text('JAM MASUK'), onSort: _onSort),
              DataColumn(label: const Text('JAM KELUAR'), onSort: _onSort),
              DataColumn(label: const Text('STATUS'), onSort: _onSort),
              const DataColumn(label: Text('AKSI')),
            ],
            rows: items.map((item) {
              final jamMasuk = item['jamMasuk'] != null
                  ? DateTime.parse(item['jamMasuk'])
                  : null;
              final jamKeluar = item['jamKeluar'] != null
                  ? DateTime.parse(item['jamKeluar'])
                  : null;
              final status = _getStatusFromData(item);

              return DataRow(
                cells: [
                  DataCell(Text(item['karyawanName'] ?? '-')),
                  DataCell(Text(item['date'] ?? '-')),
                  DataCell(Text(jamMasuk != null
                      ? DateFormat('HH:mm').format(jamMasuk)
                      : '-')),
                  DataCell(Text(jamKeluar != null
                      ? DateFormat('HH:mm').format(jamKeluar)
                      : '-')),
                  DataCell(_buildStatusChip(status)),
                  DataCell(
                    PopupMenuButton<String>(
                      color: Colors.white,
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (value) {
                        if (value == 'detail') {
                          _showDetailDialog(item);
                        } else if (value == 'hapus') {
                          _deleteAbsensi(item['id']);
                        }
                      },
                      itemBuilder: (context) =>
                      [
                        const PopupMenuItem(
                            value: 'detail',
                            child: Row(children: [
                              Icon(Icons.info_outline,
                                  size: 20, color: Colors.black54),
                              SizedBox(width: 8),
                              Text('Detail')
                            ])),
                        const PopupMenuItem(
                            value: 'hapus',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus',
                                  style: TextStyle(color: Colors.red))
                            ])),
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
      case 'lembur':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple;
        break;
      case 'pulang awal':
        bgColor = Colors.red.shade50;
        textColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPagination(int totalItems, int totalPages) {
    if (totalItems == 0) return const SizedBox.shrink();

    final bool isMobile = MediaQuery
        .of(context)
        .size
        .width < 600;
    final int startItem = ((_currentPage - 1) * _itemsPerPage + 1).clamp(
        1, totalItems);
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
                  color: _currentPage > 1 ? const Color(0xFF279E9E) : Colors
                      .grey[400],
                ),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
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
                  color: _currentPage < totalPages
                      ? const Color(0xFF279E9E)
                      : Colors.grey[400],
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