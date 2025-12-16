import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientTransactionId TEXT UNIQUE NOT NULL,
        grossAmount REAL NOT NULL,
        items TEXT NOT NULL,
        tax REAL NOT NULL,
        customerName TEXT NOT NULL,
        customerPhone TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        karyawanId TEXT NOT NULL,
        outletId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL,
        syncAttempts INTEGER DEFAULT 0,
        lastSyncAttempt TEXT,
        errorMessage TEXT
      )
    ''');
  }

  Future<String> insertPendingTransaction({
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
    final db = await database;

    final data = {
      'clientTransactionId': clientTransactionId,
      'grossAmount': grossAmount,
      'items': jsonEncode(items),
      'tax': tax,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'paymentMethod': paymentMethod,
      'karyawanId': karyawanId,
      'outletId': outletId,
      'createdAt': DateTime.now().toIso8601String(),
      'syncStatus': 'pending',
      'syncAttempts': 0,
    };

    await db.insert('pending_transactions', data);
    return clientTransactionId;
  }

  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final db = await database;
    final results = await db.query(
      'pending_transactions',
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt ASC',
    );

    return results.map((row) {
      final Map<String, dynamic> transaction = Map.from(row);
      transaction['items'] = jsonDecode(row['items'] as String);
      return transaction;
    }).toList();
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pending_transactions WHERE syncStatus = ?',
      ['pending'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateSyncStatus({
    required String clientTransactionId,
    required String status,
    String? errorMessage,
  }) async {
    final db = await database;
    await db.update(
      'pending_transactions',
      {
        'syncStatus': status,
        'syncAttempts': status == 'synced' ? 0 : 1,
        'lastSyncAttempt': DateTime.now().toIso8601String(),
        'errorMessage': errorMessage,
      },
      where: 'clientTransactionId = ?',
      whereArgs: [clientTransactionId],
    );
  }

  Future<void> incrementSyncAttempts(String clientTransactionId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_transactions SET syncAttempts = syncAttempts + 1, lastSyncAttempt = ? WHERE clientTransactionId = ?',
      [DateTime.now().toIso8601String(), clientTransactionId],
    );
  }

  Future<void> deleteSyncedTransaction(String clientTransactionId) async {
    final db = await database;
    await db.delete(
      'pending_transactions',
      where: 'clientTransactionId = ? AND syncStatus = ?',
      whereArgs: [clientTransactionId, 'synced'],
    );
  }

  Future<void> deleteAllSynced() async {
    final db = await database;
    await db.delete(
      'pending_transactions',
      where: 'syncStatus = ?',
      whereArgs: ['synced'],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}