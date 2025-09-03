import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pautamedica/features/medication/domain/entities/dose.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/presentation/widgets/medication_image_placeholder.dart';

class DoseListItem extends StatelessWidget {
  final Dose dose;
  final Function(DoseStatus) onStatusChanged;

  const DoseListItem({
    super.key,
    required this.dose,
    required this.onStatusChanged,
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
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
              onPressed: () => onStatusChanged(DoseStatus.taken),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
              onPressed: () => onStatusChanged(DoseStatus.notTaken),
            ),
          ],
        ),
      ),
    );
  }
}
