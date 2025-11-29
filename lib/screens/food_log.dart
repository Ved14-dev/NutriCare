import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ...existing code...
import '../widgets/app_scaffold.dart';

class FoodLog extends StatefulWidget {
    const FoodLog({super.key});

    @override
    _FoodLogState createState() => _FoodLogState();
}

class _FoodLogState extends State<FoodLog> {
    // We'll use Firestore stream for entries.

    @override
    Widget build(BuildContext context) {
        return AppScaffold(
            title: 'My Food Log',
            floatingActionButton: FloatingActionButton(onPressed: () => _showAddFoodDialog(context), child: const Icon(Icons.add)),
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text('Food Log', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: (() {
                                final u = FirebaseAuth.instance.currentUser;
                                if (u == null) return null;
                                return FirebaseFirestore.instance.collection('users').doc(u.uid).collection('food_logs').orderBy('timestamp', descending: true).snapshots();
                            })(),
                            builder: (context, snap) {
                                if (snap.hasError) return Center(child: Text('Error loading food logs'));
                                if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                                final docs = snap.data!.docs;
                                if (docs.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Text('No food logs yet — tap + to add', style: GoogleFonts.inter())));

                                return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: docs.length,
                                    itemBuilder: (ctx, i) {
                                        final d = docs[i].data();
                                        final name = (d['name'] as String?) ?? 'Food';
                                        final calories = d['calories']?.toString() ?? '0';
                                        final qty = d['quantity']?.toString() ?? '1';
                                        final note = (d['note'] as String?) ?? '';
                                        final date = (d['date'] as String?) ?? '';
                                        final day = (d['day'] as String?) ?? '';
                                        return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            child: ListTile(
                                                leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.fastfood, size: 20)),
                                                title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                                subtitle: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        Text('$calories kcal • qty $qty', style: GoogleFonts.inter()),
                                                        if (note.isNotEmpty) Text(note, style: GoogleFonts.inter()),
                                                        const SizedBox(height: 6),
                                                        Text('Day: $day • Date: $date', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                                                    ],
                                                ),
                                            ),
                                        );
                                    });
                            },
                        ),
                        const SizedBox(height: 32),
                        const SizedBox(height: 16),
                    ],
                ),
            ),
        );
    }

    void _showAddFoodDialog(BuildContext context) {
        final nameCtrl = TextEditingController();
        final calCtrl = TextEditingController();
        final qtyCtrl = TextEditingController(text: '1');
        final noteCtrl = TextEditingController();

        showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
                title: const Text('Add Food Item'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                        TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories')),
                        TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
                        TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
                    ]),
                ),
                actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    FilledButton(onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final calories = int.tryParse(calCtrl.text.trim()) ?? 0;
                        final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                        final note = noteCtrl.text.trim();
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final now = DateTime.now();
                        final formattedDate = '${now.day}-${now.month}-${now.year}';
                        final weekdayName = DateFormat('EEEE').format(now);

                        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('food_logs').add({
                            'name': name,
                            'calories': calories,
                            'quantity': qty,
                            'note': note,
                            'timestamp': now,
                            'date': formattedDate,
                            'day': weekdayName,
                            'userId': user.uid,
                        });

                        if (context.mounted) Navigator.of(ctx).pop();
                    }, child: const Text('Save')),
                ],
            ),
        );
    }
}
