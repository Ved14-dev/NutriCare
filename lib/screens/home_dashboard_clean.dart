import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'qr_code_screen.dart';
import '../backend/firestore_service.dart';
import '../widgets/app_scaffold.dart';
import '../backend/auth_service.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isLarge = width > 800;
    final colorScheme = Theme.of(context).colorScheme;

    Widget leftCard(BuildContext ctx) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting (reads from Firestore users/{uid})
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snap) {
                  String name = 'there';
                  if (snap.hasData && snap.data!.exists) {
                    final data = snap.data!.data() as Map<String, dynamic>?;
                    if (data != null && (data['name'] as String?)?.isNotEmpty == true) {
                      name = data['name'] as String;
                    }
                  } else if (FirebaseAuth.instance.currentUser?.displayName != null) {
                    name = FirebaseAuth.instance.currentUser!.displayName!;
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, $name', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Here is your daily summary', style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyMedium?.color)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SummaryCard(title: 'Calories', value: '1,450 kcal', color: colorScheme.secondaryContainer),
                  _SummaryCard(title: 'Meals', value: '3', color: colorScheme.tertiaryContainer),
                  _SummaryCard(title: 'Goal', value: 'Lose 0.2 kg', color: colorScheme.primaryContainer),
                ],
              ),

              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _ActionButton(icon: Icons.restaurant_menu, label: 'My Food Log', onPressed: () => Navigator.pushNamed(context, '/log')),
                  _ActionButton(icon: Icons.chat_bubble, label: 'Chat Bot', onPressed: () => Navigator.pushNamed(context, '/chat')),
                  _ActionButton(icon: Icons.qr_code, label: 'Nutritionist QR', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRCodeScreen()))),
                  _ActionButton(icon: Icons.upload_file, label: 'Upload Data', onPressed: () async {
                    await FirestoreService.sendMockFoodData();
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food data uploaded!')));
                  }),
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Ask for confirmation before signing out
                      final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                                title: const Text('Sign Out'),
                                content: const Text('Are you sure you want to sign out?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sign Out')),
                                ],
                              ));

                      if (ok == true) {
                        // Sign out Firebase first to avoid web Google Sign-In client-id assertion
                        await FirebaseAuth.instance.signOut();
                        try {
                          await AuthService.signOut();
                        } catch (_) {
                          // ignore auxiliary sign-out failures (e.g., missing web client id)
                        }
                        if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: Text('Sign out', style: GoogleFonts.inter()),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Small curated tips list (will choose a few at random each build)
    final List<Map<String, String>> tips = [
      {'title': 'Hydrate regularly', 'subtitle': 'Drinking water before meals helps reduce overeating'},
      {'title': 'Include protein', 'subtitle': 'Add a protein source to every meal to stay fuller longer'},
      {'title': 'Choose whole grains', 'subtitle': 'Swap refined carbs for whole grains for better energy levels'},
      {'title': 'Mindful eating', 'subtitle': 'Eat without distractions and chew slowly to feel satisfied'},
      {'title': 'Plan snacks', 'subtitle': 'Keep healthy snacks ready to avoid impulse choices'},
    ];

    Widget rightFeed(BuildContext ctx) {
      // pick up to 3 random tips to show
      final rnd = math.Random();
      final selected = <Map<String, String>>[];
      final pool = List<Map<String, String>>.from(tips);
      final picks = math.min(3, pool.length);
      for (var i = 0; i < picks; i++) {
        final idx = rnd.nextInt(pool.length);
        selected.add(pool.removeAt(idx));
      }
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        surfaceTintColor: colorScheme.surfaceTint,
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Health Feed', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: selected.map((t) => _FeedCard(title: t['title'] ?? '', subtitle: t['subtitle'] ?? '', image: null)).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'NutriCare',
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLarge)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: leftCard(context)),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: rightFeed(context)),
                      ],
                    )
                  else ...[
                    leftCard(context),
                    const SizedBox(height: 12),
                    Text('Health Feed', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: () {
                          // Recompute a small random sample for compact view
                          final rnd = math.Random();
                          final pool = List<Map<String, String>>.from(tips);
                          final picks = math.min(3, pool.length);
                          final selectedSmall = <Map<String, String>>[];
                          for (var i = 0; i < picks; i++) {
                            selectedSmall.add(pool.removeAt(rnd.nextInt(pool.length)));
                          }
                          return selectedSmall.map((t) => _FeedCard(title: t['title'] ?? '', subtitle: t['subtitle'] ?? '', image: null)).toList();
                        }(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                ],
              ),
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _SummaryCard({Key? key, required this.title, required this.value, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      fit: FlexFit.loose,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _ActionButton({Key? key, required this.icon, required this.label, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 20),
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? image;
  const _FeedCard({Key? key, required this.title, required this.subtitle, this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
        surfaceTintColor: colorScheme.surfaceTint,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: colorScheme.secondaryContainer)),
              const SizedBox(height: 8),
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
