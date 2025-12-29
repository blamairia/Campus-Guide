import 'package:flutter/material.dart';
import 'package:ubmap/constants/buildings.dart';
import 'package:ubmap/screens/navigation_screen.dart';

class buildingsTable extends StatefulWidget {
  final List<Map> buildings;

  const buildingsTable({super.key, required this.buildings});

  @override
  State<buildingsTable> createState() => _buildingsTableState();
}

class _buildingsTableState extends State<buildingsTable> {
  String _searchQuery = '';
  BuildingType? _selectedFilter;
  List<Map> _filteredBuildings = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredBuildings = widget.buildings;
  }

  @override
  void didUpdateWidget(buildingsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buildings != widget.buildings) {
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBuildings = widget.buildings.where((building) {
        // Filter by type
        if (_selectedFilter != null && building['type'] != _selectedFilter) {
          return false;
        }
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final name = building['name'].toString().toLowerCase();
          if (!name.contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _onFilterSelected(BuildingType? type) {
    setState(() {
      if (_selectedFilter == type) {
        _selectedFilter = null; // Deselect
      } else {
        _selectedFilter = type; // Select
      }
    });
    _applyFilters();
  }

  void _navigateToBuilding(Map building) {
    final lat = double.parse(building['coordinates']['latitude'].toString().trim());
    final lng = double.parse(building['coordinates']['longitude'].toString().trim());
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(
          destinationLat: lat,
          destinationLng: lng,
          destinationName: building['name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Buildings'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.green.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.tealAccent,
              decoration: InputDecoration(
                hintText: 'Search buildings...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filter Chips
          Container(
            height: 50,
            color: Colors.grey.shade50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildFilterChip(null, 'All'),
                ...BuildingType.values.map((type) {
                  return _buildFilterChip(type, buildingTypeLabels[type] ?? '');
                }),
              ],
            ),
          ),

          // Buildings List
          Expanded(
            child: _filteredBuildings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No buildings found',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredBuildings.length,
                    itemBuilder: (context, index) {
                      return _buildBuildingCard(_filteredBuildings[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildingType? type, String label) {
    final isSelected = _selectedFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onFilterSelected(type),
        backgroundColor: Colors.white,
        selectedColor: Colors.green.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.green.shade700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingCard(Map building) {
    final type = building['type'] as BuildingType?;
    final typeLabel = type != null ? buildingTypeLabels[type] : 'Building';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToBuilding(building),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Hero(
              tag: 'building_img_${building['id']}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/image/${building['image']}'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        typeLabel ?? 'Other',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.directions, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
