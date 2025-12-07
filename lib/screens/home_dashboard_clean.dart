import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr_code_screen.dart';
import '../backend/firestore_service.dart';
import '../backend/auth_service.dart';
import '../widgets/app_scaffold.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  // Navigation handled by AppScaffold

  Widget leftCard(BuildContext ctx) {
    final colorScheme = Theme.of(ctx).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snap) {
                String name = 'there';
                if (snap.hasData && snap.data!.exists) {
                  final data = snap.data!.data() as Map<String, dynamic>?;
                  if (data != null && (data['name'] as String?)?.isNotEmpty == true) {
                    name = data['name'] as String;
                  }
                } else if (user?.displayName != null) {
                  name = user!.displayName!;
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
            StreamBuilder<QuerySnapshot>(
              stream: user == null
                  ? null
                  : FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('food_logs')
                      .where('date', isEqualTo: DateTime.now().toIso8601String().substring(0, 10))
                      .snapshots(),
              builder: (context, snap) {
                int totalCalories = 0;
                int meals = 0;
                if (snap.hasData && snap.data!.docs.isNotEmpty) {
                  meals = snap.data!.docs.length;
                  for (var doc in snap.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    totalCalories += int.tryParse(data['calories'].toString()) ?? 0;
                  }
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SummaryCard(title: 'Calories', value: '${totalCalories} kcal', color: colorScheme.secondaryContainer),
                    _SummaryCard(title: 'Meals', value: '$meals', color: colorScheme.tertiaryContainer),
                    _SummaryCard(title: 'Goal', value: 'Stay healthy', color: colorScheme.primaryContainer),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _ActionButton(icon: Icons.restaurant_menu, label: 'My Food Log', onPressed: () => Navigator.pushNamed(ctx, '/log')),
                _ActionButton(icon: Icons.chat_bubble, label: 'Chat Bot', onPressed: () => Navigator.pushNamed(ctx, '/chat')),
                _ActionButton(icon: Icons.qr_code, label: 'Nutritionist QR', onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const QRCodeScreen()))),
                _ActionButton(icon: Icons.upload_file, label: 'Upload Data', onPressed: () async {
                  await FirestoreService.sendMockFoodData();
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Food data uploaded!')));
                }),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                        context: ctx,
                        builder: (ctx2) => AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text('Are you sure you want to sign out?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx2).pop(false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.of(ctx2).pop(true), child: const Text('Sign Out')),
                              ],
                            ));
                    if (ok == true) {
                      await FirebaseAuth.instance.signOut();
                      try {
                        await AuthService.signOut();
                      } catch (_) {}
                      if (ctx.mounted) Navigator.pushReplacementNamed(ctx, '/login');
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


  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isLarge = width > 800;
    return AppScaffold(
      title: 'NutriCare',
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftCard(context),
              const SizedBox(height: 12),
              DynamicHealthSummary(),
              const SizedBox(height: 12),
            ],
          ),
        );
      }),
    );
  }
}

// Widget to show dynamic health summary for every user
class DynamicHealthSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No health summary available.')));
        }
        final data = snap.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No health summary available.')));
        }
        final age = data['age'] ?? '-';
        final height = data['height'] ?? '-';
        final weight = data['weight'] ?? '-';
        final bmi = data['bmi'] ?? '-';
        final bmiCategory = data['bmi_category'] ?? '';
        final goal = data['goal'] ?? '-';
        final activity = data['activity_level'] ?? '-';
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Health Summary', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text('Age: $age'),
                Text('Height: $height cm'),
                Text('Weight: $weight kg'),
                Text('BMI: $bmi ${bmiCategory.isNotEmpty ? '($bmiCategory)' : ''}'),
                Text('Goal: $goal'),
                Text('Activity Level: $activity'),
              ],
            ),
          ),
        );
      },
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
