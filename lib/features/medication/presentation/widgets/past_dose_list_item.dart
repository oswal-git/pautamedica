import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/presentation/widgets/medication_image_placeholder.dart';

class PastDoseListItem extends StatelessWidget {
  final Dose dose;
  final VoidCallback onDelete;
  final VoidCallback? onUnmark; // New callback
  final bool isMostRecent; // New property

  const PastDoseListItem({
    super.key,
    required this.dose,
    required this.onDelete,
    this.onUnmark,
    this.isMostRecent = false,
  });

  Widget _getStatusIcon(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return const Icon(Icons.check_circle, color: Colors.green, size: 32);
      case DoseStatus.notTaken:
        return const Icon(Icons.cancel, color: Colors.red, size: 32);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: dose.medicationImagePath.isNotEmpty
                    ? Image.file(
                        File(dose.medicationImagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const MedicationImagePlaceholder(size: 80, iconSize: 40);
                        },
                      )
                    : const MedicationImagePlaceholder(size: 80, iconSize: 40),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.medicationName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(dose.time),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _getStatusIcon(dose.status),
                if (isMostRecent && onUnmark != null) // Conditionally show unmark button
                  IconButton(
                    icon: const Icon(Icons.undo), // Or Icons.refresh
                    onPressed: onUnmark,
                  ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}