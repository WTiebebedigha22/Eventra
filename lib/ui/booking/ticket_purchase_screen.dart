import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../../services/booking_service.dart';

class TicketPurchaseScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const TicketPurchaseScreen({super.key, required this.event});

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> {
  int quantity = 1;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handlePurchase() async {
    final bookingService = Provider.of<BookingService>(context, listen: false);
    
    try {
      await bookingService.purchaseTicket(
        eventId: widget.event['id'] ?? 'unknown',
        eventTitle: widget.event['title'],
        eventImageUrl: widget.event['imageUrl'],
        eventDate: widget.event['date'],
        eventLocation: widget.event['location'],
        price: (widget.event['price'] as num).toDouble(),
        quantity: quantity,
      );

      // Trigger Confetti!
      _confettiController.play();
      _showSuccessSheet();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Purchase failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double price = (widget.event['price'] as num).toDouble();
    double totalPrice = price * quantity;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Book Ticket", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              _buildEventSummary(),
              _buildQuantitySelector(),
              const Spacer(),
              _buildPurchaseCard(totalPrice),
            ],
          ),
        ),
        // Confetti Widget Overlay
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [Color(0xFFE91E63), Colors.white, Colors.blue],
          numberOfParticles: 20,
          gravity: 0.1,
        ),
      ],
    );
  }

  Widget _buildEventSummary() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.event['imageUrl'], 
                  width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey, width: 80, height: 80),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.event['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(widget.event['location'], style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white10, thickness: 1),
          ),
          _buildDetailRow("Date", widget.event['date']),
          const SizedBox(height: 10),
          _buildDetailRow("Seat", "General Admission"),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Quantity", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Color(0xFFE91E63)),
                  onPressed: () => setState(() { if (quantity > 1) quantity--; }),
                ),
                Text("$quantity", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFFE91E63)),
                  onPressed: () => setState(() { quantity++; }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPurchaseCard(double total) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Price", style: TextStyle(fontSize: 16, color: Colors.white54)),
                Text("\$${total.toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFE91E63))),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                onPressed: _handlePurchase,
                child: const Text("Confirm Payment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Payment Successful!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Your ticket has been booked and synced to your profile.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.pop(context); // Go back to event details
                },
                child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}