import 'package:flutter/material.dart';
import 'package:music_game/routes/map.dart';
import 'package:music_game/routes/profile.dart';

class App extends StatefulWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();

  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
          destinations: const <Widget>[
            NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
            NavigationDestination(
                icon: Icon(Icons.repeat_rounded), label: 'Trade'),
            NavigationDestination(icon: Icon(Icons.album), label: 'Collection')
          ],
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentTabIndex = index;
            });
            switch (index) {
              case 0:
                App.navigatorKey.currentState?.pushNamed('/');
                break;
              case 1:
                App.navigatorKey.currentState?.pushNamed('/trade');
                break;
              case 2:
                App.navigatorKey.currentState?.pushNamed('/profile');
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
