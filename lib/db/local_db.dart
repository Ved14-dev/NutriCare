import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart';
import '../models/food_entry.dart';

class LocalDB {
    static Database? _db;

    static Future<Database> get database async {
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
        final db = await database;
        final key = Key.fromUtf8('my32lengthsupersecretnooneknows1');
        final iv = IV.fromLength(16);
        final encrypter = Encrypter(AES(key));
        final encrypted = encrypter.encrypt('Rice Bowl: 250 kcal', iv: iv);
        await db.insert('entries', {
            'name': 'Encrypted Food Entry',
            'calories': encrypted.base64.length, // demo only
        });
    }
}
