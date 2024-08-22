import 'package:flutter/material.dart';
import 'package:music_game/routes/map.dart';
import 'package:music_game/routes/profile.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> userArtists = [];
  final _navigatorKey = GlobalKey<NavigatorState>();
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
          destinations: const <Widget>[
            NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.handshake), label: 'Trade'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile')
          ],
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentTabIndex = index;
            });
            switch (index) {
              case 0:
                _navigatorKey.currentState?.pushNamed('/');
                break;
              case 1:
                _navigatorKey.currentState?.pushNamed('/trade');
                break;
              case 2:
                _navigatorKey.currentState?.pushNamed('/profile');
                break;
            }
          }),
      body: PopScope(
        // onPopInvokedWithResult: (bool didPop, Object? result) {
        //   if (_navigatorKey.currentState != null &&
        //       _navigatorKey.currentState!.canPop()) {
        //     _navigatorKey.currentState!.pop();
        //   }
        // },
        child: Navigator(
          key: _navigatorKey,
          initialRoute: '/',
          onGenerateRoute: (RouteSettings settings) {
            WidgetBuilder builder;
            switch (settings.name) {
              case '/':
                builder = (BuildContext context) => const MapScreen();
                break;
              // case '/trade':
              //   builder = (BuildContext context) => TradeScreen();
              //   break;
              case '/profile':
                builder = (BuildContext context) => const ProfileScreen();
                break;
              default:
                throw Exception('Invalid route: ${settings.name}');
            }
            return MaterialPageRoute(
              builder: builder,
              settings: settings,
            );
          },
        ),
      ),
    );
  }
}
