import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/i18n.dart'; // AG_I18N1
import 'core/nav.dart' show agMessengerKey; // AG_FIX5
import 'core/notifications_service.dart';
import 'core/repair_push.dart';
import 'core/router.dart';
import 'core/security/app_lock_gate.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/tap_ripple.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/booking/data/booking_repository.dart';
import 'features/booking/data/notifications_repository.dart';
import 'features/booking/providers/booking_flow_provider.dart';
import 'features/booking/providers/my_bookings_provider.dart';
import 'features/booking/providers/notifications_provider.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/my_cars/data/my_cars_repository.dart';
import 'features/my_cars/providers/my_cars_provider.dart';
import 'features/booking/data/referrals_repository.dart';
import 'features/booking/data/company_repository.dart';
import 'features/booking/providers/referrals_provider.dart';
import 'features/booking/providers/company_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await initializeDateFormatting(); } catch (_) {} // AG_FIX4 + AG_I18N1: даты на всех языках
  await AgI18n.init(); // AG_I18N1
  final apiClient = ApiClient();
  RepairPush.attach(apiClient);

  final notificationsRepo = NotificationsRepository(apiClient);
  final notificationsService = NotificationsService(notificationsRepo);
  try {
    await notificationsService.init().timeout(const Duration(seconds: 10)); // AG_FIX4
  } catch (_) {}

  final authProvider = AuthProvider(
    AuthRepository(apiClient),
    apiClient,
    notificationsService,
  );
  try {
    await authProvider.init().timeout(const Duration(seconds: 6)); // AG_FIX4
  } catch (_) {}

  final appRouter = createAppRouter(authProvider);
  RepairPush.listenTaps(appRouter);

  runApp(
    AGServiceApp(
      apiClient: apiClient,
      authProvider: authProvider,
      appRouter: appRouter,
      notificationsRepo: notificationsRepo,
      notificationsService: notificationsService,
    ),
  );
}

class AGServiceApp extends StatelessWidget {
  const AGServiceApp({
    super.key,
    required this.apiClient,
    required this.authProvider,
    required this.appRouter,
    required this.notificationsRepo,
    required this.notificationsService,
  });

  final ApiClient apiClient;
  final AuthProvider authProvider;
  final GoRouter appRouter;
  final NotificationsRepository notificationsRepo;
  final NotificationsService notificationsService;

  @override
  Widget build(BuildContext context) {
    final repository = BookingRepository(apiClient);

    return ValueListenableBuilder<String>( // AG_I18N1: смена языка перестраивает приложение
      valueListenable: AgI18n.lang,
      builder: (context, _, __) => MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<BookingRepository>.value(value: repository),
        Provider<ChatRepository>(create: (_) => ChatRepository(apiClient)),
        Provider<NotificationsRepository>.value(value: notificationsRepo),
        Provider<NotificationsService>.value(value: notificationsService),
        Provider<ReferralsRepository>(
          create: (_) => ReferralsRepository(apiClient),
        ),
        Provider<CompanyRepository>(
          create: (_) => CompanyRepository(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider(notificationsRepo),
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => BookingFlowProvider()),
        ChangeNotifierProvider(create: (_) => MyBookingsProvider(repository)),
        ChangeNotifierProvider(
          create: (ctx) => ReferralsProvider(ctx.read<ReferralsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CompanyProvider(ctx.read<CompanyRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => MyCarsProvider(MyCarsRepository(apiClient)),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = context.watch<ThemeProvider>();

          return MaterialApp.router(
            title: 'AG Service',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: agMessengerKey, // AG_FIX5
            theme: buildAppTheme(),
            darkTheme: buildDarkAppTheme(),
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter,
            builder: (context, child) {
              return MediaQuery.withClampedTextScaling( // AG_FIX3
                minScaleFactor: 0.9,
                maxScaleFactor: 1.15,
                child: TapRipple(
                  child: AppLockGate(child: child ?? const SizedBox.shrink()),
                ),
              );
            },
            locale: const Locale('ru'),
            supportedLocales: const [Locale('ru'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    ));
  }
}
