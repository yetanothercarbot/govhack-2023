import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'main.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedPageIndex = 0;


  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedPageIndex) {
      case 0:
        page = ShortTermPage();
        break;
      case 1:
        page = LongTermPage();
        break;
      case 2:
        page = SurvivalPlan();
        break;
      case 3:
        page = SurvivalPlanEdit();
        break;
      default:
        throw UnimplementedError('No widget for $selectedPageIndex');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.title)), // TODO: Make background #006bb6, with a #ffd51a stripe on the right
          bottomNavigationBar: BottomAppBar(
            child: LocationIndicator(),
          ),
          floatingActionButton: Visibility(
            visible: selectedPageIndex == 2,
            child: FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              onPressed: () {selectedPageIndex = 3;},
              child: const Icon(Icons.edit), 
              )
          ),
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    title: const Text('Current Risks'),
                    selected: selectedPageIndex == 0,
                    onTap: () {
                      setState(() {
                        selectedPageIndex = 0;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Long-term Risks'),
                    selected: selectedPageIndex == 1,
                    onTap: () {
                      setState(() {
                        selectedPageIndex = 1;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Survival Plan'),
                    selected: selectedPageIndex == 2,
                    onTap: () {
                      setState(() {
                        selectedPageIndex = 2;
                      });
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            ),
          ),
          body: Row(
            children: [
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}


class ShortTermPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return SafeArea(child: ListView(
      children: [
        Card(
          child: ExpansionTile(
            title: Text('Fire Risk'),
            subtitle: Text('High'),
            initiallyExpanded: true,
            trailing: Icon(Icons.warning_amber),
            children: [
              Card(
                child: Text('QFES has issued a Watch and Act for a fire that is currently 6.9km from your address.'),
              ),
              SvgPicture.asset('assets/fire-risk-high.svg', semanticsLabel: 'Fire Risk ${appState.fireRiskDesc}',)
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text('Flood Risk'),
            subtitle: Text('Not currently at risk'),
            children: [
              Text('This uses data from water level sensors situated in nearby creeks and rivers. Based on their levels, your location should not be at risk of flooding currently '),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text('Cyclone Risk'),
            children: [
              SizedBox(height: 60, child: Placeholder(),),
            ],
          ),
        ),
      ]

    ));
  }
}

/* Page that shows the long-term risks */
class LongTermPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return SafeArea(child: ListView(
      children: [
        Card(
          child: ExpansionTile(
            title: Text('Flooding Potential'),
            subtitle: Text('High Risk - Action Needed'),
            children: [
              Text('This is a high-risk area. Consider stocking sandbags and making sure you know your escape routes. Please fill out your survival plan!'),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text('Bushfire Risk'),
            subtitle: Text('Low Risk - No Action Needed'),
            children: [
              Text('You shouldn\'t need to do anything. Make sure to fill out your survival plan.'),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text('Cyclone Risk'),
            children: [
              SizedBox(height: 60, child: Placeholder(),),
            ],
          ),
        ),
      ]

    ));
  }
}

/* Page that allows the user to create, and edit, a survival plan */
class SurvivalPlan extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

class SurvivalPlanEdit extends StatefulWidget {
  @override
  State<SurvivalPlanEdit> createState() => _SurvivalPlanEditState();
}

class _SurvivalPlanEditState extends State<SurvivalPlanEdit> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

class LocationIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Align(alignment: Alignment.centerLeft, child: Text('Location: Waiting on GPS...')),
      Align(alignment: Alignment.centerRight, child: CircularProgressIndicator())
    ],);
  }
}