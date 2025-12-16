import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'package:proyekpos2/sync-transaction/local_database_service.dart';
import 'package:proyekpos2/sync-transaction/sync_manager_service.dart';
import '../../registration/login_page.dart';
import '../../payment/payment_webview_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KaryawanDashboardPage extends StatefulWidget {
  final Map<String, dynamic> karyawanData;
  final String karyawanId;

  const KaryawanDashboardPage({
    super.key,
    required this.karyawanData,
    required this.karyawanId,
  });

  @override
  State<KaryawanDashboardPage> createState() => _KaryawanDashboardPageState();
}

class _KaryawanDashboardPageState extends State<KaryawanDashboardPage> {
  final ApiService _apiService = ApiService();
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  final SyncManagerService _syncManager = SyncManagerService.instance;
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _availableCoupons = [];
  Map<String, dynamic>? _appliedCoupon;

  bool _isLoading = true;
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  String _selectedCategoryId = 'all';
  String _selectedPaymentMethod = 'QRIS';
  String? _currentOrderId;

  Map<String, dynamic>? _todayAttendance;
  bool _isLoadingAttendance = false;

  double _subtotal = 0.0;
  double _pajak = 0.0;
  double _discount = 0.0;
  double _total = 0.0;
  final double _pajakRate = 0.10;

  final Color _primaryColor = const Color(0xFF00A3A3);
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
    _checkTodayAttendance();
    _initializeSync();
  }

  void _initializeSync() async {
    _syncManager.startListening();

    _isOnline = await _syncManager.isOnline();
    _pendingSyncCount = await _syncManager.getPendingCount();

    if (mounted) {
      setState(() {});
    }

    _syncManager.syncStatusStream.listen((status) {
      if (mounted) {
        if (status.isComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status.message),
              backgroundColor: status.hasErrors ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          _updatePendingCount();
        } else if (status.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status.message),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    });

    if (_isOnline && _pendingSyncCount > 0) {
      _syncManager.syncPendingTransactions();
    }
  }

  Future<void> _updatePendingCount() async {
    final count = await _syncManager.getPendingCount();
    if (mounted) {
      setState(() {
        _pendingSyncCount = count;
      });
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final String outletId = widget.karyawanData['outletId'] ?? '';

      if (outletId.isEmpty) throw Exception("Outlet ID tidak ditemukan");

      final results = await Future.wait([
        _apiService.getCategories(outletId: outletId),
        _apiService.getProducts(outletId: outletId),
        _apiService.getKupon(outletId: outletId),
      ]);

      setState(() {
        _categories = results[0];

        List<Map<String, dynamic>> rawProducts = results[1];
        _allProducts = rawProducts.where((product) {
          return product['showInMenu'] == true || product['showInMenu'] == null;
        }).toList();

        _filteredProducts = _allProducts;
        _availableCoupons = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _checkTodayAttendance() async {
    setState(() => _isLoadingAttendance = true);

    try {
      final String outletId = widget.karyawanData['outletId'] ?? '';
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final absensiList = await _apiService.getAbsensi(
        outletId: outletId,
        karyawanId: widget.karyawanId,
        startDate: today,
        endDate: today,
      );

      setState(() {
        _todayAttendance = absensiList.isNotEmpty ? absensiList.first : null;
        _isLoadingAttendance = false;
      });
    } catch (e) {
      setState(() => _isLoadingAttendance = false);
      print('Error checking attendance: $e');
    }
  }

  Future<void> _performAttendance() async {
    final bool isCheckIn = _todayAttendance == null || _todayAttendance!['jamMasuk'] == null;
    final String action = isCheckIn ? 'Check In' : 'Check Out';
    final String message = isCheckIn
        ? 'Apakah Anda yakin ingin melakukan absen masuk?'
        : 'Apakah Anda yakin ingin melakukan absen keluar?';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text('Konfirmasi $action'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(100, 48),
            ),
            child: const Text('Batal', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(120, 48),
            ),
            child: const Text('Ya, Lanjutkan', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingAttendance = true);

    try {
      final String karyawanName = widget.karyawanData['nama'] ?? 'Karyawan';
      final String outletId = widget.karyawanData['outletId'] ?? '';

      final now = DateTime.now();

      await _apiService.createAbsensi(
        karyawanId: widget.karyawanId,
        karyawanName: karyawanName,
        outletId: outletId,
        type: isCheckIn ? 'masuk' : 'keluar',
        timestamp: now.toUtc().toIso8601String(),
      );

      await _checkTodayAttendance();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCheckIn ? '✅ Absen masuk berhasil!' : '✅ Absen keluar berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingAttendance = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAttendanceDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final bool hasCheckedIn = _todayAttendance != null && _todayAttendance!['jamMasuk'] != null;
              final bool hasCheckedOut = _todayAttendance != null && _todayAttendance!['jamKeluar'] != null;

              String jamMasuk = '-';
              String jamKeluar = '-';

              if (hasCheckedIn) {
                final DateTime masuk = DateTime.parse(_todayAttendance!['jamMasuk']).toLocal();
                jamMasuk = DateFormat('HH:mm').format(masuk);
              }

              if (hasCheckedOut) {
                final DateTime keluar = DateTime.parse(_todayAttendance!['jamKeluar']).toLocal();
                jamKeluar = DateFormat('HH:mm').format(keluar);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, color: _primaryColor, size: 24),
                          const SizedBox(width: 8),
                          const Text('Absensi Hari Ini', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Jam Masuk', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(jamMasuk, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 50, color: Colors.white30),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Jam Keluar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(jamKeluar, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: (hasCheckedOut || _isLoadingAttendance)
                                ? null
                                : () async {
                              await _performAttendance();
                              if (mounted) Navigator.pop(context);
                            },
                            child: _isLoadingAttendance
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                            )
                                : Text(
                              hasCheckedOut ? 'Sudah Absen Hari Ini' : hasCheckedIn ? 'Absen Keluar' : 'Absen Masuk',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _filterProducts(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      if (categoryId == 'all') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((p) => p['categoryId'] == categoryId).toList();
      }
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final String id = product['_id'] ?? product['id'];
      final String name = product['name'] ?? 'Produk';
      final double price = (product['sellingPrice'] ?? 0).toDouble();

      int index = _cartItems.indexWhere((item) => item['id'] == id);

      if (index != -1) {
        _cartItems[index]['quantity']++;
      } else {
        _cartItems.add({
          'id': id,
          'nama': name,
          'harga': price,
          'quantity': 1,
        });
      }
      _calculateTotals();
    });
  }

  void _incrementQuantity(int index) {
    setState(() {
      _cartItems[index]['quantity']++;
      _calculateTotals();
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_cartItems[index]['quantity'] > 1) {
        _cartItems[index]['quantity']--;
      } else {
        _cartItems.removeAt(index);
      }
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    for (var item in _cartItems) {
      subtotal += (item['harga'] * item['quantity']);
    }

    double discountAmount = 0.0;
    if (_appliedCoupon != null) {
      double couponValue = (_appliedCoupon!['nilai'] ?? 0).toDouble();
      String type = _appliedCoupon!['tipeNilai'] ?? 'amount';

      if (type == 'percent') {
        discountAmount = subtotal * (couponValue / 100);
      } else {
        discountAmount = couponValue;
      }

      if (discountAmount > subtotal) {
        discountAmount = subtotal;
      }
    }

    setState(() {
      _subtotal = subtotal;
      _discount = discountAmount;
      _pajak = (_subtotal - _discount) * _pajakRate;
      if (_pajak < 0) _pajak = 0;
      _total = (_subtotal - _discount) + _pajak;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    }
  }

  void _showCouponDialog() {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pilih Kupon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: 'Masukkan Kode Kupon',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _applyCouponByCode(codeController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cek'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Kupon Tersedia:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                _availableCoupons.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16.0), child: Text("Tidak ada kupon aktif saat ini."))
                    : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableCoupons.length,
                    itemBuilder: (context, index) {
                      final coupon = _availableCoupons[index];
                      final bool isPercent = coupon['tipeNilai'] == 'percent';
                      final String valueStr = isPercent ? "${coupon['nilai']}%" : _currencyFormat.format(coupon['nilai']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.local_offer, color: Colors.orange),
                          title: Text(coupon['nama'] ?? 'Kupon'),
                          subtitle: Text(coupon['kodeKupon'] ?? ''),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(valueStr, style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 16)),
                              GestureDetector(
                                onTap: () {
                                  _applyCoupon(coupon);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(4)),
                                  child: const Text("Pakai", style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyCouponByCode(String code) {
    if (code.isEmpty) return;

    final foundCoupon = _availableCoupons.firstWhere(
          (c) => c['kodeKupon'].toString().toLowerCase() == code.toLowerCase(),
      orElse: () => {},
    );

    if (foundCoupon.isNotEmpty) {
      _applyCoupon(foundCoupon);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode kupon tidak valid atau kadaluarsa')),
      );
    }
  }

  void _applyCoupon(Map<String, dynamic> coupon) {
    setState(() {
      _appliedCoupon = coupon;
      _calculateTotals();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kupon ${coupon['nama']} berhasil dipasang!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _calculateTotals();
    });
  }

  Future<void> _processPayment() async {
    final String customerName = _customerNameController.text.trim().isEmpty ? 'Unknown User' : _customerNameController.text.trim();
    final String customerPhone = _customerPhoneController.text.trim().isEmpty ? '-' : _customerPhoneController.text.trim();

    Navigator.pop(context);

    final bool isOnline = await _syncManager.isOnline();

    if (!isOnline && _selectedPaymentMethod == 'QRIS') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Metode QRIS memerlukan koneksi internet. Gunakan Cash atau EDC.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!isOnline) {
      await _processOfflinePayment(customerName, customerPhone);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String apiPaymentMethod = 'Midtrans';
      if (_selectedPaymentMethod == 'EDC') apiPaymentMethod = 'EDC';
      if (_selectedPaymentMethod == 'Tunai') apiPaymentMethod = 'Tunai';

      final result = await _apiService.createTransaction(
        amount: _total,
        items: _cartItems,
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethod: apiPaymentMethod,
        karyawanId: widget.karyawanId,
        outletId: widget.karyawanData['outletId'] ?? '',
      );

      if (_selectedPaymentMethod == 'EDC' || _selectedPaymentMethod == 'Tunai') {
        await _apiService.updateTransactionStatus(result['orderId'], 'success');
        await _apiService.reduceStock(items: _cartItems);
        setState(() => _isLoading = false);
        _finishTransaction();
        return;
      }

      if (_selectedPaymentMethod == 'QRIS') {
        if (result['redirect_url'] == null || result['redirect_url'].isEmpty) {
          throw Exception("Gagal mendapatkan link pembayaran dari server");
        }

        String url = result['redirect_url'];
        String orderId = result['orderId'];

        if (kIsWeb) {
          _currentOrderId = orderId;
          setState(() => _isLoading = false);

          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);

            if (mounted) {
              _showWebPaymentStatusDialog(orderId);
            }
          } else {
            throw Exception("Tidak bisa membuka link pembayaran");
          }
        } else {
          setState(() => _isLoading = false);

          if (mounted) {
            final bool? paymentSuccess = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentWebviewPage(url: url, orderId: orderId),
              ),
            );

            if (paymentSuccess == true) {
              setState(() => _isLoading = true);
              await Future.delayed(const Duration(seconds: 2));
              await _checkFinalPaymentStatus(orderId);
              setState(() => _isLoading = false);
              _finishTransaction();
            } else if (paymentSuccess == false) {
              _showRetryDialog(orderId);
            } else {
              setState(() => _isLoading = true);
              await _checkFinalPaymentStatus(orderId);
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Status pembayaran tidak jelas. Silakan cek riwayat transaksi.')),
              );
            }
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      String errorMessage = 'Error: $e';

      if (e.toString().contains('Nomor telepon ini sudah terdaftar')) {
        final match = RegExp(r'atas nama "([^"]+)"').firstMatch(e.toString());
        if (match != null) {
          final existingName = match.group(1);
          errorMessage = 'Nomor telepon ini sudah terdaftar atas nama "$existingName". Silakan gunakan nama yang sama atau nomor telepon yang berbeda.';

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Nomor Telepon Sudah Terdaftar'),
              content: Text('Nomor telepon ini sudah terdaftar atas nama "$existingName".\n\nApakah Anda ingin menggunakan nama tersebut?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _customerNameController.text = existingName!;
                    _showPaymentDialog();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                  child: const Text('Ya, Gunakan Nama Ini'),
                ),
              ],
            ),
          );
          return;
        }
      } else if (e.toString().contains('409')) {
        errorMessage = 'Transaksi duplikat terdeteksi. Silakan coba lagi.';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Data transaksi tidak valid. Silakan periksa kembali.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Koneksi timeout. Silakan cek koneksi internet Anda.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'COBA LAGI',
            textColor: Colors.white,
            onPressed: () {
              _showPaymentDialog();
            },
          ),
        ),
      );
    }
  }

  Future<void> _processOfflinePayment(String customerName, String customerPhone) async {
    try {
      final clientTransactionId = const Uuid().v4();

      await _localDb.insertPendingTransaction(
        clientTransactionId: clientTransactionId,
        grossAmount: _total,
        items: _cartItems,
        tax: _pajak,
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethod: _selectedPaymentMethod,
        karyawanId: widget.karyawanId,
        outletId: widget.karyawanData['outletId'] ?? '',
      );

      await _updatePendingCount();

      _finishTransaction();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💾 Transaksi tersimpan offline. Akan disinkronkan saat online.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal menyimpan transaksi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWebPaymentStatusDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WebPaymentStatusDialog(
        orderId: orderId,
        apiService: _apiService,
        cartItems: _cartItems,
        onSuccess: () {
          Navigator.pop(context);
          _finishTransaction();
        },
        onFailed: () {
          Navigator.pop(context);
          _showRetryDialog(orderId);
        },
      ),
    );
  }

  Future<void> _checkFinalPaymentStatus(String orderId) async {
    try {
      final status = await _apiService.checkTransactionStatus(orderId);

      if (status != null) {
        if (status['status'] == 'success' ||
            status['transactionStatus'] == 'settlement' ||
            status['transactionStatus'] == 'capture') {
        } else if (status['status'] == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran masih diproses. Silakan cek kembali nanti.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking final status: $e');
    }
  }

  void _showRetryDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Dibatalkan'),
        content: const Text('Apakah Anda ingin mencoba lagi atau membatalkan transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batalkan'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              await _checkFinalPaymentStatus(orderId);
              setState(() => _isLoading = false);
            },
            child: const Text('Cek Status'),
          ),
        ],
      ),
    );
  }

  void _finishTransaction() async {
    await _fetchData();

    setState(() {
      _cartItems.clear();
      _appliedCoupon = null;
      _discount = 0.0;
      _calculateTotals();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _currentOrderId = null;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Transaksi Berhasil!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    if (_cartItems.isEmpty) return;
    _customerNameController.clear();
    _customerPhoneController.clear();
    setState(() {
      _selectedPaymentMethod = 'QRIS';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Checkout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(height: 30),
                    Center(
                      child: Column(
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(_total),
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Pelanggan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        hintText: '08...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.phone),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          _buildPaymentTab('QRIS / Online', 'QRIS', setStateDialog),
                          _buildPaymentTab('EDC', 'EDC', setStateDialog),
                          _buildPaymentTab('Tunai', 'Tunai', setStateDialog),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: _processPayment,
                        child: const Text('Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  void _showIncomingOrders(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                AppBar(
                  title: const Text("Pesanan Masuk"),
                  automaticallyImplyLeading: false,
                  actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))],
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('outletId', isEqualTo: widget.karyawanData['outletId'])
                        .where('orderStatus', whereIn: ['pending_payment', 'processing'])
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text("Tidak ada pesanan aktif"));

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: docs.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final String docId = docs[index].id;
                          final String status = data['orderStatus'] ?? '';
                          final List items = data['items'] ?? [];

                          Color statusColor = status == 'processing' ? Colors.green : Colors.orange;
                          String statusText = status == 'processing' ? 'Siapkan Pesanan' : 'Menunggu Bayar';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(side: BorderSide(color: statusColor, width: 1.5), borderRadius: BorderRadius.circular(8)),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor,
                                child: Icon(status == 'processing' ? Icons.soup_kitchen : Icons.hourglass_bottom, color: Colors.white),
                              ),
                              title: Text("${data['customerName']} - Meja ${data['tableNumber']}"),
                              subtitle: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                              trailing: Text(_currencyFormat.format(data['totalAmount'])),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Detail Pesanan:", style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      ...items.map((item) => Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("${item['quantity']}x ${item['name']}"),
                                          if(item['note'] != null && item['note'] != "")
                                            Text("(${item['note']})", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      )),
                                      const SizedBox(height: 16),
                                      if (status == 'processing')
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                                            onPressed: () async {
                                              await _apiService.completeOrder(docId);
                                              if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pesanan Selesai")));
                                            },
                                            child: const Text("Tandai Selesai & Antar"),
                                          ),
                                        ),
                                      if (status == 'pending_payment')
                                        const Center(child: Text("Menunggu pelanggan konfirmasi bayar di HP mereka...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentTab(String label, String value, StateSetter setStateDialog) {
    final bool isSelected = _selectedPaymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setStateDialog(() {
            _selectedPaymentMethod = value;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Keranjang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cartItems.isEmpty
                        ? const Center(child: Text("Keranjang Kosong"))
                        : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          color: Colors.white,
                          surfaceTintColor: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item['nama'], maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(_currencyFormat.format(item['harga'] * item['quantity'])),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () {
                                    _decrementQuantity(index);
                                    setSheetState(() {});
                                  },
                                ),
                                Text('${item['quantity']}'),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline, color: _primaryColor),
                                  onPressed: () {
                                    _incrementQuantity(index);
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildCartSummary(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String namaKaryawan = widget.karyawanData['nama'] ?? 'Karyawan';
    final bool hasCheckedIn = _todayAttendance != null && _todayAttendance!['jamMasuk'] != null;
    final bool hasCheckedOut = _todayAttendance != null && _todayAttendance!['jamKeluar'] != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Kasir : $namaKaryawan'),
            if (!_isOnline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('OFFLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
            if (_pendingSyncCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_pendingSyncCount Pending', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // ADDED: Notification Icon for Incoming Orders with Badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .where('outletId', isEqualTo: widget.karyawanData['outletId'])
                .where('orderStatus', whereIn: ['pending_payment', 'processing'])
                .snapshots(),
            builder: (context, snapshot) {
              int orderCount = 0;
              if (snapshot.hasData) {
                orderCount = snapshot.data!.docs.length;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.receipt_long),
                    tooltip: 'Pesanan Masuk',
                    onPressed: () => _showIncomingOrders(context),
                  ),
                  if (orderCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$orderCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // END ADDED
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: _showAttendanceDialog,
                tooltip: 'Absensi',
              ),
              if (hasCheckedIn && !hasCheckedOut)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  ),
                ),
              if (hasCheckedOut)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: (val) {
              setState(() {
                _filteredProducts = _allProducts
                    .where((p) =>
                p['name'].toString().toLowerCase().contains(val.toLowerCase()) &&
                    (_selectedCategoryId == 'all' || p['categoryId'] == _selectedCategoryId))
                    .toList();
              });
            },
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildMobileCategoryChip('all', 'Semua'),
              ..._categories.map((cat) => _buildMobileCategoryChip(cat['id'] ?? '', cat['name'] ?? 'No Name')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredProducts.isEmpty
              ? const Center(child: Text("Tidak ada produk"))
              : GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Total", style: TextStyle(fontSize: 12)),
                  Text(
                    _currencyFormat.format(_total),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showMobileCartSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.shopping_cart),
                label: Text('Keranjang (${_cartItems.length})'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[100],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  color: Colors.white,
                  child: const Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildCategoryTile('all', 'Semua Produk'),
                      ..._categories.map((cat) => _buildCategoryTile(cat['id'] ?? '', cat['name'] ?? 'No Name')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filteredProducts = _allProducts
                          .where((p) =>
                      p['name'].toString().toLowerCase().contains(val.toLowerCase()) &&
                          (_selectedCategoryId == 'all' || p['categoryId'] == _selectedCategoryId))
                          .toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: _filteredProducts.isEmpty
                    ? const Center(child: Text("Tidak ada produk"))
                    : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                  child: const Text('Keranjang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return Card(
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          title: Text(item['nama'], maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(_currencyFormat.format(item['harga'] * item['quantity'])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _decrementQuantity(index),
                                constraints: const BoxConstraints(),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('${item['quantity']}'),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline, color: _primaryColor),
                                onPressed: () => _incrementQuantity(index),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildCartSummary(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCategoryChip(String id, String name) {
    final bool isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        selectedColor: _primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? _primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) _filterProducts(id);
        },
      ),
    );
  }

  Widget _buildCategoryTile(String id, String name) {
    final bool isSelected = _selectedCategoryId == id;
    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? _primaryColor : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white,
      onTap: () => _filterProducts(id),
      leading: isSelected ? Icon(Icons.check_circle, size: 18, color: _primaryColor) : null,
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final double price = (product['sellingPrice'] ?? 0).toDouble();
    final String? imageUrl = product['imageUrl'];
    final int stock = product['stok'] ?? 0;
    final bool isOutOfStock = stock <= 0;

    return Card(
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: isOutOfStock ? null : () => _addToCart(product),
            child: Opacity(
              opacity: isOutOfStock ? 0.5 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          width: double.infinity,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey[100],
                      width: double.infinity,
                      child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'] ?? '-',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _currencyFormat.format(price),
                                style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Stok: $stock',
                              style: TextStyle(
                                color: isOutOfStock ? Colors.red : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOutOfStock)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Text(
                    'HABIS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.discount, size: 20, color: Colors.orange),
              const SizedBox(width: 8),
              if (_appliedCoupon != null) ...[
                Expanded(
                  child: Text(
                    "Kupon: ${_appliedCoupon!['kodeKupon']} (${_appliedCoupon!['tipeNilai'] == 'percent' ? '${_appliedCoupon!['nilai']}%' : _currencyFormat.format(_appliedCoupon!['nilai'])})",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: _removeCoupon,
                  tooltip: "Hapus Kupon",
                )
              ] else ...[
                const Text("Punya Kupon?", style: TextStyle(fontSize: 14)),
                const Spacer(),
                TextButton(onPressed: _showCouponDialog, child: const Text("Gunakan Kupon"))
              ]
            ],
          ),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Subtotal'),
            Text(_currencyFormat.format(_subtotal))
          ]),
          if (_appliedCoupon != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Diskon', style: TextStyle(color: Colors.green)),
                Text('- ${_currencyFormat.format(_discount)}', style: const TextStyle(color: Colors.green)),
              ]),
            ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Pajak (10%)'),
            Text(_currencyFormat.format(_pajak))
          ]),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(_currencyFormat.format(_total),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor))
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _showPaymentDialog,
              child: const Text('Konfirmasi Bayar'),
            ),
          ),
        ],
      ),
    );
  }
}

class WebPaymentStatusDialog extends StatefulWidget {
  final String orderId;
  final ApiService apiService;
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback onSuccess;
  final VoidCallback onFailed;

  const WebPaymentStatusDialog({
    super.key,
    required this.orderId,
    required this.apiService,
    required this.cartItems,
    required this.onSuccess,
    required this.onFailed,
  });

  @override
  State<WebPaymentStatusDialog> createState() => _WebPaymentStatusDialogState();
}

class _WebPaymentStatusDialogState extends State<WebPaymentStatusDialog> {
  bool _isChecking = false;
  String _statusMessage = 'Menunggu pembayaran...';
  bool _hasResult = false;
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Status Pembayaran", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  if (_isSuccess)
                    const Icon(Icons.check_circle, color: Colors.green, size: 50)
                  else if (_hasResult && !_isSuccess)
                    const Icon(Icons.error, color: Colors.red, size: 50)
                  else
                    const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A3A3))),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _isSuccess ? FontWeight.bold : FontWeight.normal,
                      color: _hasResult ? (_isSuccess ? Colors.green : Colors.red) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_hasResult)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSuccess ? const Color(0xFF00A3A3) : Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isSuccess ? widget.onSuccess : widget.onFailed,
                        child: Text(_isSuccess ? 'Selesai' : 'Tutup / Coba Lagi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (!_hasResult)
                    TextButton(onPressed: widget.onFailed, child: const Text("Batalkan / Tutup", style: TextStyle(color: Colors.grey)))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startPollingStatus();
  }

  Future<void> _startPollingStatus() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    int attempts = 0;
    const int maxAttempts = 24;

    while (attempts < maxAttempts && mounted && !_hasResult) {
      try {
        await Future.delayed(const Duration(seconds: 5));

        final statusData = await widget.apiService.checkTransactionStatus(widget.orderId);

        if (statusData != null) {
          final String status = statusData['transactionStatus'] ?? statusData['status'] ?? 'pending';

          if (status == 'settlement' || status == 'capture' || status == 'success') {
            if (mounted) {
              setState(() {
                _isSuccess = true;
                _hasResult = true;
                _statusMessage = "Pembayaran Berhasil!";
              });
            }
            return;
          } else if (status == 'expire' || status == 'cancel' || status == 'deny' || status == 'failure') {
            if (mounted) {
              setState(() {
                _isSuccess = false;
                _hasResult = true;
                _statusMessage = "Pembayaran Gagal atau Kadaluarsa.";
              });
            }
            return;
          }
        }
      } catch (e) {
        print("Polling error: $e");
      }
      attempts++;
    }

    if (mounted && !_hasResult) {
      setState(() {
        _isSuccess = false;
        _hasResult = true;
        _statusMessage = "Waktu tunggu habis. Silakan cek status secara manual.";
      });
    }
  }
}