import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_theme.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/core/providers/locale_provder.dart';
import 'package:portal_assoc/core/providers/theme_provider.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/auth/data/auth_repository.dart';
import 'package:portal_assoc/features/auth/presentation/auth_controller.dart';
import 'package:portal_assoc/l10n/app_localizations.dart';
import 'package:portal_assoc/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      Provider<AuthController>(create: (_) => AuthController(StartState(), AuthRepository())),
    ],
    child: const ToastificationWrapper(
      child: MyApp(),
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp.router(
      title: 'iasemburocracia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', ''), // Portuguese
        Locale('en', ''), // English
      ],
      locale: locale,
      routerConfig: appRouter(authProvider),
    );
  }
}
