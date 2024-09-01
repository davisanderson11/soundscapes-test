import 'package:flutter/material.dart';
import 'package:app/routes/map.dart';
import 'package:app/routes/collection.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final List<Widget> _tabs = [
    const MapScreen(),
    const Text(''),
    const CollectionScreen()
  ];
  final PageController _pageController = PageController();
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _tabs),
        bottomNavigationBar: NavigationBar(
            destinations: const <Widget>[
              NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
              NavigationDestination(
                  icon: Icon(Icons.repeat_rounded), label: 'Trade'),
              NavigationDestination(
                  icon: Icon(Icons.album), label: 'Collection')
            ],
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentTabIndex = index;
                _pageController.jumpToPage(index);
              });
            }));
  }
}
