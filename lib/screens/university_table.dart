import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ubmap/constants/app_theme.dart';
import 'package:ubmap/constants/buildings.dart';
import 'package:ubmap/helpers/distance_utils.dart';
import 'package:ubmap/screens/navigation_screen.dart';
import 'package:ubmap/services/navigation_service.dart';

/// Clean, production-ready buildings list screen
/// Inspired by Google Maps place list design
class BuildingsTable extends StatefulWidget {
  final List<Map> buildings;

  const BuildingsTable({super.key, required this.buildings});

  @override
  State<BuildingsTable> createState() => _BuildingsTableState();
}

class _BuildingsTableState extends State<BuildingsTable>
    with TickerProviderStateMixin {
  // State
  String _searchQuery = '';
  BuildingType? _selectedFilter;
  List<Map> _filteredBuildings = [];
  bool _isLoading = true;
  double? _userLat;
  double? _userLng;
  Map<int, double> _distances = {};

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final NavigationService _navigationService = NavigationService();
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _filteredBuildings = widget.buildings;
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BuildingsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buildings != widget.buildings) {
      _applyFilters();
      _calculateDistances();
    }
  }

  Future<void> _initializeData() async {
    // Get user location for distance calculation
    final position = await _navigationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
      _calculateDistances();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _listAnimationController.forward();
    }
  }

  void _calculateDistances() {
    if (_userLat == null || _userLng == null) return;

    _distances = {};
    for (var building in widget.buildings) {
      final lat = double.parse(
          building['coordinates']['latitude'].toString().trim());
      final lng = double.parse(
          building['coordinates']['longitude'].toString().trim());
      _distances[building['id']] = haversineDistance(_userLat!, _userLng!, lat, lng);
    }
    if (mounted) setState(() {});
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

      // Sort by distance if available
      if (_distances.isNotEmpty) {
        _filteredBuildings.sort((a, b) {
          final distA = _distances[a['id']] ?? double.infinity;
          final distB = _distances[b['id']] ?? double.infinity;
          return distA.compareTo(distB);
        });
      }
    });

    // Restart animation for filtered list
    _listAnimationController.reset();
    _listAnimationController.forward();
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _onFilterSelected(BuildingType? type) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFilter = (_selectedFilter == type) ? null : type;
    });
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    _onSearchChanged('');
  }

  void _navigateToBuilding(Map building) {
    HapticFeedback.lightImpact();
    final lat = double.parse(
        building['coordinates']['latitude'].toString().trim());
    final lng = double.parse(
        building['coordinates']['longitude'].toString().trim());

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
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            _buildHeader(),

            // Filter pills
            _buildFilterPills(),

            // Divider
            Container(height: 1, color: AppTheme.divider),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredBuildings.isEmpty
                      ? _buildEmptyState()
                      : _buildBuildingsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.bgSurface,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Icon(
                Icons.location_city,
                color: AppTheme.primary,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              const Expanded(
                child: Text(
                  'Campus Buildings',
                  style: AppTheme.headingMedium,
                ),
              ),
              // Results count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: AppTheme.borderRadiusFull,
                ),
                child: Text(
                  '${_filteredBuildings.length}',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Search bar
          Container(
            decoration: AppTheme.searchBarDecoration,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search buildings...',
                hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textHint),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textHint,
                ),
                suffixIcon: AnimatedOpacity(
                  opacity: _searchQuery.isNotEmpty ? 1.0 : 0.0,
                  duration: AppAnimations.fast,
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    color: AppTheme.textSecondary,
                    onPressed: _clearSearch,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusFull,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return Container(
      height: 56,
      color: AppTheme.bgSurface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingSm,
        ),
        children: [
          _buildFilterChip(null, 'All', Icons.apps),
          ...BuildingType.values.map((type) {
            return _buildFilterChip(
              type,
              buildingTypeLabels[type] ?? '',
              _getTypeIcon(type),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildingType? type, String label, IconData icon) {
    final isSelected = _selectedFilter == type ||
        (type == null && _selectedFilter == null);

    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onFilterSelected(type),
            borderRadius: AppTheme.borderRadiusFull,
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: AppTheme.chipDecoration(isSelected: isSelected),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    label,
                    style: AppTheme.labelSmall.copyWith(
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(BuildingType type) {
    switch (type) {
      case BuildingType.department:
        return Icons.business;
      case BuildingType.amphitheatre:
        return Icons.event_seat;
      case BuildingType.library:
        return Icons.local_library;
      case BuildingType.admin:
        return Icons.admin_panel_settings;
      case BuildingType.bloc:
        return Icons.apartment;
      case BuildingType.research:
        return Icons.science;
      case BuildingType.other:
        return Icons.place;
    }
  }

  Widget _buildBuildingsList() {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await _initializeData();
      },
      color: AppTheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        itemCount: _filteredBuildings.length,
        itemBuilder: (context, index) {
          return _buildAnimatedCard(index);
        },
      ),
    );
  }

  Widget _buildAnimatedCard(int index) {
    // Staggered animation
    final delay = index * 0.05;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Interval(
          delay.clamp(0.0, 0.7),
          (delay + 0.3).clamp(0.0, 1.0),
          curve: AppAnimations.defaultCurve,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: _buildBuildingCard(_filteredBuildings[index]),
    );
  }

  Widget _buildBuildingCard(Map building) {
    final type = building['type'] as BuildingType?;
    final typeLabel = type != null ? buildingTypeLabels[type] : 'Other';
    final typeColor = type != null
        ? AppTheme.buildingTypeColors[type.name] ?? AppTheme.textHint
        : AppTheme.textHint;
    final distance = _distances[building['id']];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToBuilding(building),
          borderRadius: AppTheme.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                // Thumbnail
                Hero(
                  tag: 'building_img_${building['id']}',
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: AppTheme.borderRadiusSm,
                      image: DecorationImage(
                        image: AssetImage('assets/image/${building['image']}'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.spacingMd),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        building['name'],
                        style: AppTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: AppTheme.spacingXs),

                      // Type badge + Distance
                      Row(
                        children: [
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: AppTheme.borderRadiusSm,
                            ),
                            child: Text(
                              typeLabel ?? 'Other',
                              style: AppTheme.bodySmall.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          // Distance
                          if (distance != null) ...[
                            const SizedBox(width: AppTheme.spacingSm),
                            Icon(
                              Icons.directions_walk,
                              size: 14,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              formatDistance(distance),
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Navigate chevron
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: AppTheme.borderRadiusFull,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 40,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No buildings found',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Try clearing the filter',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            if (_searchQuery.isNotEmpty || _selectedFilter != null)
              TextButton.icon(
                onPressed: () {
                  _clearSearch();
                  _onFilterSelected(null);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Show all buildings'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              // Shimmer thumbnail
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.shimmerBase,
                  borderRadius: AppTheme.borderRadiusSm,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.shimmerBase,
                        borderRadius: AppTheme.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.shimmerBase,
                        borderRadius: AppTheme.borderRadiusSm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Helper widget for staggered animations
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
