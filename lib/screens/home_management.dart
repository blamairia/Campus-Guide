import 'package:flutter/material.dart';
import 'package:ubmap/constants/buildings.dart';
import 'package:ubmap/screens/university_map.dart';
import 'package:ubmap/screens/university_table.dart';

class HomeManagement extends StatefulWidget {
  final List<Map> buildings;
  final int initialCampusIndex;

  const HomeManagement({
    super.key,
    required this.buildings,
    this.initialCampusIndex = 0,
  });

  @override
  State<HomeManagement> createState() => _HomeManagementState();
}

class _HomeManagementState extends State<HomeManagement> {
  int _pageIndex = 0;
  late List<Map> _currentBuildings;
  late int _campusIndex;

  static const List<String> campusNames = [
    'University Sidi Amar',
    'University Bouni',
    'University Sidi Achor',
  ];

  static List<List<Map>> get campusList => [buildings, buildings2, buildings3];

  @override
  void initState() {
    super.initState();
    _campusIndex = widget.initialCampusIndex;
    _currentBuildings = widget.buildings;
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _switchCampus(int index) {
    setState(() {
      _campusIndex = index;
      _currentBuildings = campusList[index];
    });
    // Close using pop if it was opened via standard navigation, or try scaffold key
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pass callback to open drawer
    final pages = [
      UniversityMap(
        key: ValueKey(_campusIndex),
        buildings: _currentBuildings,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      buildingsTable(buildings: _currentBuildings),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.green.shade700,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.school, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Campus Guide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campusNames[_campusIndex],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SWITCH CAMPUS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              ...List.generate(campusNames.length, (index) {
                final isSelected = _campusIndex == index;
                return ListTile(
                  leading: Icon(
                    Icons.location_city,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    campusNames[index],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.green : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _switchCampus(index),
                );
              }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: 'Campus Guide',
                    applicationVersion: '2.0.0',
                    applicationLegalese: '© 2024 University Annaba',
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _pageIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (selectedIndex) {
          setState(() {
            _pageIndex = selectedIndex;
          });
        },
        currentIndex: _pageIndex,
        selectedItemColor: Colors.green.shade700,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Buildings',
          ),
        ],
      ),
    );
  }
}
