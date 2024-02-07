import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'rust_doc.dart';

final localhostServer =
    InAppLocalhostServer(documentRoot: 'assets', port: 8793);

Future main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  if (!kIsWeb) {
    await localhostServer.start();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: ThemeData.light().copyWith(
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
        iconColor: const Color.fromARGB(255, 12, 56, 91),
        backgroundColor: const Color.fromARGB(50, 130, 130, 130),
        foregroundColor: const Color.fromARGB(255, 25, 25, 25),
      ))),
      darkTheme: ThemeData.dark().copyWith(
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
        iconColor: const Color.fromARGB(255, 151, 208, 255),
        backgroundColor: const Color.fromARGB(50, 130, 130, 130),
        foregroundColor: const Color.fromARGB(255, 221, 221, 221),
      ))),
      home: const InAppWebViewExampleScreen(),
    );
  }
}
