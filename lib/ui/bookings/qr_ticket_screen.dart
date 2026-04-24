import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketScreen extends StatelessWidget {
  final String ticketId;

  const TicketScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Your Ticket")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('tickets')
            .where('ticketId', isEqualTo: ticketId)
            .snapshots()
            .map((snapshot) => snapshot.docs.first),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          final qrData = {
            "ticketId": data['ticketId'],
            "eventId": data['eventId'],
            "userId": data['userId'],
          };

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data['eventTitle'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              QrImageView(
                data: qrData.toString(),
                version: QrVersions.auto,
                size: 220,
              ),

              const SizedBox(height: 20),

              Text("Quantity: ${data['quantity']}"),
              Text("Location: ${data['location']}"),
            ],
          );
        },
      ),
    );
  }
}