import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_scaffold.dart';
import '../services/gemini_service.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({Key? key}) : super(key: key);

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  String _personalizedPlan = '';
  bool _loading = false;
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _suggestedPlans = [
    {
      'title': 'Weight Loss',
      'desc': 'A calorie deficit plan focused on whole foods, lean proteins, and regular hydration.',
      'tips': '• Eat more vegetables\n• Avoid sugary drinks\n• Exercise 30 min daily',
      'meals': [
        'Breakfast: Greek yogurt with berries and chia seeds',
        'Lunch: Grilled chicken salad with mixed greens',
        'Snack: Apple slices with almond butter',
        'Dinner: Baked salmon, steamed broccoli, quinoa',
      ],
    },
    {
      'title': 'Muscle Gain',
      'desc': 'High-protein meals, strength training, and balanced macros for muscle growth.',
      'tips': '• Increase protein intake\n• Strength train 3x/week\n• Sleep 7-8 hours',
      'meals': [
        'Breakfast: Scrambled eggs, whole grain toast, avocado',
        'Lunch: Turkey and quinoa bowl with veggies',
        'Snack: Cottage cheese with pineapple',
        'Dinner: Beef stir-fry with brown rice',
      ],
    },
    {
      'title': 'Hydration Focus',
      'desc': 'Track water intake, add hydrating foods, and set reminders.',
      'tips': '• Drink water every 2 hours\n• Eat fruits/veggies\n• Limit caffeine',
      'meals': [
        'Breakfast: Oatmeal with watermelon and mint',
        'Lunch: Spinach salad with cucumber and oranges',
        'Snack: Celery sticks with hummus',
        'Dinner: Grilled fish with zucchini and tomatoes',
      ],
    },
    {
      'title': 'Balanced Diet',
      'desc': 'A plan for overall health: whole grains, lean proteins, healthy fats, and fiber.',
      'tips': '• Include all food groups\n• Limit processed foods\n• Eat mindfully',
      'meals': [
        'Breakfast: Overnight oats with nuts and banana',
        'Lunch: Grilled chicken wrap with veggies',
        'Snack: Mixed nuts and dried fruit',
        'Dinner: Lentil soup with whole grain bread',
      ],
    },
    {
      'title': 'Maintenance',
      'desc': 'Maintain current weight with portion control and regular activity.',
      'tips': '• Monitor portions\n• Stay active\n• Track progress',
      'meals': [
        'Breakfast: Smoothie with spinach, banana, and protein powder',
        'Lunch: Tuna salad sandwich on whole wheat',
        'Snack: Carrot sticks with hummus',
        'Dinner: Grilled shrimp with roasted vegetables',
      ],
    },
  ];

  Future<void> _fetchPersonalizedPlan() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _personalizedPlan = 'You must be signed in to view personalized plans.';
        _loading = false;
      });
      return;
    }
    final foodLogs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('food_logs')
        .orderBy('timestamp', descending: true)
        .get();
    final entries = foodLogs.docs.map((doc) {
      final data = doc.data();
      final encodable = <String, dynamic>{};
      data.forEach((key, value) {
        if (value is DateTime) {
          encodable[key] = value.toIso8601String();
        } else if (value is Timestamp) {
          encodable[key] = value.toDate().toIso8601String();
        } else if (value is DocumentReference) {
          encodable[key] = value.id;
        } else {
          encodable[key] = value;
        }
      });
      return encodable;
    }).toList();
    final plan = await GeminiService.getPersonalizedPlan(entries);
    setState(() {
      _personalizedPlan = plan;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchPersonalizedPlan();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Personalized Plans',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'My Plan'),
                Tab(text: 'Suggested Plans'),
              ],
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Personalized Plan Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _personalizedPlan.isNotEmpty
                            ? Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Your Personalized Plan', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.deepPurple)),
                                        const SizedBox(height: 12),
                                        Text(_personalizedPlan, style: Theme.of(context).textTheme.bodyLarge),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const Center(child: Text('No plan available.')),
                  ),
                  // Suggested Plans Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      itemCount: _suggestedPlans.length,
                      itemBuilder: (context, i) {
                        final plan = _suggestedPlans[i];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan['title'] ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.deepPurple)),
                                const SizedBox(height: 8),
                                Text(plan['desc'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 12),
                                Text('Tips:', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.deepPurple)),
                                const SizedBox(height: 4),
                                ...?plan['tips']?.split('\n').map((tip) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.deepPurple, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(tip, style: Theme.of(context).textTheme.bodySmall)),
                                        ],
                                      ),
                                    )),
                                if (plan['meals'] != null) ...[
                                  const SizedBox(height: 12),
                                  Text('Suggested Meals:', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.deepPurple)),
                                  const SizedBox(height: 4),
                                  ...List<Widget>.from((plan['meals'] as List).map((meal) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.restaurant_menu, color: Colors.green, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(meal, style: Theme.of(context).textTheme.bodySmall)),
                                          ],
                                        ),
                                      ))),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
