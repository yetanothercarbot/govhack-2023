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

class LongTermPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Placeholder();
  }
}

class SurvivalPlan extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Placeholder();
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
              Text('Fire Risk', style: theme.textTheme.headlineMedium),
              SvgPicture.asset('assets/fire-risk.svg', semanticsLabel: 'Fire Risk ${appState.fireRiskDesc}',)
            ],
          ),
        ),
        ListTile(
          title: const Text('Fire Risk')
        ),
        ListTile(
          title: const Text('Flood Risk'),
        )
      ]


    ));
  }
}

class LocationIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}