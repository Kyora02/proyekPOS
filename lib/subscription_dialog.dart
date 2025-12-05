import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:proyekpos2/service/api_service.dart';
import 'package:proyekpos2/payment/payment_webview_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class SubscriptionDialog extends StatefulWidget {
  final String userId;

  const SubscriptionDialog({super.key, required this.userId});

  @override
  State<SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Timer? _statusCheckTimer;
  String? _currentOrderId;

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _startWebStatusPolling(String orderId) async {
    setState(() => _isLoading = true);

    int attempts = 0;
    const maxAttempts = 60;

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;

      if (attempts > maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waktu pengecekan habis. Silakan cek status pembayaran secara manual.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      try {
        final result = await _apiService.checkSubscriptionStatus(orderId: orderId);

        if (result['status'] == 'success') {
          timer.cancel();
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription berhasil diaktifkan!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (result['status'] == 'failed') {
          timer.cancel();
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pembayaran gagal atau dibatalkan'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error checking status: $e');
      }
    });
  }

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

      _currentOrderId = orderId;

      if (kIsWeb) {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(
            Uri.parse(url),
            webOnlyWindowName: '_blank',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Halaman pembayaran dibuka di tab baru. Mohon selesaikan pembayaran.'),
              duration: Duration(seconds: 4),
            ),
          );

          await _startWebStatusPolling(orderId);
        }
      } else {
        final paymentResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebviewPage(
              url: url,
              orderId: orderId,
            ),
          ),
        );

        if (mounted) {
          if (paymentResult == true) {
            await Future.delayed(const Duration(seconds: 1));

            final statusResult = await _apiService.checkSubscriptionStatus(orderId: orderId);

            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(statusResult['status'] == 'success'
                    ? 'Subscription berhasil diaktifkan!'
                    : 'Pembayaran sedang diproses...'),
                backgroundColor: statusResult['status'] == 'success' ? Colors.green : Colors.orange,
              ),
            );
          } else {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pembayaran dibatalkan atau gagal'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
                        ? 'Menunggu pembayaran...\nSilakan selesaikan pembayaran di tab lain'
                        : 'Memproses pembayaran...',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  if (kIsWeb && _currentOrderId != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        _statusCheckTimer?.cancel();
                        setState(() => _isLoading = false);
                      },
                      child: const Text('Batalkan Pengecekan'),
                    ),
                  ],
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
                _statusCheckTimer?.cancel();
                Navigator.pop(context);
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