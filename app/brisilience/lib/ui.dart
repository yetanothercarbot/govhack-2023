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
              child: const Icon(Icons.edit), 
              backgroundColor: Colors.blueAccent,
              onPressed: () {selectedPageIndex = 3;}
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
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: Text('Fire Risk', style: theme.textTheme.headlineMedium)),
              SvgPicture.asset('assets/fire-risk.svg', semanticsLabel: 'Fire Risk ${appState.fireRiskDesc}',)
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: Text('Flood Risk', style: theme.textTheme.headlineMedium)),
              Align(alignment: Alignment.bottomRight, child: Text('Not currently at risk', style: theme.textTheme.headlineSmall),),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: Text('Cyclone Risk', style: theme.textTheme.headlineMedium)),
              Container(height: 60, child: Placeholder(),),
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
        ExpansionTile(
          title: Text('Flooding Potential'),
          subtitle: Text('High Risk'),
          children: [
            Text('This is a high-risk area. Consider stocking sandbags and making sure you know your escape routes.'),
          ],
        ),
        ExpansionTile(
          title: Text('Bushfire Risk'),
          subtitle: Text('Low Risk - No Action Needed'),
          children: [
            Text('You shouldn\'t need to do anything. Make sure to fill out your survival plan.'),
          ],
        ),
        ExpansionTile(
          title: Text('Cyclone Risk'),
          children: [
            Container(height: 60, child: Placeholder(),),
          ],
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