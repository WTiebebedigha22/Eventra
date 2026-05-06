import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';

class TicketScreen extends StatelessWidget {
  final String ticketId;

  const TicketScreen({super.key, required this.ticketId});

  static const Color primaryColor = Colors.deepPurpleAccent;

  @override
  Widget build(BuildContext context) {
    // Get the current user ID to satisfy security rules
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          "Your Ticket",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // UPDATED: Added userId filter to satisfy security rules
        stream: FirebaseFirestore.instance
            .collectionGroup('tickets')
            .where('userId', isEqualTo: currentUserId) 
            .where('ticketId', isEqualTo: ticketId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // If you still see an error here, check if you clicked the 
            // generated Link in the console to create the composite index.
            return _buildErrorState("Permission denied or missing index.");
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildErrorState("Ticket not found for this account.");
          }

          final doc = snapshot.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          // --- SAFE DATA PARSING ---
          final String eventTitle = data['eventTitle'] ?? 'Event';
          final String location = data['eventLocation'] ?? data['location'] ?? 'Location TBD';
          final int quantity = data['quantity'] ?? 1;
          final double price = (data['price'] ?? 0).toDouble();
          final bool isPaid = data['isPaid'] == true;
          
          final qrData = {
            "ticketId": ticketId,
            "eventId": data['eventId'] ?? 'N/A',
            "userId": data['userId'] ?? 'N/A',
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildStatusBanner(isPaid),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTicketHeader(eventTitle, location),
                      _buildDashedDivider(),
                      _buildQRSection(qrData.toString()),
                      _buildDashedDivider(),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildDetailRow(Icons.confirmation_number_outlined, 'Ticket ID', '#${ticketId.substring(0, 8).toUpperCase()}'),
                            const SizedBox(height: 14),
                            _buildDetailRow(Icons.people_outline, 'Quantity', '$quantity ticket${quantity > 1 ? 's' : ''}'),
                            const SizedBox(height: 14),
                            _buildDetailRow(Icons.payments_outlined, 'Amount Paid', '₦${(price * quantity).toStringAsFixed(0)}'),
                            const SizedBox(height: 14),
                            _buildDetailRow(
                              Icons.verified_outlined, 
                              'Status', 
                              isPaid ? 'Confirmed' : 'Pending',
                              valueColor: isPaid ? const Color(0xFF059669) : Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildHomeButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildStatusBanner(bool isPaid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFECFDF5) : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPaid ? const Color(0xFF6EE7B7) : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
            color: isPaid ? const Color(0xFF059669) : Colors.orange.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPaid ? 'Payment confirmed — Enjoy the event!' : 'Awaiting payment confirmation',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isPaid ? const Color(0xFF059669) : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHeader(String title, String location) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EVENT TICKET', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(location, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection(String data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF3F0FF), borderRadius: BorderRadius.circular(16)),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 200,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF5B21B6)),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF5B21B6)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Scan at the entrance', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: () => context.go('/home'),
        child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _notch(left: true),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dashCount = (constraints.constrainWidth() / 10).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(dashCount, (_) => Container(width: 6, height: 1.5, color: Colors.grey.shade200)),
                );
              },
            ),
          ),
          _notch(left: false),
        ],
      ),
    );
  }

  Widget _notch({required bool left}) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.horizontal(
          left: left ? Radius.zero : const Radius.circular(10),
          right: left ? const Radius.circular(10) : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: valueColor ?? Colors.black)),
      ],
    );
  }
}