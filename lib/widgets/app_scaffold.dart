import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A shared scaffold used across the app that provides a top app bar with
/// logo/title and a bottom navigation bar. Screens should pass their main
/// content as `child` so the app chrome remains consistent.
class AppScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final Widget? floatingActionButton;
  const AppScaffold({Key? key, required this.child, this.title = 'NutriCare', this.floatingActionButton}) : super(key: key);

  int _routeToIndex(String? route) {
    switch (route) {
      case '/chat':
        return 1;
      case '/log':
        return 2;
      case '/hydration':
        return 3;
      case '/profile':
        return 4;
      case '/plans':
        return 5;
      default:
        return 0;
    }
  }

  String _indexToRoute(int idx) {
    switch (idx) {
      case 1:
        return '/chat';
      case 2:
        return '/log';
      case 3:
        return '/hydration';
      case 4:
        return '/profile';
      case 5:
        return '/plans';
      default:
        return '/dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final selectedIndex = _routeToIndex(currentRoute);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: floatingActionButton,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: GoogleFonts.poppins(color: colorScheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
                        const SizedBox(height: 4),
                        Text('Track. Improve. Thrive.', style: GoogleFonts.inter(color: colorScheme.onPrimary.withOpacity(0.9), fontSize: 12)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                        stream: FirebaseAuth.instance.currentUser == null
                            ? const Stream.empty()
                            : FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
                        builder: (context, snap) {
                          String name = '';
                          if (snap.hasData && snap.data != null && snap.data!.exists) {
                            final data = snap.data!.data();
                            name = (data?['name'] as String?) ?? '';
                          }
                          if (name.isEmpty) {
                            final u = FirebaseAuth.instance.currentUser;
                            name = u?.displayName ?? u?.email ?? '';
                          }
                          final initial = (name.trim().isNotEmpty) ? name.trim()[0].toUpperCase() : 'U';
                          return CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.onPrimary,
                            child: Text(initial, style: GoogleFonts.poppins(color: colorScheme.primary, fontWeight: FontWeight.w700)),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                runSpacing: 6,
                children: [
                  _NavItem(icon: Icons.dashboard, label: 'Dashboard', index: 0, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                  _NavItem(icon: Icons.chat_bubble, label: 'Chat', index: 1, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                  _NavItem(icon: Icons.restaurant, label: 'Food Log', index: 2, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                  _NavItem(icon: Icons.local_drink, label: 'Hydration', index: 3, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                  _NavItem(icon: Icons.person, label: 'Profile', index: 4, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                  _NavItem(icon: Icons.star, label: 'Plans', index: 5, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.dashboard, label: 'Dashboard', index: 0, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                _NavItem(icon: Icons.chat_bubble, label: 'Chat', index: 1, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                _NavItem(icon: Icons.restaurant, label: 'Food Log', index: 2, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                _NavItem(icon: Icons.local_drink, label: 'Hydration', index: 3, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                _NavItem(icon: Icons.person, label: 'Profile', index: 4, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
                _NavItem(icon: Icons.star, label: 'Plans', index: 5, selectedIndex: selectedIndex, onTap: (i) => _onTap(context, i)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    final route = _indexToRoute(index);
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final void Function(int) onTap;
  const _NavItem({Key? key, required this.icon, required this.label, required this.index, required this.selectedIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool active = index == selectedIndex;
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: active ? colorScheme.primaryContainer.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onTap(index),
            icon: Icon(icon, size: 24, color: active ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7)),
            tooltip: label,
            splashRadius: 22,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: active ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }
}
