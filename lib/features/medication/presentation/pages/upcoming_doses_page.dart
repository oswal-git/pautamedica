import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/pages/medication_list_page.dart';
import 'package:pautamedica/features/medication/presentation/pages/past_doses_page.dart';
import 'package:pautamedica/features/medication/presentation/widgets/dose_list_item.dart';

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PastDosesPage(),
                ),
              ).then((_) {
                context.read<MedicationBloc>().add(LoadUpcomingDoses());
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.medication),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicationListPage(),
                ),
              ).then((_) {
                // When returning from MedicationListPage, reload the doses
                context.read<MedicationBloc>().add(LoadUpcomingDoses());
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
                return DoseListItem(
                  dose: dose,
                  onStatusChanged: (status) {
                    context
                        .read<MedicationBloc>()
                        .add(UpdateDoseStatusEvent(dose, status, refreshPastDoses: false)); // Explicitly set to false
                  },
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
}