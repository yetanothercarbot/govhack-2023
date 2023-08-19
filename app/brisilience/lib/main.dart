import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  var current = WordPair.random();
  var favourites = <WordPair>[];

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }


  void toggleFavourite() {
    if (favourites.contains(current)) {
      favourites.remove(current);
    } else {
      favourites.add(current);
    }
    notifyListeners();
  }
}

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
        page = FavouritesList();
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
          appBar: AppBar(title: Text(widget.title)),
          bottomNavigationBar: BottomAppBar(
            child: Row(),
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
    var pair = appState.current;

    IconData icon;
    if (appState.favourites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavourite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FavouritesList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favourites = appState.favourites;

    return ListView(
      children: [for (var fav in favourites) Text(fav.asLowerCase)],
    );
  }
}

class SurvivalPlan extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );


    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(pair.asLowerCase, style: style, semanticsLabel: "${pair.first} ${pair.second}"),
      ),
    );
  }
}
