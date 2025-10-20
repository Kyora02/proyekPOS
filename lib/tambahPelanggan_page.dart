import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/service/api_service.dart';

class TambahPelangganPage extends StatefulWidget {
  final Map<String, dynamic>? pelanggan; // For Edit Mode
  const TambahPelangganPage({super.key, this.pelanggan});

  @override
  State<TambahPelangganPage> createState() => _TambahPelangganPageState();
}

enum JenisKelamin { lakiLaki, perempuan }

class _TambahPelangganPageState extends State<TambahPelangganPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  final _emailController = TextEditingController();
  final _kotaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _catatanController = TextEditingController();
  final _tanggalLahirController = TextEditingController();

  JenisKelamin? _selectedGender = JenisKelamin.lakiLaki;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get _isEditMode => widget.pelanggan != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFieldsForEdit();
    } else {
      _tanggalLahirController.text =
          DateFormat('d MMMM yyyy').format(_selectedDate);
    }
  }

  void _populateFieldsForEdit() {
    final data = widget.pelanggan!;
    _namaController.text = data['name'] ?? '';
    _teleponController.text = data['phone'] ?? '';
    _emailController.text = data['email'] ?? '';
    _kotaController.text = data['city'] ?? '';
    _alamatController.text = data['address'] ?? '';
    _catatanController.text = data['notes'] ?? '';

    _selectedGender = data['gender'] == 'Perempuan'
        ? JenisKelamin.perempuan
        : JenisKelamin.lakiLaki;

    if (data['dob'] != null) {
      // Handle Firebase Timestamp or ISO String
      if (data['dob'] is String) {
        _selectedDate = DateTime.parse(data['dob']);
      } else if (data['dob'] is Map) {
        // Assuming Firestore Timestamp
        _selectedDate = DateTime.fromMillisecondsSinceEpoch(
            data['dob']['_seconds'] * 1000);
      }
    }
    _tanggalLahirController.text =
        DateFormat('d MMMM yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    _kotaController.dispose();
    _alamatController.dispose();
    _catatanController.dispose();
    _tanggalLahirController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A3A3),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00A3A3),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text =
            DateFormat('d MMMM yyyy').format(_selectedDate);
      });
    }
  }

  Future<void> _savePelanggan() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final data = {
          'name': _namaController.text,
          'phone': _teleponController.text,
          'email': _emailController.text,
          'gender': _selectedGender == JenisKelamin.lakiLaki
              ? 'Laki-laki'
              : 'Perempuan',
          'dob': _selectedDate,
          'city': _kotaController.text,
          'address': _alamatController.text,
          'notes': _catatanController.text,
        };

        if (_isEditMode) {
          await _apiService.updatePelanggan(
            id: widget.pelanggan!['id'],
            name: data['name'] as String,
            phone: data['phone'] as String,
            email: data['email'] as String?,
            gender: data['gender'] as String?,
            dob: data['dob'] as DateTime?,
            city: data['city'] as String?,
            address: data['address'] as String?,
            notes: data['notes'] as String?,
          );
        } else {
          await _apiService.addPelanggan(
            name: data['name'] as String,
            phone: data['phone'] as String,
            email: data['email'] as String?,
            gender: data['gender'] as String?,
            dob: data['dob'] as DateTime?,
            city: data['city'] as String?,
            address: data['address'] as String?,
            notes: data['notes'] as String?,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Pelanggan berhasil disimpan!'),
                backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true); // Pop with success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal menyimpan: ${e.toString()}'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit Pelanggan' : 'Tambahkan Pelanggan',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionCard(
                    title: 'Informasi Pelanggan',
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _namaController,
                          label: 'Nama',
                          hint: 'Masukkan nama pelanggan',
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _teleponController,
                          label: 'Nomor Telepon',
                          hint: 'Contoh: 08123456789',
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Contoh: email@domain.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildGenderRadio(),
                        const SizedBox(height: 16),
                        _buildDateField(context),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _kotaController,
                          label: 'Kota',
                          hint: 'Masukkan kota',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _alamatController,
                          label: 'Alamat',
                          hint: 'Masukkan alamat',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _catatanController,
                          label: 'Catatan',
                          hint: 'Masukkan catatan',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Color(0xFF00A3A3)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _savePelanggan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A3A3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                            : const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label tidak boleh kosong';
            }
            if (keyboardType == TextInputType.emailAddress &&
                value != null &&
                value.isNotEmpty &&
                !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
              return 'Masukkan email yang valid';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGenderRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jenis Kelamin',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = JenisKelamin.lakiLaki;
                  });
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedGender == JenisKelamin.lakiLaki
                          ? const Color(0xFF00A3A3)
                          : Colors.grey[300]!,
                      width: _selectedGender == JenisKelamin.lakiLaki ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<JenisKelamin>(
                        value: JenisKelamin.lakiLaki,
                        groupValue: _selectedGender,
                        onChanged: (JenisKelamin? value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        activeColor: const Color(0xFF00A3A3),
                      ),
                      const Text('Laki-Laki'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = JenisKelamin.perempuan;
                  });
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedGender == JenisKelamin.perempuan
                          ? const Color(0xFF00A3A3)
                          : Colors.grey[300]!,
                      width:
                      _selectedGender == JenisKelamin.perempuan ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<JenisKelamin>(
                        value: JenisKelamin.perempuan,
                        groupValue: _selectedGender,
                        onChanged: (JenisKelamin? value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        activeColor: const Color(0xFF00A3A3),
                      ),
                      const Text('Perempuan'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tanggal Lahir',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tanggalLahirController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Pilih tanggal',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            suffixIcon: const Icon(Icons.calendar_today_outlined,
                color: Color(0xFF00A3A3)),
          ),
          onTap: () => _selectDate(context),
        ),
      ],
    );
  }
}