import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();

  static const String _boxName = 'pending_transactions';

  LocalDatabaseService._init();

  Box get _box {
    return Hive.box(_boxName);
  }

  Future<void> insertPendingTransaction({
    required String clientTransactionId,
    required double grossAmount,
    required List<Map<String, dynamic>> items,
    required double tax,
    required String customerName,
    required String customerPhone,
    required String paymentMethod,
    required String karyawanId,
    required String outletId,
  }) async {
    final data = {
      'clientTransactionId': clientTransactionId,
      'grossAmount': grossAmount,
      'items': items,
      'tax': tax,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'paymentMethod': paymentMethod,
      'karyawanId': karyawanId,
      'outletId': outletId,
      'createdAt': DateTime.now().toIso8601String(),
      'syncStatus': 'pending',
      'syncAttempts': 0,
      'errorMessage': '',
    };

    await _box.put(clientTransactionId, data);
  }

  List<Map<String, dynamic>> getPendingTransactions() {
    final allData = _box.values.toList();

    final pending = allData.where((item) {
      if (item is! Map) return false;
      final mapItem = Map<String, dynamic>.from(item);
      return mapItem['syncStatus'] == 'pending' || mapItem['syncStatus'] == 'failed';
    }).map((item) => Map<String, dynamic>.from(item as Map)).toList();

    pending.sort((a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String));

    return pending;
  }

  /// Menghitung jumlah antrian sync
  int getPendingCount() {
    return getPendingTransactions().length;
  }

  Future<void> updateSyncStatus({
    required String clientTransactionId,
    required String status,
    String? errorMessage,
  }) async {
    final rawData = _box.get(clientTransactionId);
    if (rawData != null) {
      final data = Map<String, dynamic>.from(rawData as Map);
      data['syncStatus'] = status;
      data['lastSyncAttempt'] = DateTime.now().toIso8601String();
      if (errorMessage != null) {
        data['errorMessage'] = errorMessage;
      }
      if (status == 'synced') {
        data['syncAttempts'] = 0;
      } else {
        data['syncAttempts'] = (data['syncAttempts'] ?? 0) + 1;
      }

      await _box.put(clientTransactionId, data);
    }
  }

  Future<void> deleteSyncedTransaction(String clientTransactionId) async {
    await _box.delete(clientTransactionId);
  }

  Future<void> deleteAllSynced() async {
    final keysToDelete = <String>[];

    for (var i = 0; i < _box.length; i++) {
      final item = _box.getAt(i);
      if (item != null && item is Map) {
        final mapItem = Map<String, dynamic>.from(item);
        if (mapItem['syncStatus'] == 'synced') {
          if (mapItem['clientTransactionId'] != null) {
            keysToDelete.add(mapItem['clientTransactionId']);
          }
        }
      }
    }

    await _box.deleteAll(keysToDelete);
  }
}