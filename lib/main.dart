import 'package:flutter/material.dart';

import 'screens/root_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HolesApp());
}

class HolesApp extends StatelessWidget {
  const HolesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Holes',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.dark),
      home: const RootScreen(),
    );
  }
}
