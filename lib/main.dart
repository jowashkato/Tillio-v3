import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'helpers/AppTheme.dart';
import 'helpers/routes.dart';
import 'locale/MyLocalizations.dart';
import 'pages/notifications/view_model_manger/notifications_cubit.dart';
import 'pages/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  AppLanguage appLanguage = AppLanguage();

  try {
    await appLanguage.fetchLocale();
  } catch (e) {
    debugPrint("Locale error: $e");
  }

  runApp(MyApp(appLanguage: appLanguage));
}

class MyApp extends StatelessWidget {
  final AppLanguage? appLanguage;

  const MyApp({super.key, this.appLanguage});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = NotificationsCubit();
        try {
          cubit.getNotification();
        } catch (e) {
          debugPrint("Notification error: $e");
        }
        return cubit;
      },
      child: ChangeNotifierProvider<AppLanguage>(
        create: (_) => appLanguage!,
        child: Consumer<AppLanguage>(
          builder: (context, model, child) {
            return MaterialApp(
              routes: Routes.generateRoute(),
              initialRoute: '/splash',
              onUnknownRoute: (settings) => MaterialPageRoute(
                builder: (_) => const Splash(),
              ),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getThemeFromThemeMode(1),
              locale: model.appLocal,
              supportedLocales: Config().supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              builder: (context, child) {
                return child ?? const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}
