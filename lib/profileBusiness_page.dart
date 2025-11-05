import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileBusinessPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String outletId;
  final Future<void> Function() onProfileUpdated;

  const ProfileBusinessPage({
    super.key,
    required this.userData,
    required this.outletId,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileBusinessPage> createState() => _ProfileBusinessPageState();
}

class _ProfileBusinessPageState extends State<ProfileBusinessPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _outletNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String? _operationDuration;

  final List<String> _operationDurationOptions = [
    '< 1 Tahun',
    '1-3 Tahun',
    '> 3 Tahun'
  ];

  bool _isLoading = true;
  String? _outletId;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Pengguna tidak login.");
      }

      final outletDoc = await FirebaseFirestore.instance
          .collection('outlets')
          .doc(widget.outletId)
          .get();

      if (!outletDoc.exists) {
        throw Exception(
            "Tidak ada data outlet yang cocok (ID: ${widget.outletId}).");
      }

      final data = outletDoc.data()!;

      _outletId = outletDoc.id;

      if (mounted) {
        _outletNameController.text = data['name'] ?? '';
        _cityController.text = data['city'] ?? '';
        setState(() {
          _operationDuration = data['operationDuration'];
          if (!_operationDurationOptions.contains(_operationDuration)) {
            _operationDuration = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat data bisnis: $e'),
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
    _outletNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _simpanPerubahan() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (_outletId == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: Outlet ID or User ID not found.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String newOutletName = _outletNameController.text.trim();

      final Map<String, dynamic> outletDataToUpdate = {
        'name': newOutletName,
        'city': _cityController.text.trim(),
        'operationDuration': _operationDuration,
      };

      final Map<String, dynamic> userDataToUpdate = {
        'businessName': newOutletName,
      };

      final batch = FirebaseFirestore.instance.batch();

      final outletDocRef =
      FirebaseFirestore.instance.collection('outlets').doc(_outletId!);
      batch.update(outletDocRef, outletDataToUpdate);

      final userDocRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userDocRef, userDataToUpdate);

      await batch.commit();

      await widget.onProfileUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perubahan profil bisnis disimpan!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan perubahan: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: _buildInfoCard(
                title: 'Pengaturan Profil Bisnis',
                children: [
                  const Text(
                    'Informasi Bisnis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _outletNameController,
                    label: 'Nama Outlet',
                    hintText: 'Masukkan nama outlet Anda',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Nama outlet tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _cityController,
                    label: 'Kota',
                    hintText: 'Masukkan kota operasional',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Kota tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Lama Beroperasi',
                    value: _operationDuration,
                    hint: 'Pilih lama beroperasi',
                    items: _operationDurationOptions,
                    onChanged: (String? newValue) {
                      setState(() {
                        _operationDuration = newValue;
                      });
                    },
                    validator: (value) => value == null
                        ? 'Silakan pilih lama beroperasi'
                        : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanPerubahan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF279E9E),
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : const Text('Simpan Perubahan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const Divider(height: 32, thickness: 1, color: Colors.black12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}