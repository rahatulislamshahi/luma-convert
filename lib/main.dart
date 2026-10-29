import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_storage.dart';
import 'core/converter_controller.dart';
import 'ui/converter_screen.dart';
import 'ui/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final controller = ConverterController(DeviceStorage());
  await controller.restore();
  runApp(LumaConvertApp(controller: controller));
}

class LumaConvertApp extends StatelessWidget {
  const LumaConvertApp({super.key, required this.controller});

  final ConverterController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final palette = AppPalette(controller.dark);
      return MaterialApp(
        title: 'Luma Convert',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: controller.dark ? Brightness.dark : Brightness.light,
          scaffoldBackgroundColor: palette.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: palette.accentStrong,
            brightness: controller.dark ? Brightness.dark : Brightness.light,
          ),
          textTheme:
              ThemeData(
                brightness: controller.dark
                    ? Brightness.dark
                    : Brightness.light,
              ).textTheme.apply(
                fontFamily: 'Roboto',
                bodyColor: palette.text,
                displayColor: palette.text,
              ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: palette.operator,
            contentTextStyle: TextStyle(color: palette.text),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              (controller.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarDividerColor: Colors.transparent,
                  ),
          child: ConverterScreen(controller: controller),
        ),
      );
    },
  );
}
