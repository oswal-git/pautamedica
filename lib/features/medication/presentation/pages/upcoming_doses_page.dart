import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/pages/medication_list_page.dart';
import 'package:pautamedica/features/medication/presentation/pages/past_doses_page.dart';
import 'package:pautamedica/features/medication/presentation/widgets/dose_list_item.dart';

class UpcomingDosesPage extends StatelessWidget {
  const UpcomingDosesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Load upcoming doses when the page is built
    context.read<MedicationBloc>().add(LoadUpcomingDoses());

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
              );
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
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MedicationBloc, MedicationState>(
        builder: (context, state) {
          if (state is MedicationLoading) {
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
                    context.read<MedicationBloc>().add(UpdateDoseStatus(dose, status));
                  },
                );
              },
            );
          }
          if (state is MedicationError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Algo salió mal.'));
        },
      ),
    );
  }
}
