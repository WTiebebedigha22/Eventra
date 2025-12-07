import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final _ref = FirebaseFirestore.instance.collection('events');

  Future<List<EventModel>> fetchEvents() async {
    final snap = await _ref.get();
    return snap.docs.map((e) => EventModel.fromMap(e.data(), e.id)).toList();
  }

  Future<EventModel?> getEvent(String id) async {
    final doc = await _ref.doc(id).get();
    if (!doc.exists) return null;
    return EventModel.fromMap(doc.data()!, doc.id);
  }

  Stream<EventModel?> streamEvent(String id) {
    return _ref.doc(id).snapshots().map(
          (snap) => snap.exists
              ? EventModel.fromMap(snap.data()!, snap.id)
              : null,
        );
  }
}
