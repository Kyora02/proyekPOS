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

  @override
  void initState() {
    super.initState();

    if (widget.karyawan != null) {
      _isEditMode = true;
      _karyawanId = widget.karyawan!['id'];
      _namaController.text = widget.karyawan!['nama'] ?? '';
      _nipController.text = widget.karyawan!['nip'] ?? '';
      _emailController.text = widget.karyawan!['email'] ?? '';
      _notelpController.text = widget.karyawan!['notelp'] ?? '';
      _statusAktif = widget.karyawan!['status'] == 'Aktif';
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
      setState(() {
        _isLoading = true;
      });

      final nama = _namaController.text;
      final nip = _nipController.text;
      final email = _emailController.text;
      final password = _passwordController.text;
      final notelp = _notelpController.text;

      final outletId = widget.outletId;
      final outletName = widget.outletName;
      final status = _statusAktif ? 'Aktif' : 'Tidak Aktif';

      try {
        if (_isEditMode) {
          await _apiService.updateKaryawan(
            id: _karyawanId!,
            nama: nama,
            nip: nip,
            notelp: notelp,
            outlet: outletName,
            outletId: outletId,
            status: status,
          );
        } else {
          await _apiService.addKaryawan(
            nama: nama,
            nip: nip,
            email: email,
            password: password,
            notelp: notelp,
            outlet: outletName,
            outletId: outletId,
            status: status,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Karyawan berhasil ${_isEditMode ? 'diupdate' : 'disimpan'}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
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
              padding:
              const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
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
                        const Text(
                          'Informasi Karyawan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 32),
                        _buildLabel('Nama *'),
                        _buildTextField(
                          controller: _namaController,
                          hintText: 'Masukkan nama karyawan',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        _buildLabel('Nomor Induk Pegawai (NIP) *'),
                        _buildTextField(
                          controller: _nipController,
                          hintText: 'Masukkan NIP',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'NIP tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        _buildLabel(_isEditMode ? 'Email' : 'Email *'),
                        _buildTextField(
                          controller: _emailController,
                          hintText: 'contoh: email@domain.com',
                          keyboardType: TextInputType.emailAddress,
                          readOnly: _isEditMode,
                          validator: (value) {
                            if (!_isEditMode &&
                                (value == null || value.isEmpty)) {
                              return 'Email tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        if (!_isEditMode) ...[
                          _buildLabel('Password *'),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: 'Masukkan password',
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ],
                        _buildLabel('No. Telp'),
                        _buildTextField(
                          controller: _notelpController,
                          hintText: 'Contoh: 08123456789',
                          keyboardType: TextInputType.phone,
                        ),
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
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    bool isRequired = text.endsWith('*');
    String labelText = isRequired ? text.substring(0, text.length - 1) : text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: RichText(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          children: isRequired
              ? [
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]
              : [],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(
          _statusAktif ? 'Aktif' : 'Tidak Aktif',
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
        ),
        value: _statusAktif,
        onChanged: (bool value) {
          setState(() {
            _statusAktif = value;
          });
        },
        activeColor: const Color(0xFF279E9E),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(_isEditMode ? 'Update' : 'Simpan',
              style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}