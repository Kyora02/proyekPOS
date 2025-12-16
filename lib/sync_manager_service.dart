import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_database_service.dart';
import 'service/api_service.dart';

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
          result == ConnectivityResult.ethernet
      );

      if (hasConnection && !_isSyncing) {
        Future.delayed(const Duration(seconds: 2), () {
          syncPendingTransactions();
        });
      }
    });
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) =>
    result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
    );
  }

  Future<void> syncPendingTransactions() async {
    if (_isSyncing) return;

    final online = await isOnline();
    if (!online) return;

    _isSyncing = true;

    try {
      final pendingTransactions = await _localDb.getPendingTransactions();

      if (pendingTransactions.isEmpty) {
        _isSyncing = false;
        return;
      }

      _syncStatusController.add(SyncStatus(
        isActive: true,
        totalPending: pendingTransactions.length,
        successCount: 0,
        failedCount: 0,
        message: 'Sinkronisasi dimulai...',
      ));

      int successCount = 0;
      int failedCount = 0;
      List<String> failedReasons = [];

      for (var transaction in pendingTransactions) {
        try {
          final result = await _syncSingleTransaction(transaction);

          if (result['success'] == true) {
            successCount++;
            _syncStatusController.add(SyncStatus(
              isActive: true,
              totalPending: pendingTransactions.length,
              successCount: successCount,
              failedCount: failedCount,
              message: 'Berhasil: $successCount/${pendingTransactions.length}',
            ));
          } else if (result['isDuplicate'] == true) {
            await _localDb.updateSyncStatus(
              clientTransactionId: transaction['clientTransactionId'],
              status: 'synced',
            );
            successCount++;
            _syncStatusController.add(SyncStatus(
              isActive: true,
              totalPending: pendingTransactions.length,
              successCount: successCount,
              failedCount: failedCount,
              message: 'Duplikat diabaikan: $successCount/${pendingTransactions.length}',
            ));
          } else {
            throw Exception(result['message'] ?? 'Sync failed');
          }

        } catch (e) {
          failedCount++;
          final reason = e.toString();
          failedReasons.add(reason);

          String errorMessage = reason;
          if (reason.contains('SocketException') || reason.contains('Network')) {
            errorMessage = 'Koneksi bermasalah, akan dicoba lagi nanti';
          } else if (reason.contains('Stock') || reason.contains('stok')) {
            errorMessage = 'Stok tidak mencukupi';
          }

          await _localDb.updateSyncStatus(
            clientTransactionId: transaction['clientTransactionId'],
            status: 'failed',
            errorMessage: errorMessage,
          );

          _syncStatusController.add(SyncStatus(
            isActive: true,
            totalPending: pendingTransactions.length,
            successCount: successCount,
            failedCount: failedCount,
            message: 'Gagal: $failedCount',
          ));
        }
      }

      final String finalMessage = successCount > 0
          ? 'Sinkronisasi selesai: $successCount berhasil${failedCount > 0 ? ', $failedCount gagal' : ''}'
          : 'Sinkronisasi gagal untuk semua transaksi';

      _syncStatusController.add(SyncStatus(
        isActive: false,
        totalPending: 0,
        successCount: successCount,
        failedCount: failedCount,
        message: finalMessage,
        isComplete: true,
        hasErrors: failedCount > 0,
      ));

    } catch (e) {
      _syncStatusController.add(SyncStatus(
        isActive: false,
        totalPending: 0,
        successCount: 0,
        failedCount: 0,
        message: 'Error sinkronisasi: ${e.toString()}',
        isComplete: true,
        hasErrors: true,
      ));
    } finally {
      _isSyncing = false;
      await _localDb.deleteAllSynced();
    }
  }

  Future<Map<String, dynamic>> _syncSingleTransaction(Map<String, dynamic> transaction) async {
    await _localDb.incrementSyncAttempts(transaction['clientTransactionId']);

    try {
      final result = await _apiService.syncOfflineTransaction(
        clientTransactionId: transaction['clientTransactionId'],
        amount: transaction['grossAmount'],
        items: transaction['items'],
        customerName: transaction['customerName'],
        customerPhone: transaction['customerPhone'],
        paymentMethod: transaction['paymentMethod'],
        karyawanId: transaction['karyawanId'],
        outletId: transaction['outletId'],
        createdAt: transaction['createdAt'],
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - koneksi lambat');
        },
      );

      if (result['success'] == true) {
        await _localDb.updateSyncStatus(
          clientTransactionId: transaction['clientTransactionId'],
          status: 'synced',
        );
        return {'success': true};
      } else if (result['isDuplicate'] == true) {
        return {'success': true, 'isDuplicate': true};
      } else {
        throw Exception(result['message'] ?? 'Sync failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<int> getPendingCount() async {
    return await _localDb.getPendingCount();
  }

  void dispose() {
    stopListening();
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