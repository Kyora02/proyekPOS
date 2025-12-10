import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  final _ownerNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _alamatController = TextEditingController();
  final _cityController = TextEditingController();
  String? _operationDuration;
  bool _isLoading = false;

  Future<void> _saveBusinessInfo() async {
    if (_ownerNameController.text.isEmpty ||
        _businessNameController.text.isEmpty ||
        _alamatController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _operationDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap isi semua informasi.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final businessData = {
        'userId': user.uid,
        'ownerName': _ownerNameController.text.trim(),
        'name': _businessNameController.text.trim(),
        'alamat': _alamatController.text.trim(),
        'city': _cityController.text.trim(),
        'operationDuration': _operationDuration,
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('outlets').add(businessData);

      await userDocRef.update({'hasBusinessInfo': true});

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan data: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _alamatController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Kashierku',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A3A3),
                ),
              ),
              const SizedBox(height: 48),
              Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 5,
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Informasi Usaha',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 24.0,
                      runSpacing: 24.0,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildTextField(
                            controller: _ownerNameController,
                            label: 'Nama Pemilik Usaha',
                            hint: 'Contoh: Edi Hartanto'),
                        _buildTextField(
                            controller: _businessNameController,
                            label: 'Nama Usaha',
                            hint: 'Contoh: Toko Sahaja'),
                        _buildTextField(
                            controller: _alamatController,
                            label: 'Alamat',
                            hint: 'Contoh: Jl. Merdeka No. 1'),
                        _buildTextField(
                            controller: _cityController,
                            label: 'Kota',
                            hint: 'Contoh: Surabaya'),
                        _buildDropdownField(
                            label: 'Lama Beroperasi',
                            hint: 'Pilih',
                            value: _operationDuration,
                            items: ['< 1 Tahun', '1-3 Tahun', '> 3 Tahun'],
                            onChanged: (val) =>
                                setState(() => _operationDuration = val)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBusinessInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A3A3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
        required String label,
        required String hint}) {
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
      {required String label,
        required String hint,
        required String? value,
        required List<String> items,
        required ValueChanged<String?> onChanged}) {
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: Text(hint),
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}