import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:proyekpos2/tambahKupon_page.dart';
import 'daftarProduk_page.dart';
import '/tambahProduk_page.dart';
import 'business_page.dart';
import 'dashboard_page.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'daftarKategori_page.dart';
import 'tambahKategori_page.dart';
import 'daftarKupo_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashierku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        fontFamily: 'Inter',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/business': (context) => const BusinessPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/daftar-produk' : (context) => const DaftarProdukPage(),
        '/tambah-produk': (context) => const TambahProdukPage(),
        '/daftar-kategori' : (context) => const DaftarKategoriPage(),
        '/tambah-kategori' : (context) => const TambahKategoriPage(),
        '/tambah-kupon' : (context) => const TambahKuponPage()
     },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userDocSnapshot.hasError || !userDocSnapshot.data!.exists) {
                return const LoginPage();
              }

              final userData =
              userDocSnapshot.data!.data() as Map<String, dynamic>;
              final bool hasBusinessInfo = userData['hasBusinessInfo'] ?? false;

              if (hasBusinessInfo) {
                return const DashboardPage();
              } else {
                return const BusinessPage();
              }
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}