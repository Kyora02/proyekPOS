import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:proyekpos2/service/api_service.dart';
import 'package:proyekpos2/payment/payment_webview_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionDialog extends StatefulWidget {
  final String userId;
  final VoidCallback? onSubscriptionSuccess;

  const SubscriptionDialog({
    super.key,
    required this.userId,
    this.onSubscriptionSuccess,
  });

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _handleSubscribe(String type) async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.createSubscription(
        userId: widget.userId,
        subscriptionType: type,
      );

      final url = result['redirectUrl'];
      final orderId = result['orderId'];

      if (url == null || orderId == null) {
        throw Exception('URL atau Order ID tidak ditemukan dalam response');
      }

      if (kIsWeb) {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        setState(() => _isLoading = false);

        if (mounted) {
          _showWebPaymentStatusDialog(orderId);
        }
      } else {
        setState(() => _isLoading = false);

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebviewPage(
                url: url,
                orderId: orderId,
              ),
            ),
          );

          if (mounted) {
            _showMobilePaymentStatusDialog(orderId);
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showWebPaymentStatusDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionStatusDialog(
        orderId: orderId,
        apiService: _apiService,
        userId: widget.userId,
        onSuccess: () async {
          Navigator.pop(context);
          Navigator.pop(context, true);
          _showSuccessMessage('Subscription berhasil diaktifkan!');

          if (widget.onSubscriptionSuccess != null) {
            widget.onSubscriptionSuccess!();
          }
        },
        onFailed: () {
          Navigator.pop(context);
          _showRetryDialog(orderId);
        },
      ),
    );
  }

  void _showMobilePaymentStatusDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SubscriptionStatusDialog(
        orderId: orderId,
        apiService: _apiService,
        userId: widget.userId,
        onSuccess: () async {
          Navigator.pop(context);
          Navigator.pop(context, true);
          _showSuccessMessage('Subscription berhasil diaktifkan!');

          if (widget.onSubscriptionSuccess != null) {
            widget.onSubscriptionSuccess!();
          }
        },
        onFailed: () {
          Navigator.pop(context);
          _showRetryDialog(orderId);
        },
      ),
    );
  }

  void _showRetryDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Belum Berhasil'),
        content: const Text(
            'Pembayaran Anda belum berhasil atau masih diproses.\nApakah Anda ingin mengecek lagi?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
            },
            child: const Text('Batalkan'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showMobilePaymentStatusDialog(orderId);
            },
            child: const Text('Cek Lagi'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 650,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upgrade Paket Kashierku',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dapatkan akses fitur premium untuk bisnis Anda',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              Column(
                children: [
                  const CircularProgressIndicator(color: Color(0xFF279E9E)),
                  const SizedBox(height: 16),
                  Text(
                    kIsWeb
                        ? 'Membuka halaman pembayaran...'
                        : 'Memproses pembayaran...',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlanCard(
                    'PRO',
                    'Rp 25.000',
                    ['Manajemen Bahan Baku', 'Laporan Lengkap', 'Manajemen Pelanggan', 'Manajemen Karyawan'],
                    Colors.blue,
                        () => _handleSubscribe('pro'),
                  ),
                  const SizedBox(width: 16),
                  _buildPlanCard(
                    'ENTERPRISE',
                    'Rp 50.000',
                    ['Semua Fitur Pro', 'Multi-Outlet', 'Absensi & Gaji', 'Laporan Neraca'],
                    const Color(0xFF279E9E),
                        () => _handleSubscribe('enterprise'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading ? null : () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Batal',
                style: TextStyle(
                  color: _isLoading ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, String price, List<String> features, Color color, VoidCallback onTap) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('/ bulan', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 30),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: _isLoading ? null : onTap,
              child: const Text('Pilih & Bayar'),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionStatusDialog extends StatefulWidget {
  final String orderId;
  final ApiService apiService;
  final String userId;
  final VoidCallback onSuccess;
  final VoidCallback onFailed;

  const SubscriptionStatusDialog({
    super.key,
    required this.orderId,
    required this.apiService,
    required this.userId,
    required this.onSuccess,
    required this.onFailed,
  });

  @override
  State<SubscriptionStatusDialog> createState() => _SubscriptionStatusDialogState();
}

class _SubscriptionStatusDialogState extends State<SubscriptionStatusDialog> {
  bool _isChecking = false;
  String _statusMessage = 'Silakan selesaikan pembayaran QRIS di tab/halaman lain.';
  bool _hasResult = false;
  bool _isSuccess = false;
  int _checkAttempts = 0;

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
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Status Pembayaran Subscription",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  if (_isSuccess)
                    const Icon(Icons.check_circle, color: Colors.green, size: 60)
                  else if (_hasResult && !_isSuccess)
                    const Icon(Icons.error, color: Colors.red, size: 60)
                  else if (_isChecking)
                      const SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF279E9E)),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF279E9E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          size: 60,
                          color: Color(0xFF279E9E),
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
                  if (!_hasResult && !_isChecking) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Langkah-langkah:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildStep('1', 'Scan kode QR di halaman pembayaran'),
                          _buildStep('2', 'Selesaikan pembayaran di aplikasi e-wallet Anda'),
                          _buildStep('3', 'Klik tombol "Saya Sudah Bayar" di bawah'),
                        ],
                      ),
                    ),
                  ],
                  if (_checkAttempts > 0 && !_hasResult) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Pengecekan ke-$_checkAttempts',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: (_isChecking || _isSuccess) ? null : () {
                      widget.onFailed();
                    },
                    child: const Text(
                      'Batalkan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF279E9E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
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
                      'Saya Sudah Bayar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF279E9E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _statusMessage = 'Memverifikasi pembayaran Anda...';
    });

    _checkAttempts++;

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      final status = await widget.apiService.checkSubscriptionStatus(orderId: widget.orderId);

      if (!mounted) return;

      if (status != null) {
        if (status['status'] == 'success') {
          setState(() {
            _statusMessage = 'Pembayaran Berhasil!\n\nSubscription Anda telah aktif.';
            _hasResult = true;
            _isSuccess = true;
            _isChecking = false;
          });

          await Future.delayed(const Duration(seconds: 2));

          if (!mounted) return;

          widget.onSuccess();
        } else if (status['status'] == 'pending') {
          if (!mounted) return;

          setState(() {
            _isChecking = false;
            _statusMessage = 'Pembayaran masih diproses atau belum diselesaikan.\n\nSilakan selesaikan pembayaran terlebih dahulu, lalu cek kembali.';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran belum terdeteksi. Pastikan Anda telah menyelesaikan pembayaran.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (status['status'] == 'failed') {
          if (!mounted) return;

          setState(() {
            _statusMessage = 'Pembayaran Gagal atau Dibatalkan';
            _hasResult = true;
            _isSuccess = false;
            _isChecking = false;
          });

          await Future.delayed(const Duration(seconds: 2));

          if (!mounted) return;

          widget.onFailed();
        } else {
          if (!mounted) return;

          setState(() {
            _isChecking = false;
            _statusMessage = 'Status pembayaran tidak diketahui.\nSilakan coba lagi.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _statusMessage = 'Terjadi kesalahan saat memeriksa status.\nSilakan coba lagi.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}