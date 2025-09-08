import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/widgets/past_dose_list_item.dart';
import 'package:pautamedica/features/medication/presentation/widgets/medication_image_placeholder.dart';

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
                final isMostRecent = state.mostRecentDoseIds[dose.medicationId] == dose.id;
                return PastDoseListItem(
                  dose: dose,
                  isMostRecent: isMostRecent,
                  onDelete: () {
                    context.read<MedicationBloc>().add(DeleteDoseEvent(dose.id));
                  },
                  onUnmark: isMostRecent
                      ? () {
                          context.read<MedicationBloc>().add(
                                UpdateDoseStatusEvent(
                                  dose,
                                  DoseStatus.upcoming, // Or DoseStatus.expired based on time
                                  refreshPastDoses: true, // Set to true
                                ),
                              );
                        }
                      : null,
                  onImageTap: (imagePaths) => _showImageFullScreen(context, dose.medicationName, imagePaths),
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

  void _showImageFullScreen(BuildContext context, String medicationName, List<String> imagePaths) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              medicationName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            backgroundColor: Colors.deepPurple.shade900,
            foregroundColor: Colors.white,
          ),
          body: imagePaths.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  ),
                )
              : imagePaths.length == 1
                  ? Center(
                      child: InteractiveViewer(
                        child: Image.file(
                          File(imagePaths[0]),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const MedicationImagePlaceholder(size: 200, iconSize: 80);
                          },
                        ),
                      ),
                    )
                  : PageView.builder(
                      itemCount: imagePaths.length,
                      itemBuilder: (context, index) {
                        return Center(
                          child: InteractiveViewer(
                            child: Image.file(
                              File(imagePaths[index]),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const MedicationImagePlaceholder(size: 200, iconSize: 80);
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

