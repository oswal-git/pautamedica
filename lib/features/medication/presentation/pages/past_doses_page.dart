import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_event.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_state.dart';
import 'package:pautamedica/features/medication/presentation/widgets/past_dose_list_item.dart';
import 'package:pautamedica/features/medication/presentation/widgets/image_carousel_page.dart';

class PastDosesPage extends StatefulWidget {
  const PastDosesPage({super.key});

  @override
  State<PastDosesPage> createState() => _PastDosesPageState();
}

class _PastDosesPageState extends State<PastDosesPage> {
  @override
  void initState() {
    super.initState();
    context.read<MedicationBloc>().add(LoadPastDoses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomas Pasadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _showCleanupDialog,
          ),
        ],
      ),
      body: BlocBuilder<MedicationBloc, MedicationState>(
        buildWhen: (previous, current) {
          return current is PastDosesLoaded ||
              current is MedicationLoading ||
              current is MedicationError ||
              current is MedicationInitial;
        },
        builder: (context, state) {
          if (state is MedicationLoading || state is MedicationInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PastDosesLoaded) {
            if (state.doses.isEmpty) {
              return const Center(child: Text('No hay tomas pasadas.'));
            }
            return ListView.builder(
              itemCount: state.doses.length,
              itemBuilder: (context, index) {
                final dose = state.doses[index];
                final isMostRecent =
                    state.mostRecentDoseIds[dose.medicationId] == dose.id;
                final medication = state.medicationsMap[dose.medicationId];
                return PastDoseListItem(
                  dose: dose,
                  medicationDescription:
                      medication?.description ?? '', // Pass description
                  isMostRecent: isMostRecent,
                  onDelete: () {
                    context
                        .read<MedicationBloc>()
                        .add(DeleteDoseEvent(dose.id));
                  },
                  onUnmark: isMostRecent
                      ? () {
                          context.read<MedicationBloc>().add(
                                UpdateDoseStatusEvent(
                                  dose,
                                  DoseStatus
                                      .upcoming, // Or DoseStatus.expired based on time
                                  refreshPastDoses: true, // Set to true
                                ),
                              );
                        }
                      : null,
                  onImageTap: (imagePaths, initialIndex) =>
                      _showImageFullScreen(context, dose.medicationName,
                          imagePaths, initialIndex),
                );
              },
            );
          }
          if (state is MedicationError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Algo salió mal.'));
        },
      ),
    );
  }

  void _showImageFullScreen(BuildContext context, String medicationName,
      List<String> imagePaths, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCarouselPage(
          imagePaths: imagePaths,
          initialIndex: initialIndex,
          medicationName: medicationName,
        ),
      ),
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar Tomas Pasadas'),
          content: const Text(
              'Selecciona cuánto tiempo mantener las tomas pasadas:'),
          actions: [
            TextButton(
              onPressed: () => _confirmCleanup(15),
              child: const Text('Mantener últimos 15 días'),
            ),
            TextButton(
              onPressed: () => _confirmCleanup(30),
              child: const Text('Mantener últimos 30 días'),
            ),
            TextButton(
              onPressed: () => _confirmCleanup(90),
              child: const Text('Mantener últimos 3 meses'),
            ),
            TextButton(
              onPressed: () => _confirmCleanup(0),
              child: const Text('Eliminar todas'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmCleanup(int days) {
    Navigator.of(context).pop(); // Close the dialog
    String message;
    if (days == 0) {
      message =
          '¿Estás seguro de que quieres eliminar todas las tomas pasadas?';
    } else {
      message =
          '¿Estás seguro de que quieres eliminar las tomas pasadas anteriores a $days días?';
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => _performCleanup(days),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _performCleanup(int days) {
    Navigator.of(context).pop(); // Close the confirmation dialog
    final cutoff = days == 0
        ? DateTime.now()
        : DateTime.now().subtract(Duration(days: days));
    context.read<MedicationBloc>().add(CleanPastDosesEvent(cutoff));
  }
}
