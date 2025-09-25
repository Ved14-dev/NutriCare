import 'package:flutter/material.dart';
import '../db/local_db.dart';
import '../models/food_entry.dart';

class FoodLog extends StatefulWidget {
    @override
    _FoodLogState createState() => _FoodLogState();
}

class _FoodLogState extends State<FoodLog> {
    List<FoodEntry> entries = [];

    @override
    void initState() {
        super.initState();
        _loadEntries();
    }

    Future<void> _loadEntries() async {
        entries = await LocalDB.getEntries();
        setState(() {});
    }

    Future<void> _addEntry() async {
        await LocalDB.insertMockEncryptedEntry();
        await _loadEntries();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('My Food Log')),
            body: Column(
                children: [
                    Expanded(
                        child: ListView.builder(
                            itemCount: entries.length,
                            itemBuilder: (ctx, i) => ListTile(
                                leading: Icon(Icons.fastfood),
                                title: Text(entries[i].name),
                                subtitle: Text('${entries[i].calories} kcal'),
                            ),
                        ),
                    ),
                    Padding(
                        padding: EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('Add Mock Entry'),
                            onPressed: _addEntry,
                        ),
                    ),
                ],
            ),
        );
    }
}
