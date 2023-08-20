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
            subtitle: Text('High - Watch and Act - Action Needed.'),
            initiallyExpanded: true,
            trailing: Icon(Icons.warning),
            children: [
              Card(
                child: Text('QFES has issued a Watch and Act for a fire that is currently 6.5km from your address. Please review your survival plan and be prepared to take action.'),
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
    return SafeArea(child: ListView(
      children: [
        Card(
          child: ExpansionTile(
            title: Text('Basic details set'),
            trailing: Icon(Icons.check),
            expandedAlignment: Alignment.topLeft,
            children: [
              Text('\u2022 Evacuation destination: Set, and meets recommendations.\n\u2022 Exit Route: Set, and meets recommendations'),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text('Survival Bag Packed'),
            subtitle: Text('You have indicated that your go bag is packed'),
            trailing: Icon(Icons.check),
            expandedAlignment: Alignment.topLeft,
            children: [
              Text('''Your survival bag should contain:
\u2022 Sufficient non-perishable food & drink
\u2022 First Aid Kit
\u2022 Radio with batteries
\u2022 Prescription Medication
\u2022 Sufficient fuel for evacuation
\u2022 Photocopies of important documents (including identification, health information, prescriptions, insurance)'''),
            ],
          ),
        ),
        Row(children: [
          ElevatedButton.icon(
            onPressed: () {}, 
            icon: Icon(Icons.download),
            label: Text('Save as PDF')
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.share),
            label: Text('Share')
          ),
        ],),
        ElevatedButton(
          onPressed: () {
            showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Before you go...'),
                content: SizedBox(
                  width: 300,
                  height: 300,
                  child: Text('''Make sure you have the following:
\u2022 Everybody who is evacuating with you
\u2022 Pets or animals
\u2022 Survival bag
                  ''')
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'OK'),
                    child: const Text('OK'),
                  ),
                ],
              );
            });
          }, 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: Text('I\'m evacuating', style: TextStyle(fontSize: 25),)
        ),
      ],
    ),);
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