import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'config/theme_config.dart';
import 'provider/app_provider.dart';
import 'provider/config_provider.dart';
import 'provider/player_provider.dart';
import 'routes/app_routes.dart';
import 'utils/locale_utils.dart';

class MBoxApp extends StatelessWidget {
  const MBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: GetMaterialApp(
        title: 'MBox',
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.lightTheme,
        darkTheme: ThemeConfig.darkTheme,
        themeMode: ThemeMode.dark,
        locale: LocaleUtils.currentLocale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
          Locale('en', 'US'),
        ],
        initialRoute: AppRoutes.home,
        getPages: AppRoutes.routes,
      ),
    );
  }
}
