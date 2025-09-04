import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/presentation/widgets/medication_image_placeholder.dart';

class DoseListItem extends StatelessWidget {
  final Dose dose;
  final Function(DoseStatus) onStatusChanged;
  final VoidCallback? onImageTap; // New callback

  const DoseListItem({
    super.key,
    required this.dose,
    required this.onStatusChanged,
    this.onImageTap,
  });

  Color _getCardColor(Dose dose) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final doseDate = DateTime(dose.time.year, dose.time.month, dose.time.day);

    if (dose.status == DoseStatus.expired) {
      return Colors.red.shade200; // Stronger red for expired
    }

    if (doseDate == today) {
      return Colors.orange.shade100; // Reddish for today
    }

    return Colors.white; // Default color for other days
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      color: _getCardColor(dose),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Row(
          children: [
            GestureDetector( // Added GestureDetector
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
                            return const MedicationImagePlaceholder(size: 64, iconSize: 32); // Reduced icon size
                          },
                        )
                      : const MedicationImagePlaceholder(size: 64, iconSize: 32), // Reduced icon size
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
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 28), // Reduced icon size
              onPressed: () => onStatusChanged(DoseStatus.taken),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 28), // Reduced icon size
              onPressed: () => onStatusChanged(DoseStatus.notTaken),
            ),
          ],
        ),
      ),
    );
  }
}
