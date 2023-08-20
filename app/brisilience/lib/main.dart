import 'package:brisilience/api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui.dart';

void main() {
  var api = BrisilienceApi();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'SEQPrepare',
        theme: ThemeData(
          useMaterial3: true,
          // colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: MyHomePage(title: "SEQPrepare"),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  late int fireRiskIndex;
  String fireRiskDesc = "Fire Risk Indicator";
}

