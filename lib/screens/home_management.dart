import 'package:flutter/material.dart';
import 'package:mapbox_navigation/screens/university_map.dart';
import 'package:mapbox_navigation/screens/university_table.dart';

class HomeManagement extends StatefulWidget {
  const HomeManagement({Key? key}) : super(key: key);

  @override
  State<HomeManagement> createState() => _HomeManagementState();
}

class _HomeManagementState extends State<HomeManagement> {
  final List<Widget> _pages = [const UniversityMap(), const buildingsTable()];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (selectedIndex) {
          setState(() {
            _index = selectedIndex;
          });
        },
        currentIndex: _index,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.map), label: 'University Maps'),
          BottomNavigationBarItem(
              icon: Icon(Icons.business_outlined),
              label: 'University Buildings'),
        ],
      ),
    );
  }
}
