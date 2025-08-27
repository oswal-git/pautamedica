import 'package:flutter/material.dart';
import 'package:pautamedica/features/medication/presentation/pages/add_edit_medication_page.dart';

class AddMedicationFAB extends StatelessWidget {
  const AddMedicationFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditMedicationPage(
              medication: null,
              isEditing: false,
            ),
          ),
        );
      },
      backgroundColor: Colors.deepPurple.shade900,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add),
      label: const Text(
        'Agregar',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
