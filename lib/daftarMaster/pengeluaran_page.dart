import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'dart:math' as math;

class PengeluaranPage extends StatefulWidget {
  final String outletId;

  const PengeluaranPage({Key? key, required this.outletId}) : super(key: key);

  @override
  State<PengeluaranPage> createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  final ScrollController _horizontalScrollController = ScrollController();
  List<Map<String, dynamic>> expenses = [];
  bool isLoading = false;
  String? selectedType;
  String? selectedCategory;
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final Map<String, String> typeLabels = {
    'one-time': 'Sekali',
    'recurring': 'Berulang',
  };

  final Map<String, String> categoryLabels = {
    'alat': 'Alat',
    'properti': 'Properti',
    'bahan': 'Bahan',
    'gaji': 'Gaji',
    'maintenance': 'Maintenance',
    'lainnya': 'Lainnya',
  };

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService().getExpenses(
        outletId: widget.outletId,
        type: selectedType,
        category: selectedCategory,
      );
      setState(() {
        expenses = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredExpenses {
    List<Map<String, dynamic>> filtered = expenses;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((expense) {
        final name = expense['name']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    return filtered;
  }

  void _sortData(List<Map<String, dynamic>> data) {
    if (_sortColumnIndex == null) return;

    data.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      switch (_sortColumnIndex) {
        case 0:
          aValue = a['name'] ?? '';
          bValue = b['name'] ?? '';
          break;
        case 1:
          aValue = categoryLabels[a['category']] ?? '';
          bValue = categoryLabels[b['category']] ?? '';
          break;
        case 2:
          aValue = typeLabels[a['type']] ?? '';
          bValue = typeLabels[b['type']] ?? '';
          break;
        case 3:
          aValue = a['amount'] ?? 0;
          bValue = b['amount'] ?? 0;
          break;
        case 4:
          aValue = DateTime.parse(a['date']).millisecondsSinceEpoch;
          bValue = DateTime.parse(b['date']).millisecondsSinceEpoch;
          break;
        default:
          return 0;
      }

      int compare;
      if (aValue is num && bValue is num) {
        compare = aValue.compareTo(bValue);
      } else if (aValue is String && bValue is String) {
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

  void _showAddEditDialog({Map<String, dynamic>? expense}) {
    final isEdit = expense != null;
    final nameController = TextEditingController(text: expense?['name'] ?? '');
    final amountController = TextEditingController(
      text: expense?['amount']?.toString() ?? '',
    );
    final descController = TextEditingController(
      text: expense?['description'] ?? '',
    );

    String selectedType = expense?['type'] ?? 'one-time';
    String selectedCategory = expense?['category'] ?? 'lainnya';
    DateTime selectedDate = expense != null
        ? DateTime.parse(expense['date'])
        : DateTime.now();
    String? recurringFrequency = expense?['recurringFrequency'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(isEdit ? 'Edit Pengeluaran' : 'Tambah Pengeluaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pengeluaran',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe',
                    border: OutlineInputBorder(),
                  ),
                  items: typeLabels.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: categoryLabels.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 16),
                if (selectedType == 'recurring')
                  DropdownButtonFormField<String>(
                    value: recurringFrequency ?? 'monthly',
                    decoration: const InputDecoration(
                      labelText: 'Frekuensi',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Harian')),
                      DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
                      DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                      DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => recurringFrequency = value);
                    },
                  ),
                if (selectedType == 'recurring') const SizedBox(height: 16),
                ListTile(
                  title: const Text('Tanggal'),
                  subtitle: Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mohon isi semua field')),
                  );
                  return;
                }

                try {
                  if (isEdit) {
                    await ApiService().updateExpense(
                      id: expense['id'],
                      name: nameController.text,
                      amount: double.parse(amountController.text),
                      type: selectedType,
                      category: selectedCategory,
                      description: descController.text,
                      date: selectedDate,
                      recurringFrequency: selectedType == 'recurring'
                          ? recurringFrequency
                          : null,
                    );
                  } else {
                    await ApiService().addExpense(
                      name: nameController.text,
                      amount: double.parse(amountController.text),
                      type: selectedType,
                      category: selectedCategory,
                      description: descController.text,
                      date: selectedDate,
                      outletId: widget.outletId,
                      recurringFrequency: selectedType == 'recurring'
                          ? recurringFrequency
                          : null,
                    );
                  }

                  Navigator.pop(context);
                  _loadExpenses();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Pengeluaran berhasil diupdate'
                              : 'Pengeluaran berhasil ditambahkan',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF279E9E),
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Update' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Pengeluaran'),
        content: Text('Apakah Anda yakin ingin menghapus pengeluaran "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().deleteExpense(id);
        _loadExpenses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengeluaran berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredData = _filteredExpenses;
    _sortData(filteredData);
    final totalItems = filteredData.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilterRow(),
                  const SizedBox(height: 24),
                  _buildExpenseTable(filteredData),
                  const SizedBox(height: 24),
                  _buildPagination(totalItems, totalPages),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Daftar Pengeluaran',
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
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
        )
            : ElevatedButton.icon(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tambah Pengeluaran', style: TextStyle(fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari pengeluaran...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 1;
              });
            },
          ),
        ),
        Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              dropdownColor: Colors.white,
              value: selectedType,
              isExpanded: true,
              hint: const Text('Semua Tipe'),
              onChanged: (String? newValue) {
                setState(() {
                  selectedType = newValue;
                  _currentPage = 1;
                  _loadExpenses();
                });
              },
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Tipe')),
                ...typeLabels.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }),
              ],
            ),
          ),
        ),
        Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              dropdownColor: Colors.white,
              value: selectedCategory,
              isExpanded: true,
              hint: const Text('Semua Kategori'),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue;
                  _currentPage = 1;
                  _loadExpenses();
                });
              },
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                ...categoryLabels.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseTable(List<Map<String, dynamic>> data) {
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, data.length);
    final List<Map<String, dynamic>> pageData = data.sublist(startIndex, endIndex);

    if (pageData.isEmpty) {
      final String message = _searchQuery.isNotEmpty
          ? 'Tidak ada pengeluaran ditemukan.'
          : 'Belum ada pengeluaran.';

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0),
          child: Center(child: Text(message)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalScrollController,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 80.0,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey[600],
              ),
              dataTextStyle: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              columns: [
                DataColumn(
                  label: const Text('NAMA PENGELUARAN'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('KATEGORI'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('TIPE'),
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('JUMLAH'),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('TANGGAL'),
                  onSort: _onSort,
                ),
                const DataColumn(
                  label: Text('AKSI'),
                ),
              ],
              rows: pageData.map((expense) {
                return DataRow(
                  cells: [
                    DataCell(Text(expense['name'] ?? 'N/A')),
                    DataCell(Text(categoryLabels[expense['category']] ?? 'N/A')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: expense['type'] == 'recurring'
                              ? Colors.orange[50]
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: expense['type'] == 'recurring'
                                ? Colors.orange[200]!
                                : Colors.blue[200]!,
                          ),
                        ),
                        child: Text(
                          typeLabels[expense['type']] ?? 'N/A',
                          style: TextStyle(
                            color: expense['type'] == 'recurring'
                                ? Colors.orange[700]
                                : Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(currencyFormat.format(expense['amount']))),
                    DataCell(
                      Text(
                        DateFormat('dd MMM yyyy', 'id_ID')
                            .format(DateTime.parse(expense['date'])),
                      ),
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (String value) {
                          switch (value) {
                            case 'Ubah':
                              _showAddEditDialog(expense: expense);
                              break;
                            case 'Hapus':
                              _deleteExpense(expense['id'], expense['name']);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'Ubah',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20, color: Colors.black54),
                                SizedBox(width: 12),
                                Text('Ubah'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Hapus',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Hapus', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'alat':
        return Icons.build;
      case 'properti':
        return Icons.home;
      case 'bahan':
        return Icons.inventory;
      case 'gaji':
        return Icons.payments;
      case 'maintenance':
        return Icons.engineering;
      default:
        return Icons.more_horiz;
    }
  }

  String _getFrequencyLabel(String? frequency) {
    switch (frequency) {
      case 'daily':
        return 'Harian';
      case 'weekly':
        return 'Mingguan';
      case 'monthly':
        return 'Bulanan';
      case 'yearly':
        return 'Tahunan';
      default:
        return '';
    }
  }
}