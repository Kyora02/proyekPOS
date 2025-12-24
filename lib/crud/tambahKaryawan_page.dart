import 'package:flutter/material.dart';
import 'package:proyekpos2/service/api_service.dart';

class TambahKaryawanPage extends StatefulWidget {
  final Map<String, dynamic>? karyawan;
  final String outletId;
  final String outletName;

  const TambahKaryawanPage({
    super.key,
    this.karyawan,
    required this.outletId,
    required this.outletName,
  });

  @override
  State<TambahKaryawanPage> createState() => _TambahKaryawanPageState();
}

class _TambahKaryawanPageState extends State<TambahKaryawanPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _namaController = TextEditingController();
  final _nipController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notelpController = TextEditingController();

  bool _statusAktif = true;
  bool _isPasswordVisible = false;
  bool _isEditMode = false;
  String? _karyawanId;
  bool _isLoading = false;

  List<Map<String, dynamic>> _outletsList = [];
  String? _selectedOutletId;
  String? _selectedOutletName;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    _selectedOutletId = widget.outletId;
    _selectedOutletName = widget.outletName;

    if (widget.karyawan != null) {
      _isEditMode = true;
      _karyawanId = widget.karyawan!['id'];
      _namaController.text = widget.karyawan!['nama'] ?? '';
      _nipController.text = widget.karyawan!['nip'] ?? '';
      _emailController.text = widget.karyawan!['email'] ?? '';
      _notelpController.text = widget.karyawan!['notelp'] ?? '';
      _statusAktif = widget.karyawan!['status'] == 'Aktif';
      _selectedOutletId = widget.karyawan!['outletId'] ?? widget.outletId;
      _selectedOutletName = widget.karyawan!['outlet'] ?? widget.outletName;
    }

    try {
      final outlets = await _apiService.getOutlets();
      setState(() {
        _outletsList = outlets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar outlet: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _notelpController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (_isEditMode) {
          await _apiService.updateKaryawan(
            id: _karyawanId!,
            nama: _namaController.text,
            nip: _nipController.text,
            notelp: _notelpController.text,
            outlet: _selectedOutletName!,
            outletId: _selectedOutletId!,
            status: _statusAktif ? 'Aktif' : 'Tidak Aktif',
          );
        } else {
          await _apiService.addKaryawan(
            nama: _namaController.text,
            nip: _nipController.text,
            email: _emailController.text,
            password: _passwordController.text,
            notelp: _notelpController.text,
            outlet: _selectedOutletName!,
            outletId: _selectedOutletId!,
            status: _statusAktif ? 'Aktif' : 'Tidak Aktif',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Karyawan berhasil ${_isEditMode ? 'diupdate' : 'disimpan'}!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_isEditMode ? 'Ubah Karyawan' : 'Tambahkan Karyawan'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Informasi Karyawan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(height: 32),
                        _buildLabel('Nama *'),
                        _buildTextField(_namaController, 'Masukkan nama karyawan'),
                        _buildLabel('Nomor Induk Pegawai (NIP) *'),
                        _buildTextField(_nipController, 'Masukkan NIP'),
                        _buildLabel('Pilih Outlet *'),
                        _buildOutletDropdown(),
                        _buildLabel(_isEditMode ? 'Email' : 'Email *'),
                        _buildTextField(
                            _emailController,
                            'email@domain.com',
                            readOnly: _isEditMode,
                            keyboardType: TextInputType.emailAddress
                        ),
                        if (!_isEditMode) ...[
                          _buildLabel('Password *'),
                          _buildTextField(
                            _passwordController,
                            'Masukkan password',
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                        ],
                        _buildLabel('No. Telp'),
                        _buildTextField(_notelpController, '08123456789', keyboardType: TextInputType.phone),
                        _buildLabel('Status'),
                        _buildStatusToggle(),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF279E9E))),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool readOnly = false, bool obscureText = false, Widget? suffixIcon, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (v) => (v == null || v.isEmpty) && !readOnly ? 'Field wajib diisi' : null,
    );
  }

  Widget _buildOutletDropdown() {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.white,
      value: _outletsList.any((o) => o['id'] == _selectedOutletId) ? _selectedOutletId : null,
      items: _outletsList.map((outlet) {
        return DropdownMenuItem<String>(
          value: outlet['id'],
          child: Text(outlet['name'] ?? 'Outlet Tanpa Nama'),
        );
      }).toList(),
      onChanged: (value) {
        final selected = _outletsList.firstWhere((o) => o['id'] == value);
        setState(() {
          _selectedOutletId = value;
          _selectedOutletName = selected['name'];
        });
      },
      validator: (value) => value == null ? 'Silakan pilih outlet' : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: SwitchListTile(
        title: Text(_statusAktif ? 'Aktif' : 'Tidak Aktif'),
        value: _statusAktif,
        onChanged: (v) => setState(() => _statusAktif = v),
        activeColor: const Color(0xFF279E9E),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _saveForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(_isEditMode ? 'Update' : 'Simpan'),
        ),
      ],
    );
  }
}