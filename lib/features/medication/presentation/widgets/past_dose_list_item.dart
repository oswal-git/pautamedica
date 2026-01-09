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
  final Function(List<String>, int)? onImageTap; // Changed callback signature

  final String medicationDescription;

  const PastDoseListItem({
    super.key,
    required this.dose,
    required this.onDelete,
    this.onUnmark,
    this.isMostRecent = false,
    this.onImageTap,
    this.medicationDescription = '',
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
    final displayImagePath = dose.medicationImagePaths.length > 1
        ? dose.medicationImagePaths[1]
        : dose.medicationImagePaths.isNotEmpty
            ? dose.medicationImagePaths[0]
            : '';

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
              onTap: onImageTap != null
                  ? () {
                      final initialIndex =
                          dose.medicationImagePaths.length > 1 ? 1 : 0;
                      onImageTap!(dose.medicationImagePaths, initialIndex);
                    }
                  : null,
              child: SizedBox(
                width: 64, // Reduced size
                height: 64, // Reduced size
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: displayImagePath.isNotEmpty &&
                          File(displayImagePath).existsSync()
                      ? Image.file(
                          File(displayImagePath),
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
                  if (medicationDescription.isNotEmpty)
                    Text(
                      medicationDescription,
                      style: TextStyle(
                        fontSize: 12, // Same font size as posology
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            _getStatusIcon(dose.status),
          ],
        ),
      ),
    );
  }
}
