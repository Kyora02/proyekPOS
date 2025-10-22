import 'package:flutter/material.dart';

class TambahKaryawanPage extends StatefulWidget {
  const TambahKaryawanPage({super.key});

  @override
  State<TambahKaryawanPage> createState() => _TambahKaryawanPageState();
}

class _TambahKaryawanPageState extends State<TambahKaryawanPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _namaController = TextEditingController();
  final _nipController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notelpController = TextEditingController();

  // State for Dropdown
  String? _selectedOutlet;
  final List<String> _outletOptions = ['Kashierku Pusat', 'Kashierku Cabang Surabaya']; // Dummy data

  // State for Toggle
  bool _statusAktif = true;

  // State for password visibility
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    // Clean up controllers
    _namaController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _notelpController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      // All data is valid, proceed to save
      final nama = _namaController.text;
      final nip = _nipController.text;
      final email = _emailController.text;
      final password = _passwordController.text;
      final notelp = _notelpController.text;
      final outlet = _selectedOutlet;
      final status = _statusAktif ? 'Aktif' : 'Tidak Aktif';

      // For testing, print the values
      print('--- Data Karyawan ---');
      print('Nama: $nama');
      print('NIP: $nip');
      print('Email: $email');
      print('Password: $password');
      print('No. Telp: $notelp');
      print('Outlet: $outlet');
      print('Status: $status');

      // TODO: Add your API call to save the data here

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karyawan berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tambahkan Karyawan'),
        centerTitle: true, // <-- ADDED: Centers the title
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton( // <-- ADDED: Back button
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
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

                    _buildLabel('Email'),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'contoh: email@domain.com',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    _buildLabel('Password *'),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'Masukkan password',
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
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

                    _buildLabel('No. Telp'),
                    _buildTextField(
                      controller: _notelpController,
                      hintText: 'Contoh: 08123456789',
                      keyboardType: TextInputType.phone,
                    ),

                    _buildLabel('Outlet *'),
                    _buildOutletDropdown(),

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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildOutletDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedOutlet,
      hint: const Text('Pilih outlet'),
      items: _outletOptions.map((String outlet) {
        return DropdownMenuItem<String>(
          value: outlet,
          child: Text(outlet),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedOutlet = newValue;
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Outlet harus dipilih';
        }
        return null;
      },
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
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Just close the page
          },
          child: const Text(
            'Batal',
            style: TextStyle(color: Color(0xFF279E9E), fontSize: 16),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _saveForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Simpan', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}