import 'package:flutter/material.dart';

import '../constants/buildings.dart';

Widget carouselCard(int index, num distance, num duration) {
  return Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/image/bikoura.jpg'),
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buildings[index]['name'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(buildings[index]['items'],
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(
                  '${distance.toStringAsFixed(2)}kms, ${duration.toStringAsFixed(2)} mins',
                  style: const TextStyle(color: Colors.tealAccent),
                )
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
