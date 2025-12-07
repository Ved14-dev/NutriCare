import 'package:flutter/material.dart';
// Removed unused import
import '../backend/food_log_admin.dart';

class AdminDeleteFoodLogsButton extends StatelessWidget {
  const AdminDeleteFoodLogsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await FoodLogAdmin.deleteAllFoodLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All food log history deleted.')),
        );
      },
      child: const Text('Delete All Food Log History'),
    );
  }
}
