import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'hydration_animated_widgets.dart';

class HydrationPage extends StatefulWidget {
  const HydrationPage({Key? key}) : super(key: key);

  @override
  State<HydrationPage> createState() => _HydrationPageState();
}

class _HydrationPageState extends State<HydrationPage> {
    int _selectedIndex = 2; // Hydration tab index

    void _onNavTap(int index) {
      if (index == _selectedIndex) return;
      if (index == 0) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (index == 1) {
        Navigator.pushReplacementNamed(context, '/food_log');
      } else if (index == 2) {
        // Already on hydration
      }
      setState(() {
        _selectedIndex = index;
      });
    }
  final double hydrationGoal = 7.0; // litres
  final Duration animationDuration = const Duration(milliseconds: 1200);
  Future<void> _addWater(double litres) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('hydration_logs')
        .doc(today);
    final doc = await docRef.get();
    double current = (doc.data()?['litres'] ?? 0.0) as double;
    await docRef.set({'litres': current + litres, 'date': today}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return Scaffold(
      appBar: AppBar(title: const Text('Hydration Tracker')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('hydration_logs')
                  .doc(today)
                  .snapshots(),
              builder: (context, snap) {
                double todayIntake = 0.0;
                if (snap.hasData && snap.data!.exists) {
                  final data = snap.data!.data() as Map<String, dynamic>?;
                  todayIntake = (data?['litres'] ?? 0.0) as double;
                }
                final progress = (todayIntake / hydrationGoal).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Today\'s Intake', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: animationDuration,
                        curve: Curves.easeInOut,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Lottie.asset('assets/animations/water_wave.json', repeat: true, animate: true),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: todayIntake),
                                  duration: animationDuration,
                                  builder: (context, value, child) => Text(
                                    '${value.toStringAsFixed(2)} / $hydrationGoal L',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedProgressBar(progress: progress),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Quick Add', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          AnimatedAddButton(label: '+250ml', onTap: () => _addWater(0.25)),
                          AnimatedAddButton(label: '+500ml', onTap: () => _addWater(0.5)),
                          AnimatedAddButton(label: '+1L', onTap: () => _addWater(1.0)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Expanded(child: _buildHistory()),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Food Log'),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: 'Hydration'),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('hydration_logs')
          .orderBy('date', descending: true)
          .limit(7)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Text('No hydration history yet.');
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final date = data['date'] ?? docs[i].id;
            final litres = (data['litres'] ?? 0.0) as double;
            return ListTile(
              title: Text('Date: $date'),
              subtitle: Text('Intake: ${litres.toStringAsFixed(2)} L'),
            );
          },
        );
      },
    );
  }
}
