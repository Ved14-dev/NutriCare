import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db/local_db.dart';
import '../models/food_entry.dart';
import '../widgets/app_scaffold.dart';

class FoodLog extends StatefulWidget {
    const FoodLog({super.key});

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
        return AppScaffold(
            title: 'My Food Log',
            child: Column(
                children: [
                    Expanded(
                                    child: entries.isEmpty
                                            ? Center(child: Text('No entries yet', style: GoogleFonts.inter()))
                                            : ListView.builder(
                                        padding: const EdgeInsets.all(12),
                                        itemCount: entries.length,
                                        itemBuilder: (ctx, i) => Card(
                                                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    elevation: 2,
                                                    surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                                                    child: ListTile(
                                                                    leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.secondaryContainer, child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 20)),
                                                        title: Text(entries[i].name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                                        subtitle: Text('${entries[i].calories} kcal', style: GoogleFonts.inter()),
                                                    ),
                                                ),
                                    ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(16),
                                    child: SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                            icon: const Icon(Icons.add, size: 20),
                                            label: Text('Add Mock Entry', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                                            onPressed: _addEntry,
                                        ),
                                    ),
                    ),
                ],
            ),
        );
    }
}
