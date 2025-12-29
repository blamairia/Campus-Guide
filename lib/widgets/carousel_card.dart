import 'package:flutter/material.dart';
import 'package:ubmap/helpers/distance_utils.dart';

Widget carouselCard(Map building, num distanceKm, num durationMin) {
  return Card(
    clipBehavior: Clip.antiAlias,
    elevation: 4,
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade800, Colors.grey.shade900],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Image
            CircleAvatar(
              backgroundImage: AssetImage('assets/image/${building['image']}'),
              radius: 24,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    building['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_walk, size: 14, color: Colors.tealAccent.shade200),
                      const SizedBox(width: 4),
                      Text(
                        formatDistance(distanceKm * 1000),
                        style: TextStyle(color: Colors.tealAccent.shade200, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 14, color: Colors.tealAccent.shade200),
                      const SizedBox(width: 4),
                      Text(
                        '${durationMin.round()} min',
                        style: TextStyle(color: Colors.tealAccent.shade200, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Navigate icon
            const Icon(Icons.navigation, color: Colors.tealAccent, size: 24),
          ],
        ),
      ),
    ),
  );
}
