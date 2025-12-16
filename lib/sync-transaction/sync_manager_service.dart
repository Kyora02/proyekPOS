import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_database_service.dart';
import '../service/api_service.dart';

class SyncManagerService {
  static final SyncManagerService instance = SyncManagerService._init();

  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  SyncManagerService._init();

  void startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((result) =>
      result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet);

      if (hasConnection && !_isSyncing) {
        print("🌐 Koneksi terdeteksi, mencoba sinkronisasi...");
        Future.delayed(const Duration(seconds: 3), () {
          syncPendingTransactions();
        });
      }
    });
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) =>
    result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  Future<void> syncPendingTransactions() async {
    if (_isSyncing) return;

    final online = await isOnline();
    if (!online) return;

    _isSyncing = true;

    try {
      final pendingTransactions = _localDb.getPendingTransactions();

      if (pendingTransactions.isEmpty) {
        _isSyncing = false;
        return;
      }

      _syncStatusController.add(SyncStatus(
        isActive: true,
        totalPending: pendingTransactions.length,
        successCount: 0,
        failedCount: 0,
        message: 'Mulai sinkronisasi ${pendingTransactions.length} transaksi...',
      ));

      int successCount = 0;
      int failedCount = 0;

      for (var transaction in pendingTransactions) {
        try {
          print("⏳ Syncing: ${transaction['clientTransactionId']}");

          final result = await _apiService.syncOfflineTransaction(
            clientTransactionId: transaction['clientTransactionId'],
            amount: (transaction['grossAmount'] as num).toDouble(),
            // Pastikan items dikirim sebagai List<Map>
            items: List<Map<String, dynamic>>.from(transaction['items']),
            customerName: transaction['customerName'],
            customerPhone: transaction['customerPhone'],
            paymentMethod: transaction['paymentMethod'],
            karyawanId: transaction['karyawanId'],
            outletId: transaction['outletId'],
            createdAt: transaction['createdAt'],
          ).timeout(const Duration(seconds: 20));

          if (result['success'] == true || result['isDuplicate'] == true) {
            // Jika sukses atau duplikat (sudah ada di server), tandai synced
            await _localDb.updateSyncStatus(
              clientTransactionId: transaction['clientTransactionId'],
              status: 'synced',
            );
            successCount++;
          } else {
            throw Exception(result['message'] ?? 'Sync failed');
          }
        } catch (e) {
          failedCount++;
          print("❌ Gagal sync: $e");

          await _localDb.updateSyncStatus(
            clientTransactionId: transaction['clientTransactionId'],
            status: 'failed',
            errorMessage: e.toString(),
          );
        }

        _syncStatusController.add(SyncStatus(
          isActive: true,
          totalPending: pendingTransactions.length,
          successCount: successCount,
          failedCount: failedCount,
          message: 'Proses: $successCount Sukses, $failedCount Gagal',
        ));
      }

      await _localDb.deleteAllSynced();

      _syncStatusController.add(SyncStatus(
        isActive: false,
        totalPending: 0,
        successCount: successCount,
        failedCount: failedCount,
        message: 'Sync Selesai: $successCount terkirim.',
        isComplete: true,
        hasErrors: failedCount > 0,
      ));

    } catch (e) {
      print("Error Global Sync: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<int> getPendingCount() async {
    return _localDb.getPendingCount();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

class SyncStatus {
  final bool isActive;
  final int totalPending;
  final int successCount;
  final int failedCount;
  final String message;
  final bool isComplete;
  final bool hasErrors;

  SyncStatus({
    required this.isActive,
    required this.totalPending,
    required this.successCount,
    required this.failedCount,
    required this.message,
    this.isComplete = false,
    this.hasErrors = false,
  });
}