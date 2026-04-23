import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../services/booking_service.dart';

class TicketPurchaseScreen extends StatefulWidget {
  final String eventId;
  // Note: 'event' is now optional because we will fetch it via the eventId
  final Map<String, dynamic>? event;

  const TicketPurchaseScreen({
    super.key, 
    required this.eventId, 
    this.event,
  });

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  int quantity = 1;
  late ConfettiController _confettiController;
  
  // Theme Colors (Matching your App)
  static const Color primaryColor = Colors.deepPurpleAccent;
  static const Color backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handlePurchase(Map<String, dynamic> eventData) async {
    final bookingService = Provider.of<BookingService>(context, listen: false);
    
    try {
      await bookingService.purchaseTicket(
        eventId: widget.eventId,
        eventTitle: eventData['title'] ?? 'Untitled Event',
        eventImageUrl: eventData['imageUrl'] ?? '',
        eventDate: (eventData['eventDate'] as Timestamp?)?.toDate().toString() ?? 'TBD',
        eventLocation: eventData['location'] ?? 'Unknown',
        price: double.tryParse(eventData['price'].toString()) ?? 0.0,
        quantity: quantity,
      );

      _confettiController.play();
      _showSuccessSheet();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Purchase failed: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              onPressed: () => context.pop(),
            ),
            title: const Text("Checkout", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('events').doc(widget.eventId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }

              final eventData = snapshot.data!.data() as Map<String, dynamic>;
              double price = double.tryParse(eventData['price'].toString()) ?? 0.0;
              double totalPrice = price * quantity;

              return Column(
                children: [
                  _buildEventSummary(eventData),
                  const SizedBox(height: 10),
                  _buildQuantitySelector(),
                  const Spacer(),
                  _buildPurchaseCard(totalPrice, eventData),
                ],
              );
            },
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [primaryColor, Colors.orange, Colors.blue],
          numberOfParticles: 25,
          gravity: 0.1,
        ),
      ],
    );
  }

  Widget _buildEventSummary(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data['imageUrl'] ?? '', 
                  width: 70, height: 70, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: Colors.grey[300], width: 70, height: 70, child: const Icon(Icons.image)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? 'Event', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(data['location'] ?? 'Location TBD', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          _buildDetailRow("Standard Entry", "₦${data['price']}"),
          const SizedBox(height: 12),
          _buildDetailRow("Seat Type", "General Admission"),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(15)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Quantity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Row(
              children: [
                _qtyBtn(Icons.remove, () => setState(() { if (quantity > 1) quantity--; })),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text("$quantity", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _qtyBtn(Icons.add, () => setState(() { quantity++; })),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 20, color: primaryColor),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPurchaseCard(double total, Map<String, dynamic> eventData) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Pay", style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text("₦${total.toStringAsFixed(0)}", 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: () => _handlePurchase(eventData),
                child: const Text("Confirm & Pay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
            const SizedBox(height: 20),
            const Text("Booking Successful!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Your ticket has been booked and added to your profile.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  context.pop(); // Go back to event details
                },
                child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}