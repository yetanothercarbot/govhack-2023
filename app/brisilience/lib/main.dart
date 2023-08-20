import 'package:brisilience/api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'ui.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
          title: 'SEQPrepare',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: MyHomePage(title: "SEQPrepare"),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  serverApi api = serverApi("https://api.seqprepare.xyz");
  late Future<apiResponse> response;
  
  @override
  MyAppState() {
    response = api.fetch();
  }

}
