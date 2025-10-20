import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isPasswordObscured = true;

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 1,
          'createdAt': Timestamp.now(),
        });
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload();
        await FirebaseAuth.instance.signOut();
      }

      if (mounted) {
        _showSuccessSnackBar('Registrasi berhasil! Silahkan login.');
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _phoneController.clear();

        await Future.delayed(const Duration(milliseconds: 500));
        // if(mounted) Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'Password yang diberikan terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Akun dengan email ini sudah ada.';
      } else {
        message = 'Terjadi kesalahan. Silahkan coba lagi.';
      }
      _showErrorSnackBar(message);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -screenSize.height * 0.1,
            left: -screenSize.width * 0.2,
            child: Container(
              width: screenSize.width * 0.6,
              height: screenSize.width * 0.6,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -screenSize.height * 0.1,
            right: -screenSize.width * 0.2,
            child: Container(
              width: screenSize.width * 0.7,
              height: screenSize.width * 0.7,
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Kashierku',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A3A3))),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Align(
                              alignment: Alignment.center,
                              child: Text('Buat Akun',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black))),
                          const SizedBox(height: 8),
                          const Align(
                              alignment: Alignment.center,
                              child: Text('Daftar Akun !',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                  textAlign: TextAlign.center)),
                          const SizedBox(height: 30),
                          const Text('Nama Lengkap',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                                hintText: 'Masukkan Nama Lengkap'),
                            keyboardType: TextInputType.name,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama tidak boleh kosong.';
                              }
                              if (value.length > 50) {
                                return 'Nama tidak boleh lebih dari 50 karakter.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text('Alamat Email',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                                hintText: 'Masukkan Alamat Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong.';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Tolong masukkan email yang valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text('Password',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isPasswordObscured,
                            decoration: InputDecoration(
                              hintText: 'Masukkan Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordObscured
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordObscured = !_isPasswordObscured;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong.';
                              }
                              if (value.length < 8) {
                                return 'Password harus lebih dari 8 karakter.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text('Nomor Telepon',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                                hintText: 'Masukkan Nomor Telepon'),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nomor telepon tidak boleh kosong.';
                              }
                              if (!value.startsWith('08')){
                                return ("Nomor telepon harus diawali dengan 08");
                              }
                              if (value.length < 10 || value.length > 13){
                                return ("Nomor telepon harus terdiri dari 10-13 karakter");
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _register,
                              child: const Text('Daftar'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Sudah Punya Akun ?",
                                  style: TextStyle(fontSize: 13)),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('Login!',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

