import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalDetailsForm extends StatefulWidget {
  const PersonalDetailsForm({Key? key}) : super(key: key);

  @override
  State<PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<PersonalDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  String _age = '';
  String _height = '';
  String _weight = '';
  String _gender = '';
  String _activityLevel = '';
  String _goal = '';

  double get _bmi {
    final h = double.tryParse(_height) ?? 0;
    final w = double.tryParse(_weight) ?? 0;
    if (h > 0 && w > 0) {
      final meters = h / 100.0;
      return w / (meters * meters);
    }
    return 0;
  }

  String get _bmiCategory {
    final bmi = _bmi;
    if (bmi == 0) return '';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Future<void> _saveDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'age': _age,
      'height': _height,
      'weight': _weight,
      'gender': _gender,
      'activity_level': _activityLevel,
      'goal': _goal,
      'bmi': _bmi.toStringAsFixed(2),
      'bmi_category': _bmiCategory,
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details saved!')));
    // Show profile update notification
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile Updated'),
        content: const Text('Your personal details have been updated.'),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _age = v),
            onSaved: (v) => _age = v ?? '',
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Height (cm)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _height = v),
            onSaved: (v) => _height = v ?? '',
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _weight = v),
            onSaved: (v) => _weight = v ?? '',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(child: Text('BMI: ${_bmi > 0 ? _bmi.toStringAsFixed(2) : '-'}', style: TextStyle(fontWeight: FontWeight.bold))),
                if (_bmi > 0) Text('(${_bmiCategory})', style: TextStyle(color: Colors.blueGrey)),
              ],
            ),
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Gender'),
            onChanged: (v) => setState(() => _gender = v),
            onSaved: (v) => _gender = v ?? '',
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Activity Level'),
            onChanged: (v) => setState(() => _activityLevel = v),
            onSaved: (v) => _activityLevel = v ?? '',
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Goal (e.g. lose weight, build muscle)'),
            onChanged: (v) => setState(() => _goal = v),
            onSaved: (v) => _goal = v ?? '',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _formKey.currentState?.save();
              _saveDetails();
            },
            child: const Text('Save Details'),
          ),
        ],
      ),
    );
  }
}
