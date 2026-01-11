import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/domain/entities/dose_status.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_event.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_state.dart';
import 'package:pautamedica/features/medication/presentation/pages/medication_list_page.dart';
import 'package:pautamedica/features/medication/presentation/pages/past_doses_page.dart';
import 'package:pautamedica/features/medication/presentation/widgets/dose_list_item.dart';
import 'package:pautamedica/features/medication/presentation/widgets/image_carousel_page.dart';

class UpcomingDosesPage extends StatefulWidget {
  const UpcomingDosesPage({super.key});

  @override
  State<UpcomingDosesPage> createState() => _UpcomingDosesPageState();
}

class _UpcomingDosesPageState extends State<UpcomingDosesPage> {
  @override
  void initState() {
    super.initState();
    context.read<MedicationBloc>().add(LoadUpcomingDoses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximas Tomas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              final bloc = context.read<MedicationBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PastDosesPage(),
                ),
              ).then((_) {
                bloc.add(LoadUpcomingDoses());
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.medication),
            onPressed: () {
              final bloc = context.read<MedicationBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicationListPage(),
                ),
              ).then((_) {
                // When returning from MedicationListPage, reload the doses
                bloc.add(LoadUpcomingDoses());
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<MedicationBloc, MedicationState>(
        buildWhen: (previous, current) {
          return current is UpcomingDosesLoaded ||
              current is MedicationLoading ||
              current is MedicationError ||
              current is MedicationInitial;
        },
        builder: (context, state) {
          if (state is MedicationLoading || state is MedicationInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UpcomingDosesLoaded) {
            if (state.doses.isEmpty) {
              return const Center(child: Text('No hay próximas tomas.'));
            }
            return ListView.builder(
              itemCount: state.doses.length,
              itemBuilder: (context, index) {
                final dose = state.doses[index];
                final medication = state.medicationsMap[dose.medicationId];
                return DoseListItem(
                  dose: dose,
                  medicationDescription:
                      medication?.description ?? '', // Pass description
                  onStatusChanged: (status) async {
                    final bloc = context.read<MedicationBloc>();
                    if (status == DoseStatus.taken &&
                        dose.time.isAfter(DateTime.now())) {
                      final shouldProceed = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar Toma Futura'),
                            content: const Text(
                                'La dosis es posterior a hoy. ¿Estás seguro de que quieres marcarla como tomada?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Afirmar'),
                              ),
                            ],
                          );
                        },
                      );
                      if (shouldProceed != true) return;
                    }
                    if (!mounted) return;
                    bloc.add(UpdateDoseStatusEvent(dose, status,
                        refreshPastDoses: false)); // Explicitly set to false
                  },
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
