import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:proyekpos2/service/api_service.dart';
import '../../registration/login_page.dart';
import '../../payment/payment_webview_page.dart';

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
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _availableCoupons = [];
  Map<String, dynamic>? _appliedCoupon;

  bool _isLoading = true;
  String _selectedCategoryId = 'all';
  String _selectedPaymentMethod = 'QRIS';
  String? _currentOrderId;

  double _subtotal = 0.0;
  double _pajak = 0.0;
  double _discount = 0.0;
  double _total = 0.0;
  final double _pajakRate = 0.10;

  final Color _primaryColor = const Color(0xFF00A3A3);
  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
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

  void _filterProducts(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      if (categoryId == 'all') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts =
            _allProducts.where((p) => p['categoryId'] == categoryId).toList();
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                    const Text(
                      'Pilih Kupon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cek'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Kupon Tersedia:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                _availableCoupons.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Tidak ada kupon aktif saat ini."),
                )
                    : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableCoupons.length,
                    itemBuilder: (context, index) {
                      final coupon = _availableCoupons[index];
                      final bool isPercent = coupon['tipeNilai'] == 'percent';
                      final String valueStr = isPercent
                          ? "${coupon['nilai']}%"
                          : _currencyFormat.format(coupon['nilai']);

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
                              Text(
                                valueStr,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                    fontSize: 16),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _applyCoupon(coupon);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Pakai",
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
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
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Pelanggan wajib diisi!')),
      );
      return;
    }

    if (_customerPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor Telepon wajib diisi!')),
      );
      return;
    }

    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      String apiPaymentMethod = 'Midtrans';
      if (_selectedPaymentMethod == 'EDC') apiPaymentMethod = 'EDC';
      if (_selectedPaymentMethod == 'Tunai') apiPaymentMethod = 'Tunai';

      final result = await _apiService.createTransaction(
        amount: _total,
        items: _cartItems,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
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
                builder: (context) => PaymentWebviewPage(
                  url: url,
                  orderId: orderId,
                ),
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
                const SnackBar(
                  content: Text('Status pembayaran tidak jelas. Silakan cek riwayat transaksi.'),
                ),
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
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _customerNameController.text = existingName!;
                    _showPaymentDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
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
        content: const Text(
            'Apakah Anda ingin mencoba lagi atau membatalkan transaksi ini?'
        ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                        const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(_total),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Pelanggan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Metode Pembayaran",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
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
                          _buildPaymentTab(
                              'QRIS / Online', 'QRIS', setStateDialog),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _processPayment,
                        child: const Text(
                          'Bayar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildPaymentTab(
      String label, String value, StateSetter setStateDialog) {
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
                    decoration: BoxDecoration(
                      border:
                      Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Keranjang',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
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
                            title: Text(item['nama'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(_currencyFormat.format(
                                item['harga'] * item['quantity'])),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    _decrementQuantity(index);
                                    setSheetState(() {});
                                  },
                                ),
                                Text('${item['quantity']}'),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline,
                                      color: _primaryColor),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir : $namaKaryawan'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
            },
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
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: (val) {
              setState(() {
                _filteredProducts = _allProducts
                    .where((p) =>
                p['name']
                    .toString()
                    .toLowerCase()
                    .contains(val.toLowerCase()) &&
                    (_selectedCategoryId == 'all' ||
                        p['categoryId'] == _selectedCategoryId))
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
              ..._categories.map((cat) => _buildMobileCategoryChip(
                  cat['id'] ?? '', cat['name'] ?? 'No Name')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredProducts.isEmpty
              ? const Center(child: Text("Tidak ada produk"))
              : GridView.builder(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) =>
                _buildProductCard(_filteredProducts[index]),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
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
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showMobileCartSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  child: const Text("Kategori",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildCategoryTile('all', 'Semua Produk'),
                      ..._categories.map((cat) => _buildCategoryTile(
                          cat['id'] ?? '', cat['name'] ?? 'No Name')),
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filteredProducts = _allProducts
                          .where((p) =>
                      p['name']
                          .toString()
                          .toLowerCase()
                          .contains(val.toLowerCase()) &&
                          (_selectedCategoryId == 'all' ||
                              p['categoryId'] == _selectedCategoryId))
                          .toList();
                    });
                  },
                ),
              ),
              Expanded(
                child: _filteredProducts.isEmpty
                    ? const Center(child: Text("Tidak ada produk"))
                    : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(_filteredProducts[index]),
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
                  decoration: BoxDecoration(
                      border:
                      Border(bottom: BorderSide(color: Colors.grey[300]!))),
                  child: const Text('Keranjang',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          title: Text(item['nama'],
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(_currencyFormat
                              .format(item['harga'] * item['quantity'])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () => _decrementQuantity(index),
                                constraints: const BoxConstraints(),
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('${item['quantity']}'),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: _primaryColor),
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
      leading: isSelected
          ? Icon(Icons.check_circle, size: 18, color: _primaryColor)
          : null,
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
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey[100],
                      width: double.infinity,
                      child: const Icon(Icons.fastfood,
                          size: 40, color: Colors.grey),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _currencyFormat.format(price),
                                style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                TextButton(
                  onPressed: _showCouponDialog,
                  child: const Text("Gunakan Kupon"),
                )
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
            const Text('Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(_currencyFormat.format(_total),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _primaryColor))
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Status Pembayaran",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
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
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A3A3)),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _isSuccess ? FontWeight.bold : FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                  if (!_hasResult) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Setelah selesai membayar di tab baru, klik tombol "Cek Status" di bawah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isSuccess)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onFailed();
                    },
                    child: const Text(
                      'Batalkan',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A3A3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: (_isChecking || _isSuccess) ? null : _checkStatus,
                  child: _isChecking
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Cek Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Memeriksa status pembayaran...';
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      final status = await widget.apiService.checkTransactionStatus(widget.orderId);

      if (status != null) {
        if (status['status'] == 'success' ||
            status['transactionStatus'] == 'settlement' ||
            status['transactionStatus'] == 'capture') {

          await widget.apiService.reduceStock(items: widget.cartItems);

          setState(() {
            _statusMessage = 'Pembayaran Berhasil';
            _hasResult = true;
            _isSuccess = true;
            _isChecking = false;
          });

          await Future.delayed(const Duration(seconds: 1));
          widget.onSuccess();
        } else if (status['status'] == 'pending') {
          setState(() {
            _isChecking = false;
            _statusMessage = 'Pembayaran masih diproses.\nSilakan cek kembali dalam beberapa saat.';
          });
        } else {
          setState(() {
            _statusMessage = 'Pembayaran Gagal atau Dibatalkan';
            _hasResult = true;
            _isSuccess = false;
            _isChecking = false;
          });

          await Future.delayed(const Duration(seconds: 2));
          widget.onFailed();
        }
      } else {
        setState(() {
          _isChecking = false;
          _statusMessage = 'Tidak dapat memeriksa status.\nSilakan coba lagi.';
        });
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
        _statusMessage = 'Error: ${e.toString()}\nSilakan coba lagi.';
      });
    }
  }
}