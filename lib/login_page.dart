import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailTxt = TextEditingController();
  final _passwordTxt = TextEditingController();
  bool _isPasswordObscured = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailTxt.text.trim(),
        password: _passwordTxt.text.trim(),
      );

      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context).pop();

      String message;
      if (e.code == 'user-not-found') {
        message = 'Tidak ada pengguna yang ditemukan untuk email tersebut.';
      } else if (e.code == 'wrong-password') {
        message = 'Password yang dimasukkan salah.';
      } else if (e.code == 'invalid-credential') {
        message =
        'Kredensial tidak valid. Silakan periksa kembali email dan password Anda.';
      } else {
        message = 'Terjadi kesalahan. Silahkan coba lagi.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailTxt.dispose();
    _passwordTxt.dispose();
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
                              child: Text('Sign In',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black))),
                          const SizedBox(height: 8),
                          const Align(
                              alignment: Alignment.center,
                              child: Text(
                                  'Silahkan Masukkan Kredensial Akun Anda !',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                  textAlign: TextAlign.center)),
                          const SizedBox(height: 30),
                          const Text('Alamat Email',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailTxt,
                            decoration: const InputDecoration(
                                hintText: 'Masukkan Alamat Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong.';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Tolong masukkan email yang valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Password',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 20),
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                                  alignment: Alignment.centerRight,
                                ),
                                child: Text(
                                  'Lupa Password ?',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordTxt,
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
                                    _isPasswordObscured =
                                    !_isPasswordObscured;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              child: const Text('Login Sekarang!'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Belum Punya Akun ?",
                                  style: TextStyle(fontSize: 13)),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                          const RegisterPage()));
                                },
                                child: Text('Registrasi Akun!',
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

