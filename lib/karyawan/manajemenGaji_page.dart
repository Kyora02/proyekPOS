import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service/api_service.dart';

class ManajemenGajiPage extends StatefulWidget {
  final String outletId;

  const ManajemenGajiPage({
    super.key,
    required this.outletId,
  });

  @override
  State<ManajemenGajiPage> createState() => _ManajemenGajiPageState();
}

class _ManajemenGajiPageState extends State<ManajemenGajiPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manajemen Gaji Karyawan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF279E9E),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF279E9E),
                      tabs: const [
                        Tab(text: 'Komponen Gaji'),
                        Tab(text: 'Konfigurasi Karyawan'),
                        Tab(text: 'Payroll'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    KomponenGajiTab(outletId: widget.outletId),
                    KonfigurasiKaryawanTab(outletId: widget.outletId),
                    PayrollTab(outletId: widget.outletId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KomponenGajiTab extends StatefulWidget {
  final String outletId;

  const KomponenGajiTab({super.key, required this.outletId});

  @override
  State<KomponenGajiTab> createState() => _KomponenGajiTabState();
}

class _KomponenGajiTabState extends State<KomponenGajiTab> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _components = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComponents();
  }

  Future<void> _loadComponents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getSalaryComponents(outletId: widget.outletId);
      setState(() {
        _components = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddComponentDialog() async {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    String selectedType = 'allowance';
    String selectedValueType = 'fixed';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Tambah Komponen Gaji'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Komponen',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'allowance', child: Text('Tunjangan')),
                    DropdownMenuItem(value: 'deduction', child: Text('Potongan')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedValueType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Nilai',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Tetap (Rp)')),
                    DropdownMenuItem(value: 'percentage', child: Text('Persentase (%)')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedValueType = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: selectedValueType == 'fixed' ? 'Nilai (Rp)' : 'Persentase (%)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
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
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF279E9E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await _apiService.addSalaryComponent(
          name: nameController.text,
          type: selectedType,
          valueType: selectedValueType,
          value: double.parse(valueController.text),
          outletId: widget.outletId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Komponen gaji berhasil ditambahkan')),
          );
          _loadComponents();
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

  Future<void> _showEditComponentDialog(Map<String, dynamic> component) async {
    final nameController = TextEditingController(text: component['name']);
    final valueController = TextEditingController(text: component['value'].toString());
    String selectedType = component['type'];
    String selectedValueType = component['valueType'];
    bool isActive = component['isActive'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Edit Komponen Gaji'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Komponen',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'allowance', child: Text('Tunjangan')),
                    DropdownMenuItem(value: 'deduction', child: Text('Potongan')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedValueType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Nilai',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Tetap (Rp)')),
                    DropdownMenuItem(value: 'percentage', child: Text('Persentase (%)')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedValueType = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: selectedValueType == 'fixed' ? 'Nilai (Rp)' : 'Persentase (%)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Status Aktif'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
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
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF279E9E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await _apiService.updateSalaryComponent(
          id: component['id'],
          name: nameController.text,
          type: selectedType,
          valueType: selectedValueType,
          value: double.parse(valueController.text),
          isActive: isActive,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Komponen gaji berhasil diupdate')),
          );
          _loadComponents();
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

  Future<void> _deleteComponent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus komponen ini?'),
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
        await _apiService.deleteSalaryComponent(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Komponen gaji berhasil dihapus')),
          );
          _loadComponents();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComponents,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _showAddComponentDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Komponen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF279E9E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _components.isEmpty
              ? Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Belum ada komponen gaji',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
              : Expanded(
            child: ListView.builder(
              itemCount: _components.length,
              itemBuilder: (context, index) {
                final component = _components[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: component['type'] == 'allowance'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        component['type'] == 'allowance'
                            ? Icons.add_circle_outline
                            : Icons.remove_circle_outline,
                        color: component['type'] == 'allowance'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    title: Text(component['name'] ?? ''),
                    subtitle: Text(
                      component['valueType'] == 'fixed'
                          ? 'Rp ${NumberFormat('#,###').format(component['value'])}'
                          : '${component['value']}%',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (component['isActive'] == false)
                          const Chip(
                            label: Text('Nonaktif', style: TextStyle(fontSize: 10)),
                            backgroundColor: Colors.grey,
                          ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditComponentDialog(component);
                            } else if (value == 'delete') {
                              _deleteComponent(component['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class KonfigurasiKaryawanTab extends StatefulWidget {
  final String outletId;

  const KonfigurasiKaryawanTab({super.key, required this.outletId});

  @override
  State<KonfigurasiKaryawanTab> createState() => _KonfigurasiKaryawanTabState();
}

class _KonfigurasiKaryawanTabState extends State<KonfigurasiKaryawanTab> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _karyawanList = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKaryawan();
  }

  Future<void> _loadKaryawan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.getKaryawan(outletId: widget.outletId);
      setState(() {
        _karyawanList = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showSalaryConfigDialog(Map<String, dynamic> karyawan) async {
    final baseSalaryController = TextEditingController();
    List<Map<String, dynamic>> selectedAllowances = [];
    List<Map<String, dynamic>> selectedDeductions = [];

    try {
      final existingConfig = await _apiService.getSalaryConfig(karyawanId: karyawan['id']);
      if (existingConfig != null) {
        baseSalaryController.text = existingConfig['baseSalary'].toString();
        selectedAllowances = List<Map<String, dynamic>>.from(existingConfig['allowances'] ?? []);
        selectedDeductions = List<Map<String, dynamic>>.from(existingConfig['deductions'] ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading config: $e')),
        );
      }
    }

    final components = await _apiService.getSalaryComponents(outletId: widget.outletId);
    final allowanceComponents = components.where((c) => c['type'] == 'allowance').toList();
    final deductionComponents = components.where((c) => c['type'] == 'deduction').toList();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Konfigurasi Gaji - ${karyawan['nama']}'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: baseSalaryController,
                    decoration: const InputDecoration(
                      labelText: 'Gaji Pokok (Rp)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  const Text('Tunjangan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...allowanceComponents.map((comp) {
                    final isSelected = selectedAllowances.any((a) => a['name'] == comp['name']);
                    return CheckboxListTile(
                      title: Text(comp['name']),
                      subtitle: Text(comp['valueType'] == 'fixed'
                          ? 'Rp ${NumberFormat('#,###').format(comp['value'])}'
                          : '${comp['value']}%'),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedAllowances.add(comp);
                          } else {
                            selectedAllowances.removeWhere((a) => a['name'] == comp['name']);
                          }
                        });
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  const Text('Potongan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...deductionComponents.map((comp) {
                    final isSelected = selectedDeductions.any((d) => d['name'] == comp['name']);
                    return CheckboxListTile(
                      title: Text(comp['name']),
                      subtitle: Text(comp['valueType'] == 'fixed'
                          ? 'Rp ${NumberFormat('#,###').format(comp['value'])}'
                          : '${comp['value']}%'),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedDeductions.add(comp);
                          } else {
                            selectedDeductions.removeWhere((d) => d['name'] == comp['name']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final existingConfig = await _apiService.getSalaryConfig(karyawanId: karyawan['id']);

        if (existingConfig == null) {
          await _apiService.addSalaryConfig(
            karyawanId: karyawan['id'],
            karyawanName: karyawan['nama'],
            outletId: widget.outletId,
            baseSalary: double.parse(baseSalaryController.text),
            allowances: selectedAllowances,
            deductions: selectedDeductions,
          );
        } else {
          await _apiService.updateSalaryConfig(
            karyawanId: karyawan['id'],
            baseSalary: double.parse(baseSalaryController.text),
            allowances: selectedAllowances,
            deductions: selectedDeductions,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konfigurasi gaji berhasil disimpan')),
          );
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadKaryawan,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: _karyawanList.isEmpty
          ? Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Belum ada data karyawan', style: TextStyle(color: Colors.grey)),
        ),
      )
          : ListView.builder(
        itemCount: _karyawanList.length,
        itemBuilder: (context, index) {
          final karyawan = _karyawanList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  karyawan['nama']?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(karyawan['nama'] ?? ''),
              subtitle: Text('NIP: ${karyawan['nip'] ?? '-'}'),
              trailing: ElevatedButton.icon(
                onPressed: () => _showSalaryConfigDialog(karyawan),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Atur Gaji'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF279E9E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PayrollTab extends StatefulWidget {
  final String outletId;

  const PayrollTab({super.key, required this.outletId});

  @override
  State<PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends State<PayrollTab> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _payrolls = [];
  List<Map<String, dynamic>> _karyawanList = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payrollData = await _apiService.getPayroll(outletId: widget.outletId);
      final karyawanData = await _apiService.getKaryawan(outletId: widget.outletId);
      setState(() {
        _payrolls = payrollData;
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

  Future<void> _showCalculateSalaryDialog() async {
    String? selectedKaryawanId;
    String? selectedKaryawanName;
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Hitung Gaji'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Karyawan',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  dropdownColor: Colors.white,
                  value: selectedKaryawanId,
                  items: _karyawanList.map<DropdownMenuItem<String>>((k) {
                    return DropdownMenuItem<String>(
                      value: k['id'].toString(),
                      child: Text(k['nama']?.toString() ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedKaryawanId = val;
                      selectedKaryawanName = _karyawanList.firstWhere((k) => k['id'].toString() == val)['nama'];
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Bulan',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  dropdownColor: Colors.white,
                  value: selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(DateFormat.MMMM().format(DateTime(2000, index + 1))),
                    );
                  }),
                  onChanged: (val) => setDialogState(() => selectedMonth = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Tahun',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  dropdownColor: Colors.white,
                  value: selectedYear,
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - 2 + index;
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (val) => setDialogState(() => selectedYear = val!),
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
              onPressed: selectedKaryawanId == null ? null : () => Navigator.pop(context, true),
              child: const Text('Hitung'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedKaryawanId != null) {
      try {
        final calculation = await _apiService.calculateSalary(
          karyawanId: selectedKaryawanId!,
          month: selectedMonth,
          year: selectedYear,
          outletId: widget.outletId,
        );

        if (!mounted) return;

        final confirm = await _showSalaryDetailDialog(calculation);

        if (confirm == true) {
          await _apiService.createPayroll(calculation);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payroll berhasil dibuat')),
            );
            _loadData();
          }
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

  Future<bool?> _showSalaryDetailDialog(Map<String, dynamic> calculation) async {
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final baseSalary = safeDouble(calculation['baseSalary']);

    double totalAllowances = 0.0;
    if (calculation['allowances'] != null && (calculation['allowances'] as List).isNotEmpty) {
      for (var allowance in calculation['allowances'] as List) {
        totalAllowances += safeDouble(allowance['calculatedValue']);
      }
    }

    double totalDeductions = 0.0;
    if (calculation['deductions'] != null && (calculation['deductions'] as List).isNotEmpty) {
      for (var deduction in calculation['deductions'] as List) {
        totalDeductions += safeDouble(deduction['calculatedValue']);
      }
    }

    final calculatedTotal = baseSalary + totalAllowances - totalDeductions;
    final apiTotal = safeDouble(calculation['totalSalary']);

    final finalTotal = apiTotal > 0 ? apiTotal : calculatedTotal;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Detail Gaji - ${calculation['karyawanName'] ?? 'Unknown'}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode: ${DateFormat.MMMM().format(DateTime(calculation['year'] ?? DateTime.now().year, calculation['month'] ?? DateTime.now().month))} ${calculation['year'] ?? DateTime.now().year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Divider(height: 24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gaji Pokok:', style: TextStyle(fontSize: 15)),
                    Text(
                      'Rp ${NumberFormat('#,###').format(baseSalary)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (calculation['allowances'] != null && (calculation['allowances'] as List).isNotEmpty) ...[
                  const Text('Tunjangan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...(calculation['allowances'] as List).map((allowance) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(allowance['name'] ?? '', style: const TextStyle(fontSize: 14)),
                        Text(
                          '+ Rp ${NumberFormat('#,###').format(safeDouble(allowance['calculatedValue']))}',
                          style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                if (calculation['deductions'] != null && (calculation['deductions'] as List).isNotEmpty) ...[
                  const Text('Potongan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...(calculation['deductions'] as List).map((deduction) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(deduction['name'] ?? '', style: const TextStyle(fontSize: 14)),
                        Text(
                          '- Rp ${NumberFormat('#,###').format(safeDouble(deduction['calculatedValue']))}',
                          style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 24),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF279E9E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF279E9E).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Gaji:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###').format(finalTotal)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF279E9E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF279E9E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan Payroll'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPayrollDetail(Map<String, dynamic> payroll) async {
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final baseSalary = safeDouble(payroll['baseSalary']);

    double totalAllowances = 0.0;
    if (payroll['allowances'] != null && (payroll['allowances'] as List).isNotEmpty) {
      for (var allowance in payroll['allowances'] as List) {
        totalAllowances += safeDouble(allowance['calculatedValue']);
      }
    }

    double totalDeductions = 0.0;
    if (payroll['deductions'] != null && (payroll['deductions'] as List).isNotEmpty) {
      for (var deduction in payroll['deductions'] as List) {
        totalDeductions += safeDouble(deduction['calculatedValue']);
      }
    }

    final calculatedTotal = baseSalary + totalAllowances - totalDeductions;
    final apiTotal = safeDouble(payroll['totalSalary'] ?? payroll['netSalary']);

    final finalTotal = apiTotal > 0 ? apiTotal : calculatedTotal;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Detail Payroll - ${payroll['karyawanName'] ?? 'Unknown'}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode: ${DateFormat.MMMM().format(DateTime(payroll['year'] ?? DateTime.now().year, payroll['month'] ?? DateTime.now().month))} ${payroll['year'] ?? DateTime.now().year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Divider(height: 24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gaji Pokok:', style: TextStyle(fontSize: 15)),
                    Text(
                      'Rp ${NumberFormat('#,###').format(baseSalary)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (payroll['allowances'] != null && (payroll['allowances'] as List).isNotEmpty) ...[
                  const Text('Tunjangan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...(payroll['allowances'] as List).map((allowance) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(allowance['name'] ?? '', style: const TextStyle(fontSize: 14)),
                        Text(
                          '+ Rp ${NumberFormat('#,###').format(safeDouble(allowance['calculatedValue']))}',
                          style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                if (payroll['deductions'] != null && (payroll['deductions'] as List).isNotEmpty) ...[
                  const Text('Potongan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...(payroll['deductions'] as List).map((deduction) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(deduction['name'] ?? '', style: const TextStyle(fontSize: 14)),
                        Text(
                          '- Rp ${NumberFormat('#,###').format(safeDouble(deduction['calculatedValue']))}',
                          style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 24),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF279E9E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF279E9E).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Gaji:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###').format(finalTotal)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF279E9E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (payroll['createdAt'] != null)
                  Text(
                    'Dibuat: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(payroll['createdAt']))}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _showCalculateSalaryDialog,
              icon: const Icon(Icons.calculate, size: 18),
              label: const Text('Hitung Gaji'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF279E9E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _payrolls.isEmpty
              ? Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Belum ada data payroll', style: TextStyle(color: Colors.grey)),
            ),
          )
              : Expanded(
            child: ListView.builder(
              itemCount: _payrolls.length,
              itemBuilder: (context, index) {
                final payroll = _payrolls[index];

                double safeDouble(dynamic value) {
                  if (value == null) return 0.0;
                  if (value is double) return value;
                  if (value is int) return value.toDouble();
                  if (value is String) return double.tryParse(value) ?? 0.0;
                  return 0.0;
                }

                final totalSalary = safeDouble(payroll['totalSalary'] ?? payroll['netSalary']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.payment, color: Colors.green),
                    ),
                    title: Text(payroll['karyawanName'] ?? 'Unknown'),
                    subtitle: Text(
                      '${DateFormat.MMMM().format(DateTime(payroll['year'] ?? DateTime.now().year, payroll['month'] ?? DateTime.now().month))} ${payroll['year'] ?? DateTime.now().year} • Rp ${NumberFormat('#,###').format(totalSalary)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _showPayrollDetail(payroll),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}