import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/widgets/past_dose_list_item.dart';

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
        builder: (context, state) {
          if (state is MedicationLoading) {
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
                return PastDoseListItem(
                  dose: dose,
                  onDelete: () {
                    context.read<MedicationBloc>().add(DeleteDoseEvent(dose.id));
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