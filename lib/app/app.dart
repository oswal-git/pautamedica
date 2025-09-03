import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/data/repositories/medication_repository_impl.dart';
import 'package:pautamedica/features/medication/domain/usecases/add_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/delete_medication.dart';
import 'package:pautamedica/features/medication/domain/usecases/generate_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_medications.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_past_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/get_upcoming_doses.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_dose_status.dart';
import 'package:pautamedica/features/medication/domain/usecases/update_medication.dart';
import 'package:pautamedica/features/medication/presentation/bloc/medication_bloc.dart';
import 'package:pautamedica/features/medication/presentation/pages/upcoming_doses_page.dart';


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
            create: (context) {
        final medicationRepository = MedicationRepositoryImpl();
        return MedicationBloc(
          getMedications: GetMedications(medicationRepository),
          addMedication: AddMedication(medicationRepository),
          updateMedication: UpdateMedication(medicationRepository),
          deleteMedication: DeleteMedication(medicationRepository),
          getUpcomingDoses: GetUpcomingDoses(medicationRepository),
          getPastDoses: GetPastDoses(medicationRepository),
          updateDoseStatus: UpdateDoseStatus(medicationRepository),
          generateDoses: GenerateDoses(medicationRepository),
        )..add(GenerateDosesEvent());
      },
      child: MaterialApp(
        // showPerformanceOverlay: true,
        title: 'Pauta Médica',
        theme: ThemeData(
          fontFamily: 'Roboto',
          useMaterial3: true,
          // Máximo contraste para accesibilidad
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          // Colores de texto con máximo contraste
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 48,
            ),
            displayMedium: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 36,
            ),
            bodyLarge: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            bodyMedium: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          // AppBar con máximo contraste
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.deepPurple.shade900,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: Colors.black54,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          // Botones flotantes con máximo contraste
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.deepPurple.shade900,
            foregroundColor: Colors.white,
            elevation: 8,
            highlightElevation: 16,
            extendedPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          // Colores de acento con más contraste
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple.shade900,
            brightness: Brightness.light,
          ).copyWith(
            primary: Colors.deepPurple.shade900,
            secondary: Colors.orange.shade700,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        home: const UpcomingDosesPage(),
      ),
    );
  }
}
