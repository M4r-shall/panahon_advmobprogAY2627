import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
 
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const StateManagementApp(),
    ),
  );
}

//listener if the trheme is changed
 
class ThemeModel with ChangeNotifier {
  bool _isDark = false;
 
  bool get isDark => _isDark;
 
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// sets ups the theme and home screen
 
class StateManagementApp extends StatelessWidget {
  const StateManagementApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);
 
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'State Management Combined',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MyHomePage(),
    );
  }
}
 
// increment counter on homescreen

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
 
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
 
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
 
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral State Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Go to App State Example',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeStatePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// App state screen
class ThemeStatePage extends StatelessWidget {
  const ThemeStatePage({super.key});
 
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('App State Example'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // const Icon(Icons.brightness_6),
                Switch(
                  value: themeModel.isDark,
                  onChanged: (_) => themeModel.toggleTheme(), //toggle light and dark
                ),
              ],
            ),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Toggle the theme using the switch in the app bar.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}