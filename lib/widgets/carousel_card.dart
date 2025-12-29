import 'package:flutter/material.dart';
import 'package:ubmap/constants/app_theme.dart';
import 'package:ubmap/helpers/distance_utils.dart';

/// Carousel card for map view
/// Height-constrained to fit within carousel without overflow
Widget carouselCard(Map building, num distanceKm, num durationMin) {
  return Container(
    height: 80, // Fixed height to prevent overflow
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.bgSurface,
      borderRadius: AppTheme.borderRadiusMd,
      boxShadow: AppTheme.shadowSm,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          // Thumbnail - smaller to fit
          ClipRRect(
            borderRadius: AppTheme.borderRadiusSm,
            child: Image.asset(
              'assets/image/${building['image']}',
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 52,
                height: 52,
                color: AppTheme.bgElevated,
                child: const Icon(Icons.image, color: AppTheme.textHint),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),

          // Info - Use Expanded to prevent overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Building name
                Text(
                  building['name'],
                  style: AppTheme.titleMedium.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Distance and time in single row with overflow protection
                Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      size: 12,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      formatDistance(distanceKm * 1000),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '${durationMin.round()} min',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Navigate button - smaller
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right,
              color: AppTheme.textOnPrimary,
              size: 18,
            ),
          ),
        ],
      ),
    ),
  );
}
