import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/domain/entities/repetition_type.dart';
import 'package:pautamedica/features/medication/presentation/widgets/medication_image_placeholder.dart';

class MedicationListItem extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTap;
  final VoidCallback onImageTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const MedicationListItem({
    super.key,
    required this.medication,
    required this.onTap,
    required this.onImageTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen del medicamento (tocable)
              GestureDetector(
                onTap: onImageTap,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: medication.imagePath.isNotEmpty
                        ? Image.file(
                            File(medication.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const MedicationImagePlaceholder(size: 80, iconSize: 40);
                            },
                          )
                        : const MedicationImagePlaceholder(size: 80, iconSize: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Información del medicamento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del medicamento
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Posología
                    Text(
                      medication.posology,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Repetition info
                    _buildRepetitionInfo(context),

                    // Horarios
                    if (medication.schedules.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Horarios: ${_formatSchedules(medication.schedules)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Botones de acción
              Column(
                children: [
                  // Botón de editar
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit,
                      color: Colors.deepPurple.shade600,
                      size: 20,
                    ),
                    tooltip: 'Editar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),

                  // Botón de eliminar
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    tooltip: 'Eliminar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepetitionInfo(BuildContext context) {
    final repetitionText = _getRepetitionText(medication);
    if (repetitionText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(
          Icons.repeat,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          repetitionText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getRepetitionText(Medication medication) {
    switch (medication.repetitionType) {
      case RepetitionType.none:
        return 'Dosis única';
      case RepetitionType.daily:
        if (medication.repetitionInterval == 1) {
          return 'Cada día';
        }
        return 'Cada ${medication.repetitionInterval} días';
      case RepetitionType.weekly:
        if (medication.repetitionInterval == 1) {
          return 'Cada semana';
        }
        return 'Cada ${medication.repetitionInterval} semanas';
      case RepetitionType.monthly:
        if (medication.repetitionInterval == 1) {
          return 'Cada mes';
        }
        return 'Cada ${medication.repetitionInterval} meses';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatSchedules(List<DateTime> schedules) {
    if (schedules.isEmpty) return 'Sin horarios';

    final sortedSchedules = List<DateTime>.from(schedules)
      ..sort((a, b) => a.compareTo(b));

    return sortedSchedules.map((s) => _formatTime(s)).join(', ');
  }
}