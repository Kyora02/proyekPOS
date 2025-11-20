import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class PaymentWebviewPage extends StatefulWidget {
  final String url;
  final String orderId;

  const PaymentWebviewPage({
    super.key,
    required this.url,
    required this.orderId,
  });

  @override
  State<PaymentWebviewPage> createState() => _PaymentWebviewPageState();
}

class _PaymentWebviewPageState extends State<PaymentWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  bool _hasReturnedResult = false;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
              });
            }
            _checkUrlForCompletion(url);
          },
          onPageFinished: (String url) {
            print('Page finished: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
            }
            _checkUrlForCompletion(url);
          },
          onWebResourceError: (WebResourceError error) {
            print("WebView Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) async {
            print('Navigation request: ${request.url}');

            _checkUrlForCompletion(request.url);

            // Handle external apps (GoPay, ShopeePay, etc.)
            if (!request.url.startsWith('http://') &&
                !request.url.startsWith('https://') &&
                !request.url.startsWith('about:blank') &&
                !request.url.startsWith('data:')) {

              final Uri uri = Uri.parse(request.url);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                print('Could not launch ${request.url}: $e');
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _checkUrlForCompletion(String url) {
    if (_hasReturnedResult) return;

    final lowerUrl = url.toLowerCase();

    print('Checking URL: $lowerUrl');

    bool isSuccess =
    lowerUrl.contains('status_code=200') ||
        lowerUrl.contains('transaction_status=settlement') ||
        lowerUrl.contains('transaction_status=capture') ||
        lowerUrl.contains('transaction_status=success') ||
        lowerUrl.contains('/success') ||
        lowerUrl.contains('payment_successful') ||
        lowerUrl.contains('payment-successful') ||
        lowerUrl.contains('payment_success') ||
        (lowerUrl.contains('order_id=${widget.orderId.toLowerCase()}') &&
            (lowerUrl.contains('settlement') ||
                lowerUrl.contains('success') ||
                lowerUrl.contains('status_code=200'))) ||
        (lowerUrl.contains('finish') && !lowerUrl.contains('unfinish')) ||
        lowerUrl.contains('/payment/success') ||
        lowerUrl.contains('/transaction/success');

    bool isFailed =
        lowerUrl.contains('status_code=201') ||
            lowerUrl.contains('status_code=202') ||
            lowerUrl.contains('transaction_status=deny') ||
            lowerUrl.contains('transaction_status=cancel') ||
            lowerUrl.contains('transaction_status=expire') ||
            lowerUrl.contains('transaction_status=failure') ||
            lowerUrl.contains('/unfinish') ||
            lowerUrl.contains('/error') ||
            lowerUrl.contains('payment_failed') ||
            lowerUrl.contains('payment-failed');

    if (isSuccess) {
      print('✅ Payment SUCCESS detected for order: ${widget.orderId}');
      _showSuccessDialog();
    } else if (isFailed) {
      print('❌ Payment FAILED detected for order: ${widget.orderId}');
      _returnResult(false);
    }
  }

  void _showSuccessDialog() {
    if (_hasReturnedResult) return;
    _hasReturnedResult = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Transaksi Anda telah berhasil diproses.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    _autoCloseTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(true);
      }
    });
  }

  void _returnResult(bool isSuccess) {
    if (_hasReturnedResult) return;

    _hasReturnedResult = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context, isSuccess);
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (_hasReturnedResult) return false;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pembayaran?'),
        content: const Text(
            'Apakah Anda yakin ingin membatalkan pembayaran?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (_hasReturnedResult) return;

              final shouldClose = await _onWillPop();
              if (shouldClose && mounted) {
                Navigator.pop(context, false);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _controller.reload();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Memuat halaman pembayaran...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}