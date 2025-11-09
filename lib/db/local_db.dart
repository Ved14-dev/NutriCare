import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/food_entry.dart';

class LocalDB {
    static Database? _db;
    // Simple in-memory fallback for web where sqflite is not available.
    static final List<FoodEntry> _webEntries = <FoodEntry>[];

    static Future<Database> get database async {
        if (kIsWeb) {
            // sqflite (native filesystem DB) isn't available on the web.
            // Callers should use Firestore or another web-friendly store, but
            // return a helpful error if they attempt to access the database
            // directly. Higher-level methods use a web in-memory fallback.
            throw UnsupportedError('LocalDB.database is not available on web. Use getEntries() or other web-safe APIs.');
        }

        if (_db != null) return _db!;
        _db = await openDatabase(
            join(await getDatabasesPath(), 'nutricare.db'),
            onCreate: (db, version) {
                return db.execute(
                    'CREATE TABLE entries(id INTEGER PRIMARY KEY, name TEXT, calories INTEGER)',
                );
            },
            version: 1,
        );
        return _db!;
    }

    static Future<List<FoodEntry>> getEntries() async {
        if (kIsWeb) {
            // Return a lightweight in-memory list for web. This avoids
            // calling sqflite APIs which aren't supported in browsers.
            return List<FoodEntry>.from(_webEntries);
        }

        final db = await database;
        final maps = await db.query('entries');
        return List.generate(maps.length, (i) {
            return FoodEntry(
                id: maps[i]['id'] as int,
                name: maps[i]['name'] as String,
                calories: maps[i]['calories'] as int,
            );
        });
    }

    static Future<void> insertMockEncryptedEntry() async {
        if (kIsWeb) {
            // Add a mock entry to the in-memory list on web.
            _webEntries.add(FoodEntry(id: null, name: 'Encrypted Food Entry', calories: 250));
            return;
        }

        final db = await database;
    final key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt('Rice Bowl: 250 kcal', iv: iv);
        await db.insert('entries', {
            'name': 'Encrypted Food Entry',
            'calories': encrypted.base64.length, // demo only
        });
    }
}
