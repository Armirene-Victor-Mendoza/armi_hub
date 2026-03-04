import 'package:armi_hub/features/order_creation/domain/entities/scanned_order.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class OrdersLocalDataSource {
  OrdersLocalDataSource();

  static const String _databaseName = 'armi_hub.db';
  static const int _databaseVersion = 4;
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
            business_name TEXT,
            store_name TEXT,
            total_value REAL NOT NULL,
            payment_method INTEGER NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            address TEXT NOT NULL,
            phone TEXT NOT NULL,
            city TEXT NOT NULL,
            ocr_raw_text TEXT NOT NULL,
            ocr_total REAL,
            receipt_image_path TEXT NOT NULL,
            request_json TEXT NOT NULL,
            url_image TEXT,
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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE $tableName ADD COLUMN city TEXT NOT NULL DEFAULT ''");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE $tableName ADD COLUMN url_image TEXT");
        }
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE $tableName ADD COLUMN business_name TEXT");
          await db.execute("ALTER TABLE $tableName ADD COLUMN store_name TEXT");
        }
      },
    );
    await _ensureRequiredColumns(_database!);

    return _database!;
  }

  Future<void> _ensureRequiredColumns(Database db) async {
    await _ensureColumn(db, columnName: 'city', definition: "TEXT NOT NULL DEFAULT ''");
    await _ensureColumn(db, columnName: 'url_image', definition: 'TEXT');
    await _ensureColumn(db, columnName: 'business_name', definition: 'TEXT');
    await _ensureColumn(db, columnName: 'store_name', definition: 'TEXT');
  }

  Future<void> _ensureColumn(
    Database db, {
    required String columnName,
    required String definition,
  }) async {
    final existingColumns = await db.rawQuery('PRAGMA table_info($tableName)');
    final hasColumn = existingColumns.any((column) => column['name'] == columnName);
    if (hasColumn) return;

    await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $definition');
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
