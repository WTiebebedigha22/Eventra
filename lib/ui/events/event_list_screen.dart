import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/components/event_tile.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final sample = List.generate(6, (i) => i);
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.7
        ),
        itemCount: sample.length,
        itemBuilder: (c, i) => const EventTile(),
      ),
    );
  }
}
