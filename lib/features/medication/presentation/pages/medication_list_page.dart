import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:pautamedica/features/medication/domain/entities/medication.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_event.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_state.dart';
import 'package:pautamedica/features/medication/presentation/widgets/medication_list_item.dart';
import 'package:pautamedica/features/medication/presentation/widgets/add_medication_fab.dart';
import 'package:pautamedica/features/medication/presentation/pages/add_edit_medication_page.dart';
import 'package:pautamedica/features/medication/presentation/widgets/image_carousel_page.dart';

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
    return BlocListener<MedicationBloc, MedicationState>(
      listener: (context, state) {
        if (state is MedicationExportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is MedicationImportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Datos importados correctamente.'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is PastDosesMarkedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dosis pasadas marcadas como desistidas.'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is MedicationError) {
          // Evita mostrar el SnackBar si ya se está mostrando la pantalla de error.
          final currentState = context.read<MedicationBloc>().state;
          if (currentState is! MedicationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Scaffold(
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
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'export') {
                  context.read<MedicationBloc>().add(ExportMedicationsEvent());
                } else if (value == 'import') {
                  context.read<MedicationBloc>().add(ImportMedicationsEvent());
                } else if (value == 'marcarpasadas') {
                  final bloc = context.read<MedicationBloc>();
                  if (mounted) {
                    bloc.add(MarkPastDosesAsNotTakenEvent());
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.file_upload),
                    title: Text('Exportar datos'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'import',
                  child: ListTile(
                    leading: Icon(Icons.file_download),
                    title: Text('Importar datos'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'marcarpasadas',
                  child: ListTile(
                    leading: Icon(Icons.mark_chat_unread_outlined),
                    title: Text('Marcar pasadas'),
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: BlocBuilder<MedicationBloc, MedicationState>(
          buildWhen: (previous, current) {
            return current is MedicationLoaded ||
                current is MedicationLoading ||
                current is MedicationError ||
                current is MedicationInitial ||
                current is MedicationImportLoading;
          },
          builder: (context, state) {
            _logger
                .i('MedicationListPage: Estado actual: ${state.runtimeType}');

            if (state is MedicationImportLoading) {
              return Stack(
                children: [
                  _buildContent(state), // Fondo
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Importando datos...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Por favor espere.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

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

              return ReorderableListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: 80, // Added extra bottom padding for the FAB
                ),
                onReorder: (oldIndex, newIndex) =>
                    _reorderMedications(state.medications, oldIndex, newIndex),
                itemCount: state.medications.length,
                itemBuilder: (context, index) {
                  final medication = state.medications[index];
                  return MedicationListItem(
                    key: ValueKey(medication.id),
                    medication: medication,
                    onTap: () => _showMedicationDetails(context, medication),
                    onImageTap: (imagePaths, initialIndex) =>
                        _showImageFullScreen(
                            context, medication, imagePaths, initialIndex),
                    onDelete: () => _confirmDelete(context, medication),
                    onEdit: () => _navigateToEdit(context, medication),
                    onTake: () => context
                        .read<MedicationBloc>()
                        .add(RecordMedicationDoseEvent(medication)),
                  );
                },
              );
            }

            _logger.w(
                'MedicationListPage: Estado desconocido: ${state.runtimeType}');
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
      ),
    );
  }

  Widget _buildContent(MedicationState state) {
    // Reutiliza la lógica del builder para el fondo durante import loading
    if (state is MedicationLoaded) {
      if (state.medications.isEmpty) {
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
      return ReorderableListView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          top: 16,
          right: 16,
          bottom: 80,
        ),
        onReorder: (oldIndex, newIndex) =>
            _reorderMedications(state.medications, oldIndex, newIndex),
        itemCount: state.medications.length,
        itemBuilder: (context, index) {
          final medication = state.medications[index];
          return MedicationListItem(
            key: ValueKey(medication.id),
            medication: medication,
            onTap: () => _showMedicationDetails(context, medication),
            onImageTap: (imagePaths, initialIndex) => _showImageFullScreen(
                context, medication, imagePaths, initialIndex),
            onDelete: () => _confirmDelete(context, medication),
            onEdit: () => _navigateToEdit(context, medication),
            onTake: () => context
                .read<MedicationBloc>()
                .add(RecordMedicationDoseEvent(medication)),
          );
        },
      );
    }
    // Para otros estados durante import, mostrar el loading normal o vacío
    return const SizedBox.shrink();
  }

  void _reorderMedications(
      List<Medication> medications, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final reorderedMedications = List<Medication>.from(medications);
    final medication = reorderedMedications.removeAt(oldIndex);
    reorderedMedications.insert(newIndex, medication);
    context
        .read<MedicationBloc>()
        .add(ReorderMedicationsEvent(reorderedMedications));
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

  void _showImageFullScreen(BuildContext context, medication,
      List<String> imagePaths, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCarouselPage(
          imagePaths: imagePaths,
          initialIndex: initialIndex,
          medicationName: medication.name,
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
