import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pautamedica/features/medication/data/notification_service.dart';
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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _notificationService.flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _configureDidReceiveLocalNotificationSubject();
    _checkNotificationLaunch();
  }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationStream.stream
        .listen((notificationResponse) async {
      _handleNotificationNavigation();
    });
  }

  Future<void> _checkNotificationLaunch() async {
    final notificationAppLaunchDetails =
        await _notificationService.flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      _handleNotificationNavigation();
    }
  }

  void _handleNotificationNavigation() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const UpcomingDosesPage()),
      (route) => route.isFirst,
    );
    _notificationService.cancelAllNotifications();
  }

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
        navigatorKey: navigatorKey,
        title: 'Pauta Médica',
        theme: ThemeData(
          fontFamily: 'Roboto',
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
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
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.deepPurple.shade900,
            foregroundColor: Colors.white,
            elevation: 8,
            highlightElevation: 16,
            extendedPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
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
