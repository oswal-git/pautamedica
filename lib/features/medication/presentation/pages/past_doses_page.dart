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
  final ScrollController _scrollController = ScrollController();
  int? _deletedIndex;

  @override
  void initState() {
    super.initState();
    context.read<MedicationBloc>().add(LoadPastDoses());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      body: BlocListener<MedicationBloc, MedicationState>(
        listenWhen: (previous, current) {
          return current is PastDosesLoaded;
        },
        listener: (context, state) {
          if (state is PastDosesLoaded && _deletedIndex != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final targetIndex = _deletedIndex! < state.doses.length
                  ? _deletedIndex!
                  : state.doses.length - 1;
              _scrollController.animateTo(
                targetIndex * 100.0, // Approximate item height
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _deletedIndex = null;
            });
          }
        },
        child: BlocBuilder<MedicationBloc, MedicationState>(
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
                controller: _scrollController,
                itemCount: state.doses.length,
                itemBuilder: (context, index) {
                  final dose = state.doses[index];
                  final isMostRecent =
                      state.mostRecentDoseIds[dose.medicationId] == dose.id;
                  final medication = state.medicationsMap[dose.medicationId];
                  return Dismissible(
                    key: Key(dose.id.toString()),
                    direction: isMostRecent
                        ? DismissDirection.horizontal
                        : DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        // Swipe right to delete
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Eliminar Toma'),
                              content: const Text(
                                  '¿Estás seguro de que quieres eliminar esta toma?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            );
                          },
                        );
                      } else if (direction == DismissDirection.startToEnd &&
                          isMostRecent) {
                        // Swipe left to unmark if possible
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Desmarcar Toma'),
                              content: const Text(
                                  '¿Estás seguro de que quieres desmarcar esta toma?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Desmarcar'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.endToStart) {
                        // Swipe right to delete
                        _deletedIndex = index;
                        context
                            .read<MedicationBloc>()
                            .add(DeleteDoseEvent(dose.id));
                      } else if (direction == DismissDirection.startToEnd &&
                          isMostRecent) {
                        // Swipe left to unmark
                        context.read<MedicationBloc>().add(
                              UpdateDoseStatusEvent(
                                dose,
                                DoseStatus.upcoming,
                                refreshPastDoses: true,
                              ),
                            );
                      }
                    },
                    background: isMostRecent
                        ? Container(
                            color: Colors.blue,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(Icons.undo, color: Colors.white),
                          )
                        : Container(),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: PastDoseListItem(
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
                                      DoseStatus.upcoming,
                                      refreshPastDoses: true,
                                    ),
                                  );
                            }
                          : null,
                      onImageTap: (imagePaths, initialIndex) =>
                          _showImageFullScreen(context, dose.medicationName,
                              imagePaths, initialIndex),
                    ),
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
