import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  const EventTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 6)
      ]),
      child: Column(children: const [
        SizedBox(height: 140, child: Center(child: Icon(Icons.event, size: 56))),
        Padding(padding: EdgeInsets.all(8.0), child: Text('Event title'))
      ]),
    );
  }
}
