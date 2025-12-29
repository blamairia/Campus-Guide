import 'package:flutter/material.dart';
import 'package:ubmap/constants/app_theme.dart';
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
      BuildingsTable(buildings: _currentBuildings),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: AppTheme.bgSurface,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: AppTheme.borderRadiusMd,
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 32,
                        color: AppTheme.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    const Text(
                      'Campus Guide',
                      style: TextStyle(
                        color: AppTheme.textOnPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      campusNames[_campusIndex],
                      style: TextStyle(
                        color: AppTheme.textOnPrimary.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingSm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SWITCH CAMPUS',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textHint,
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
                    color: isSelected ? AppTheme.primary : AppTheme.textHint,
                  ),
                  title: Text(
                    campusNames[index],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primary)
                      : null,
                  onTap: () => _switchCampus(index),
                );
              }),
              const Divider(color: AppTheme.divider),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                title: Text(
                  'About',
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary),
                ),
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
        backgroundColor: AppTheme.bgSurface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textHint,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list),
            label: 'Buildings',
          ),
        ],
      ),
    );
  }
}
