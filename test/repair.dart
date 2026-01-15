import 'package:cloud_firestore/cloud_firestore.dart';
Future<void> repairMissingTimestamps() async {
  final postsRef = FirebaseFirestore.instance.collection('posts');
  
  // 1. Get all posts (we don't use orderBy here because it would hide the broken ones)
  final snapshot = await postsRef.get();
  
  WriteBatch batch = FirebaseFirestore.instance.batch();
  int count = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();
    
    // 2. Check if createdAt is missing or null
    if (!data.containsKey('createdAt') || data['createdAt'] == null) {
      batch.update(doc.reference, {
        'createdAt': FieldValue.serverTimestamp(),
      });
      count++;
    }
  }

  // 3. Commit the changes
  if (count > 0) {
    await batch.commit();
    print("Successfully repaired $count posts!");
  } else {
    print("No repairs needed. All posts have timestamps.");
  }
}