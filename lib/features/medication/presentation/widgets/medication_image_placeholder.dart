import 'package:flutter/material.dart';

class MedicationImagePlaceholder extends StatelessWidget {
  final double? size;
  final double? iconSize;

  const MedicationImagePlaceholder({
    super.key,
    this.size,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.medication_liquid,
          size: iconSize,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}