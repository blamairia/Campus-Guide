import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class buildingsTable extends StatefulWidget {
  final List<dynamic> buildings;

  const buildingsTable({Key? key, required this.buildings}) : super(key: key);

  @override
  State<buildingsTable> createState() => _buildingsTableState();
}

class _buildingsTableState extends State<buildingsTable> {
  _buildingsTableState();

  Widget cardButtons(IconData iconData, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(5),
          minimumSize: Size.zero,
        ),
        child: Row(
          children: [
            Icon(iconData, size: 16),
            const SizedBox(width: 2),
            Text(label)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('buildings Table'),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoTextField(
                prefix: Padding(
                  padding: EdgeInsets.only(left: 15),
                  child: Icon(Icons.search),
                ),
                padding: EdgeInsets.all(15),
                placeholder: 'Search For a Building or a place by name',
                style: TextStyle(color: Colors.white),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
              const SizedBox(height: 5),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.buildings.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/image/${widget.buildings[index]['image']}',
                          height: MediaQuery.of(context).size.height / 4,
                          width: MediaQuery.of(context).size.width / 3,
                          fit: BoxFit.cover,
                        ),
                        Expanded(
                          child: Container(
                            height: 200,
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.buildings[index]['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(widget.buildings[index]['items']),
                                const Spacer(),
                                Row(
                                  children: [
                                    cardButtons(Icons.call, 'Call'),
                                    cardButtons(Icons.location_on, 'Map'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      )),
    );
  }
}
