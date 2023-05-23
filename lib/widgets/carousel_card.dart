import 'package:flutter/material.dart';

Widget carouselCard(Map building, num distance, num duration) {
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/image/' + building['image']),
                  radius: constraints.maxWidth * 0.10, // 10% of parent width
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        building['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Flexible(
                      child: Text(
                        '${distance.toStringAsFixed(2)}kms,'
                        ' \n ${duration.toStringAsFixed(2)} mins',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.tealAccent),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
