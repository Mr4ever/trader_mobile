import 'package:flutter/material.dart';
import 'services/api.dart';

// الصفحات
import 'screens/home_page.dart';
import 'screens/history_page.dart';
import 'screens/ml_page.dart';
import 'screens/settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TraderApp());
}

class TraderApp extends StatefulWidget {
  const TraderApp({super.key});

  @override
  State<TraderApp> createState() => _TraderAppState();
}

class _TraderAppState extends State<TraderApp> {
  late final Api api;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    api = Api(baseUrl: 'http://127.0.0.1:5000');
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(api: api),
      HistoryPage(api: api),
      MlPage(api: api),
      SettingsPage(api: api),
    ];

    return MaterialApp(
      title: 'Trader Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(child: pages[_index]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
            NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'ML'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
