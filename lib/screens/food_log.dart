

  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:fluttertoast/fluttertoast.dart';
  import 'package:intl/intl.dart';
  import '../widgets/app_scaffold.dart';
  import '../services/food_image_service.dart';
  import '../services/food_recognition_service.dart';
  import '../data/nutrition_table.dart';

class FoodLog extends StatefulWidget {
  const FoodLog({super.key});

  @override
  _FoodLogState createState() => _FoodLogState();
}


class _FoodLogState extends State<FoodLog> {
  bool _loadingImage = false;
  final _formKey = GlobalKey<FormState>();
  String _foodName = '';
  String _calories = '';
  String _protein = '';
  String _carbs = '';
  String _fat = '';
  String _serving = '';

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.of(ctx).pop();
                _handleImageFoodLog(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload from Gallery'),
              onTap: () async {
                Navigator.of(ctx).pop();
                _handleImageFoodLog(fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageFoodLog({required bool fromCamera}) async {
    setState(() => _loadingImage = true);
    try {
      final imageBytes = fromCamera
          ? await FoodImageService.pickCameraImage()
          : await FoodImageService.pickGalleryImage();
      if (imageBytes == null) {
        setState(() => _loadingImage = false);
        return;
      }
      // Use FoodRecognitionService to classify image
      final foodRecognizer = FoodRecognitionService();
      await foodRecognizer.loadModel();
      final predictedClass = await foodRecognizer.predictFood(imageBytes);
      final nutrition = nutritionTable[predictedClass] ?? {};
      final foods = [
        {
          'name': predictedClass,
          'calories': nutrition['calories'] ?? 0,
          'protein_g': nutrition['protein'] ?? 0,
          'carbs_g': nutrition['carbs'] ?? 0,
          'fat_g': nutrition['fat'] ?? 0,
          'serving_size': nutrition['serving_size'] ?? '',
        }
      ];
      setState(() => _loadingImage = false);
      if (!mounted) return;
      final editedFoods = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (_) => FoodImageConfirmScreen(foods: foods),
        ),
      );
      if (editedFoods != null && editedFoods.isNotEmpty) {
        await FoodImageService.saveFoodLogToFirestore(editedFoods);
        Fluttertoast.showToast(msg: 'Food log saved from image!');
      }
    } catch (e) {
      setState(() => _loadingImage = false);
      Fluttertoast.showToast(msg: 'Image food log failed: $e');
    }
  }

  void _showAddFoodDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Food Entry'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Food Name'),
                  onSaved: (v) => _foodName = v ?? '',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Calories'),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _calories = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Protein (g)'),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _protein = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Carbs (g)'),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _carbs = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Fat (g)'),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _fat = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Serving Size'),
                  onSaved: (v) => _serving = v ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                _formKey.currentState?.save();
                _saveManualFoodEntry();
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveManualFoodEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: 'You must be signed in to log food.');
      return;
    }
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final weekday = DateFormat('EEEE').format(now);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('food_logs')
          .add({
        'food_name': _foodName,
        'calories': _calories,
        'protein': _protein,
        'carbs': _carbs,
        'fat': _fat,
        'serving': _serving,
        'timestamp': FieldValue.serverTimestamp(),
        'date': formattedDate,
        'day': weekday,
        'source': 'manual',
      });
      Fluttertoast.showToast(msg: 'Food log saved successfully.');
      _formKey.currentState?.reset();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to save: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Food Log',
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Food (AI)'),
        onPressed: _showImageSourceSheet,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Food Entry'),
                    onPressed: _showAddFoodDialog,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('food_logs')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading food logs.'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(child: Text('No food logs yet.'));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) {
                          final data = docs[i].data();
                          final docRef = docs[i].reference;
                          // Support both manual and image logs
                          if (data['foods'] is List) {
                            // Image-based log: show all foods in a column
                            final foods = List<Map<String, dynamic>>.from(data['foods']);
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: const Icon(Icons.fastfood),
                                title: Text('Image Log: ${foods.map((f) => f['name']).join(", ")}'),
                                subtitle: Text(
                                  foods.map((f) => '${f['name']} - ${f['calories']} kcal | ${f['protein_g']}g P | ${f['carbs_g']}g C | ${f['fat_g']}g F').join('\n'),
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await docRef.delete();
                                    Fluttertoast.showToast(msg: 'Food entry deleted');
                                  },
                                ),
                              ),
                            );
                          } else {
                            // Manual log (existing)
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: const Icon(Icons.fastfood),
                                title: Text(data['food_name'] ?? 'Unknown'),
                                subtitle: Text('${data['calories']} kcal | ${data['protein']}g P | ${data['carbs']}g C | ${data['fat']}g F'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await docRef.delete();
                                    Fluttertoast.showToast(msg: 'Food entry deleted');
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_loadingImage)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// --- Place these at the very end of the file, outside of _FoodLogState and any other class ---

class FoodImageConfirmScreen extends StatefulWidget {
  final List<Map<String, dynamic>> foods;
  const FoodImageConfirmScreen({Key? key, required this.foods}) : super(key: key);

  @override
  State<FoodImageConfirmScreen> createState() => _FoodImageConfirmScreenState();
}

class _FoodImageConfirmScreenState extends State<FoodImageConfirmScreen> {
  late List<Map<String, dynamic>> _foods;

  @override
  void initState() {
    super.initState();
    _foods = widget.foods.map((f) => Map<String, dynamic>.from(f)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Food Items')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _foods.length,
                itemBuilder: (ctx, i) {
                  final food = _foods[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            initialValue: food['name'] ?? '',
                            decoration: const InputDecoration(labelText: 'Food Name'),
                            onChanged: (v) => food['name'] = v,
                          ),
                          TextFormField(
                            initialValue: food['calories']?.toString() ?? '',
                            decoration: const InputDecoration(labelText: 'Calories'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => food['calories'] = int.tryParse(v) ?? 0,
                          ),
                          TextFormField(
                            initialValue: food['protein_g']?.toString() ?? '',
                            decoration: const InputDecoration(labelText: 'Protein (g)'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => food['protein_g'] = double.tryParse(v) ?? 0.0,
                          ),
                          TextFormField(
                            initialValue: food['carbs_g']?.toString() ?? '',
                            decoration: const InputDecoration(labelText: 'Carbs (g)'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => food['carbs_g'] = double.tryParse(v) ?? 0.0,
                          ),
                          TextFormField(
                            initialValue: food['fat_g']?.toString() ?? '',
                            decoration: const InputDecoration(labelText: 'Fat (g)'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => food['fat_g'] = double.tryParse(v) ?? 0.0,
                          ),
                          TextFormField(
                            initialValue: food['serving_size'] ?? '',
                            decoration: const InputDecoration(labelText: 'Serving Size'),
                            onChanged: (v) => food['serving_size'] = v,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop(_foods);
              },
            ),
          ],
        ),
      ),
    );
  }
}

