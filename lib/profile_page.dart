import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onProfileUpdated;

  const ProfilePage({
    super.key,
    required this.userData,
    required this.onProfileUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;


  late TextEditingController _editNameCtr;
  late TextEditingController _editPhoneCtr;
  late TextEditingController _passwordCtr;
  late TextEditingController _confirmPasswordCtr;

  @override
  void initState() {
    super.initState();
    _editNameCtr =
        TextEditingController(text: widget.userData['name']?.toString() ?? '');
    _editPhoneCtr = TextEditingController(
        text: widget.userData['phone']?.toString() ?? '');
    _passwordCtr = TextEditingController();
    _confirmPasswordCtr = TextEditingController();
  }

  @override
  void dispose() {
    _editNameCtr.dispose();
    _editPhoneCtr.dispose();
    _passwordCtr.dispose();
    _confirmPasswordCtr.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Pengguna tidak ditemukan. Silakan login kembali.");
      }

      final Map<String, dynamic> dataToUpdate = {};
      if (_editNameCtr.text != (widget.userData['name']?.toString() ?? '')) {
        dataToUpdate['name'] = _editNameCtr.text;
      }
      if (_editPhoneCtr.text !=
          (widget.userData['phone']?.toString() ?? '')) {
        dataToUpdate['phone'] = _editPhoneCtr.text;
      }

      if (dataToUpdate.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(dataToUpdate);
      }

      if (_passwordCtr.text.isNotEmpty) {
        await user.updatePassword(_passwordCtr.text);
      }
      widget.onProfileUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengaturan Profil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 24),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24.0),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Informasi Akun Profil'),
            const SizedBox(height: 16),
            _buildProfileInfoFields(),
            const SizedBox(height: 24),
            _buildSectionHeader('Ubah Kata Sandi (Opsional)'),
            const SizedBox(height: 16),
            _buildPasswordFields(),
            const SizedBox(height: 24),
            _buildSectionHeader('Informasi Hak Akses'),
            const SizedBox(height: 16),
            _buildAccessInfoField(),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF279E9E),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                )
                    : const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoFields() {
    return Column(
      children: [
        _buildTextField(
          label: 'Email',
          initialValue:
          widget.userData['email']?.toString() ?? 'tidak ada email',
          enabled: false,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Nama',
          controller: _editNameCtr,
          hint: 'Masukkan nama lengkap Anda',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama tidak boleh kosong';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Nomor Telepon',
          controller: _editPhoneCtr,
          hint: 'Contoh: 081234567890',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nomor telepon tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        _buildTextField(
          label: 'Kata Sandi Baru',
          controller: _passwordCtr,
          isPassword: true,
          isVisible: _isPasswordVisible,
          onVisibilityToggle: () {
            setState(() => _isPasswordVisible = !_isPasswordVisible);
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Konfirmasi Kata Sandi Baru',
          controller: _confirmPasswordCtr,
          isPassword: true,
          isVisible: _isConfirmPasswordVisible,
          onVisibilityToggle: () {
            setState(
                    () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
          },
          validator: (value) {
            if (_passwordCtr.text.isNotEmpty && value != _passwordCtr.text) {
              return 'Kata sandi tidak cocok';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    TextEditingController? controller,
    String? hint,
    bool enabled = true,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          enabled: enabled,
          obscureText: isPassword && !isVisible,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: Color(0xFF279E9E), width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: onVisibilityToggle,
            )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAccessInfoField() {
    final roleValue = widget.userData['role'];
    String roleDisplayText;
    switch (roleValue) {
      case 1:
        roleDisplayText = 'Owner';
        break;
      case 2:
        roleDisplayText = 'Karyawan';
        break;
      default:
        roleDisplayText = 'Tidak Diketahui';
    }
    return _buildTextField(
      label: 'Hak Akses',
      initialValue: roleDisplayText,
      enabled: false,
    );
  }
}