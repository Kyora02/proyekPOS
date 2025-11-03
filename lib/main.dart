import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:proyekpos2/crud/tambahKaryawan_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:proyekpos2/crud/tambahKupon_page.dart';
import 'package:proyekpos2/crud/tambahPelanggan_page.dart';
import 'package:proyekpos2/daftarMaster/daftarKupon_page.dart';
import 'daftarMaster/daftarProduk_page.dart';
import 'crud/tambahProduk_page.dart';
import 'business_page.dart';
import 'dashboard_page.dart';
import 'service/firebase_options.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'daftarMaster/daftarKategori_page.dart';
import 'crud/tambahKategori_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);
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
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterPage());
          case '/business':
            return MaterialPageRoute(builder: (_) => const BusinessPage());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardPage());
          case '/daftar-produk':
            return MaterialPageRoute(builder: (_) => const DaftarProdukPage());
          case '/tambah-produk':
            final Map<String, dynamic>? product =
            settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => TambahProdukPage(product: product),
            );
          case '/daftar-kategori':
            return MaterialPageRoute(builder: (_) => const DaftarKategoriPage());

          case '/tambah-kategori':
            final Map<String, dynamic>? kategori =
            settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => TambahKategoriPage(kategori: kategori),
            );
          case '/daftar-kupon':
            return MaterialPageRoute(builder: (_) => const DaftarKuponPage());
          case '/tambah-kupon':
            final Map<String, dynamic>? kupon =
            settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => TambahKuponPage(kupon: kupon),
            );
          case '/tambah-pelanggan':
            final Map<String, dynamic>? pelanggan =
            settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => TambahPelangganPage(pelanggan: pelanggan),
            );
          case '/tambah-karyawan':
            final Map<String, dynamic>? karyawan =
            settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => TambahKaryawanPage(karyawan: karyawan),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
        }
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
                FirebaseAuth.instance.signOut();
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
