import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityMonitor extends StatefulWidget {
  final Widget child;
  final Function(bool isOnline)? onConnectivityChanged;

  const ConnectivityMonitor({
    super.key,
    required this.child,
    this.onConnectivityChanged,
  });

  @override
  State<ConnectivityMonitor> createState() => _ConnectivityMonitorState();
}

class _ConnectivityMonitorState extends State<ConnectivityMonitor> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _showBanner = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      print('Could not check connectivity status: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) =>
    result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
    );

    if (hasConnection != _isOnline) {
      setState(() {
        _isOnline = hasConnection;
        _showBanner = true;
      });

      if (widget.onConnectivityChanged != null) {
        widget.onConnectivityChanged!(hasConnection);
      }

      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showBanner = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 4,
              color: _isOnline ? Colors.green : Colors.red,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        _isOnline ? Icons.wifi : Icons.wifi_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isOnline ? 'Koneksi kembali terhubung' : 'Koneksi terputus - Mode Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () {
                          _hideTimer?.cancel();
                          setState(() {
                            _showBanner = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}