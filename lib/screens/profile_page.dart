import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_scaffold.dart';
import '../backend/auth_service.dart';
import '../widgets/personal_details_form.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Account'),
                Tab(text: 'Personal Details'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ...existing account info code...
                        Row(
                          children: [
                            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                              stream: FirebaseAuth.instance.currentUser == null
                                  ? const Stream.empty()
                                  : FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
                              builder: (context, snap) {
                                String name = '';
                                String email = '';
                                if (snap.hasData && snap.data != null && snap.data!.exists) {
                                  final data = snap.data!.data();
                                  name = (data?['name'] as String?) ?? '';
                                  email = (data?['email'] as String?) ?? '';
                                }
                                final authUser = FirebaseAuth.instance.currentUser;
                                if (name.isEmpty) name = authUser?.displayName ?? '';
                                if (email.isEmpty) email = authUser?.email ?? '';

                                final initial = (name.trim().isNotEmpty) ? name.trim()[0].toUpperCase() : (email.isNotEmpty ? email.trim()[0].toUpperCase() : 'U');

                                return Row(children: [
                                  CircleAvatar(radius: 36, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text(initial, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onPrimaryContainer))),
                                  const SizedBox(width: 12),
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(name.isNotEmpty ? name : 'User', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text('Premium Member', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))
                                  ])
                                ]);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Icon(Icons.email, size: 22, color: Theme.of(context).colorScheme.primary),
                            title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                              stream: FirebaseAuth.instance.currentUser == null
                                  ? const Stream.empty()
                                  : FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
                              builder: (context, snap) {
                                String email = '';
                                if (snap.hasData && snap.data != null && snap.data!.exists) {
                                  email = (snap.data!.data()?['email'] as String?) ?? '';
                                }
                                if (email.isEmpty) email = FirebaseAuth.instance.currentUser?.email ?? '';
                                return Text(email.isNotEmpty ? email : 'Not set', style: GoogleFonts.inter());
                              },
                            ),
                            subtitle: Text('Account', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65))),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Icon(Icons.settings, size: 22, color: Theme.of(context).colorScheme.primary),
                            title: Text('Settings', style: GoogleFonts.inter()),
                            subtitle: Text('Profile, Notifications, Privacy', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65))),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Icon(Icons.logout, size: 22, color: Theme.of(context).colorScheme.error),
                            title: Text('Sign out', style: GoogleFonts.inter()),
                            onTap: () async {
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
                                await FirebaseAuth.instance.signOut();
                                try {
                                  await AuthService.signOut();
                                } catch (_) {}
                                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(child: Text('NutriCare • v1.0.0', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65)))),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  // Personal Details Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(18.0),
                    child: PersonalDetailsForm(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
