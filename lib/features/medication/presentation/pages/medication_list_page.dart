import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/widgets/medication_list_item.dart';
import 'package:pautamedica/features/medication/presentation/widgets/add_medication_fab.dart';
import 'package:pautamedica/features/medication/presentation/pages/add_edit_medication_page.dart';

class MedicationListPage extends StatefulWidget {
  const MedicationListPage({super.key});

  @override
  State<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    context.read<MedicationBloc>().add(LoadMedications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pauta Médica',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      body: BlocBuilder<MedicationBloc, MedicationState>(
        buildWhen: (previous, current) {
          return current is MedicationLoaded ||
              current is MedicationLoading ||
              current is MedicationError ||
              current is MedicationInitial;
        },
        builder: (context, state) {
          _logger.i('MedicationListPage: Estado actual: ${state.runtimeType}');

          if (state is MedicationLoading || state is UpcomingDosesLoaded) {
            _logger.i('MedicationListPage: Mostrando loading...');
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.deepPurple,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando medicamentos...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (state is MedicationError) {
            _logger.e(
                'MedicationListPage: Estado MedicationError: ${state.message}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MedicationBloc>().add(LoadMedications());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is MedicationLoaded) {
            _logger.i(
                'MedicationListPage: Estado MedicationLoaded con ${state.medications.length} medicamentos');
            if (state.medications.isEmpty) {
              _logger.i(
                  'MedicationListPage: Lista vacía, mostrando mensaje de no medicamentos');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay medicamentos registrados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toca el botón + para agregar tu primer medicamento',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                top: 16,
                right: 16,
                bottom: 80, // Added extra bottom padding for the FAB
              ),
              itemCount: state.medications.length,
              itemBuilder: (context, index) {
                final medication = state.medications[index];
                return MedicationListItem(
                  key: ValueKey(medication.id),
                  medication: medication,
                  onTap: () => _showMedicationDetails(context, medication),
                  onImageTap: () => _showImageFullScreen(context, medication),
                  onDelete: () => _confirmDelete(context, medication),
                  onEdit: () => _navigateToEdit(context, medication),
                );
              },
            );
          }

          _logger.w('MedicationListPage: Estado desconocido: ${state.runtimeType}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Estado desconocido',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  'Estado: ${state.runtimeType}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: const AddMedicationFAB(),
    );
  }

  void _showMedicationDetails(BuildContext context, medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMedicationPage(
          medication: medication,
          isEditing: true,
        ),
      ),
    );
  }

  void _showImageFullScreen(BuildContext context, medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              medication.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            backgroundColor: Colors.deepPurple.shade900,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: (medication.imagePath != null && medication.imagePath.isNotEmpty && File(medication.imagePath).existsSync())
                  ? Image.file(
                      File(medication.imagePath),
                      fit: BoxFit.contain, // Keep contain for aspect ratio
                    )
                  : const Icon(
                      Icons.image_not_supported, // Placeholder icon
                      size: 100,
                      color: Colors.grey,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, medication) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar "${medication.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<MedicationBloc>().add(
                      DeleteMedicationEvent(medication.id),
                    );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEdit(BuildContext context, medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMedicationPage(
          medication: medication,
          isEditing: true,
        ),
      ),
    );
  }
}