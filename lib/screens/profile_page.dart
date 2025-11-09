import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_scaffold.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 36, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text('A', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onPrimaryContainer))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Alex Johnson', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('Premium Member', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))])
              ],
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.email, size: 22, color: Theme.of(context).colorScheme.primary),
                title: Text('alex@example.com', style: GoogleFonts.inter()),
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
                onTap: () {},
              ),
            ),
            const Spacer(),
            Center(child: Text('NutriCare • v1.0.0', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65)))),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
