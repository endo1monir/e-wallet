import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wallet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        number TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wallet_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertWallet(Map<String, dynamic> wallet) async {
    final db = await database;
    return db.insert('wallets', wallet);
  }

  Future<int> updateWallet(Map<String, dynamic> wallet) async {
    final db = await database;
    final id = wallet['id'] as int;
    return db.update('wallets', wallet, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteWallet(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'wallet_id = ?', whereArgs: [id]);
    return db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getWallets() async {
    final db = await database;
    return db.query('wallets', orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> getWallet(int id) async {
    final db = await database;
    final result = await db.query('wallets', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return db.insert('transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getTransactions(int walletId) async {
    final db = await database;
    return db.query('transactions',
        where: 'wallet_id = ?',
        whereArgs: [walletId],
        orderBy: 'id DESC');
  }

  Future<int> deleteTransactions(int walletId) async {
    final db = await database;
    return db.delete('transactions',
        where: 'wallet_id = ?', whereArgs: [walletId]);
  }

  Future<void> updateBalance(int walletId, double balance) async {
    final db = await database;
    await db.update('wallets', {'balance': balance},
        where: 'id = ?', whereArgs: [walletId]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
