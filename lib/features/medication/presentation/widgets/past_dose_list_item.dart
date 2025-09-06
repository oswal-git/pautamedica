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
  final VoidCallback? onImageTap; // New callback

  const PastDoseListItem({
    super.key,
    required this.dose,
    required this.onDelete,
    this.onUnmark,
    this.isMostRecent = false,
    this.onImageTap,
  });

  Widget _getStatusIcon(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return const Icon(Icons.check_circle,
            color: Colors.green, size: 28); // Reduced icon size
      case DoseStatus.notTaken:
        return const Icon(Icons.cancel,
            color: Colors.red, size: 28); // Reduced icon size
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
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Row(
          children: [
            GestureDetector(
              // Added GestureDetector
              onTap: onImageTap, // Assign onImageTap
              child: SizedBox(
                width: 64, // Reduced size
                height: 64, // Reduced size
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: dose.medicationImagePath.isNotEmpty
                      ? Image.file(
                          File(dose.medicationImagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const MedicationImagePlaceholder(
                                size: 64, iconSize: 32); // Reduced icon size
                          },
                        )
                      : const MedicationImagePlaceholder(
                          size: 64, iconSize: 32), // Reduced icon size
                ),
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
                      fontSize: 16, // Reduced font size
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(dose.time),
                    style: TextStyle(
                      fontSize: 12, // Reduced font size
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (dose.markedAt != null) // Display markedAt if available
                    Text(
                      'Tomada el ${DateFormat('dd/MM/yyyy HH:mm').format(dose.markedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                _getStatusIcon(dose.status),
                if (isMostRecent &&
                    onUnmark != null) // Conditionally show unmark button
                  IconButton(
                    icon: const Icon(Icons.undo), // Or Icons.refresh
                    onPressed: onUnmark,
                    iconSize: 28, // Reduced icon size
                  ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                  iconSize: 28, // Reduced icon size
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
