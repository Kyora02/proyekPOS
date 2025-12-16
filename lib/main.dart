import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'bloc/cart/cart_bloc.dart';
import 'bloc/menu/menu_bloc.dart';
import 'profile/business_page.dart';
import 'dashboard_page.dart';
import 'service/firebase_options.dart';
import 'registration/login_page.dart';
import 'registration/register_page.dart';
import 'karyawan/karyawan_dashboard_page.dart';
import 'sync-transaction/connectivity_monitor_widget.dart';
import 'self_order/self_order_page.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('pending_transactions');
  await initializeDateFormatting('id_ID', null);

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CartBloc()),
        BlocProvider(create: (_) => MenuBloc()),
      ],
      child: MaterialApp(
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
        home: const ConnectivityMonitor(
          child: AuthWrapper(),
        ),
        onGenerateRoute: (settings) {
          if (settings.name != null) {
            final Uri uri = Uri.parse(settings.name!);

            if (uri.path == '/self-order') {
              return MaterialPageRoute(builder: (_) => const SelfOrderPage());
            }
          }
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterPage());
            case '/business':
              return MaterialPageRoute(builder: (_) => const BusinessPage());
            case '/dashboard':
              return MaterialPageRoute(builder: (_) => const DashboardPage());
            // case '/self-order':
            //   return MaterialPageRoute(builder: (_) => const SelfOrderPage());
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Page not found')),
                ),
              );
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _getRedirectPage(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final bool hasBusinessInfo = userData['hasBusinessInfo'] ?? false;

      if (hasBusinessInfo) {
        return const DashboardPage();
      } else {
        return const BusinessPage();
      }
    }

    final karyawanQuery = await FirebaseFirestore.instance
        .collection('karyawan')
        .where('authUid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (karyawanQuery.docs.isNotEmpty) {
      final karyawanDoc = karyawanQuery.docs.first;
      final karyawanData = karyawanDoc.data();

      if (karyawanData['status'] == 'Aktif') {
        return KaryawanDashboardPage(
          karyawanData: karyawanData,
          karyawanId: karyawanDoc.id,
        );
      } else {
        await FirebaseAuth.instance.signOut();
        return const LoginPage();
      }
    }

    await FirebaseAuth.instance.signOut();
    return const LoginPage();
  }

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

          return FutureBuilder<Widget>(
            future: _getRedirectPage(user),
            builder: (context, redirectSnapshot) {
              if (redirectSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (redirectSnapshot.hasError) {
                FirebaseAuth.instance.signOut();
                return const LoginPage();
              }

              if (redirectSnapshot.hasData) {
                return redirectSnapshot.data!;
              }

              return const LoginPage();
            },
          );
        }

        return const LoginPage();
      },
    );
  }
}