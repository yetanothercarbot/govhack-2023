import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Brisilience',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(title: "Brisilience"),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  late int fireRiskIndex;
  String fireRiskDesc = "Fire Risk Indicator";
}

