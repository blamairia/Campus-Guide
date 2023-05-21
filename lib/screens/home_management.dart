import 'package:flutter/material.dart';
import 'package:ubmap/screens/university_map.dart';
import 'package:ubmap/screens/university_table.dart';

class HomeManagement extends StatefulWidget {
  final List<Map> buildings;

  const HomeManagement({Key? key, required this.buildings}) : super(key: key);

  @override
  State<HomeManagement> createState() => _HomeManagementState();
}

class _HomeManagementState extends State<HomeManagement> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      UniversityMap(buildings: widget.buildings),
      buildingsTable(buildings: widget.buildings),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
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
