import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class OrdersLocalDataSource {
  OrdersLocalDataSource();

  static const String _databaseName = 'armi_hub.db';
  static const int _databaseVersion = 1;
  static const String tableName = 'scanned_orders';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final fullPath = path.join(databasesPath, _databaseName);

    _database = await openDatabase(
      fullPath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            business_id INTEGER NOT NULL,
            store_id TEXT NOT NULL,
            total_value REAL NOT NULL,
            payment_method INTEGER NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            address TEXT NOT NULL,
            phone TEXT NOT NULL,
            ocr_raw_text TEXT NOT NULL,
            ocr_total REAL,
            receipt_image_path TEXT NOT NULL,
            request_json TEXT NOT NULL,
            response_status_code INTEGER,
            response_body_raw TEXT,
            status TEXT NOT NULL,
            error_message TEXT
          )
        ''');

        await db.execute('CREATE INDEX idx_scanned_orders_created_at ON $tableName(created_at)');
        await db.execute('CREATE INDEX idx_scanned_orders_status ON $tableName(status)');
        await db.execute('CREATE INDEX idx_scanned_orders_business_store ON $tableName(business_id, store_id)');
      },
    );

    return _database!;
  }

  Future<void> upsertOrder(ScannedOrder order) async {
    final db = await database;
    await db.insert(
      tableName,
      order.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ScannedOrder?> getOrderById(String id) async {
    final db = await database;
    final rows = await db.query(tableName, where: 'id = ?', whereArgs: <Object>[id], limit: 1);

    if (rows.isEmpty) return null;
    return ScannedOrder.fromMap(rows.first);
  }

  Future<List<ScannedOrder>> getOrderHistory({String? status}) async {
    final db = await database;
    final rows = await db.query(
      tableName,
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : <Object>[status],
      orderBy: 'created_at DESC',
    );

    return rows.map(ScannedOrder.fromMap).toList();
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
