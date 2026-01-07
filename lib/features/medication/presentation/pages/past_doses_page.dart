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
}
