import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/booking_service.dart';
import '../../app/app_theme.dart';
import '../../core/shared_widget.dart';
import 'payment_screen.dart';

class TicketPurchaseScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic>? event;

  const TicketPurchaseScreen({super.key, required this.eventId, this.event});

  @override
  State<TicketPurchaseScreen> createState() => _TicketPurchaseScreenState();
}

class _TicketPurchaseScreenState extends State<TicketPurchaseScreen> with SingleTickerProviderStateMixin {
  int quantity = 1;
  bool _isLoading = false;
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Colors.white;
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _formatPrice(double price) {
    final format = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    return format.format(price);
  }

  Future<void> _handlePurchase(Map<String, dynamic> eventData) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        _showSnackBar('Please login to continue', isError: true);
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // Create a temporary ticket ID
      final tempTicketId = 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
      final price = _parsePrice(eventData['price']);
      final totalPrice = price * quantity;
      final serviceFee = totalPrice * 0.05;
      final grandTotal = totalPrice + serviceFee;

      // Navigate to PaymentScreen with all details
      if (mounted) {
        // Play confetti for success before navigation
        _confettiController.play();
        
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          // Navigate to PaymentScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                eventId: widget.eventId,
                ticketId: tempTicketId,
                totalAmount: totalPrice,
                quantity: quantity,
                eventTitle: eventData['title'] ?? 'Untitled Event',
                seats: ['General Admission x$quantity'],
                eventDate: (eventData['eventDate'] as Timestamp?)?.toDate().toString(),
                venue: eventData['location'] ?? 'TBD',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
              onPressed: _isLoading ? null : () => context.pop(),
            ),
            title: const Text(
              "Checkout",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .doc(widget.eventId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: errorColor),
                          const SizedBox(height: 16),
                          const Text("Something went wrong"),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final price = _parsePrice(data['price']);
                  final totalPrice = price * quantity;

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildEventSummary(data),
                              const SizedBox(height: 16),
                              _buildQuantitySelector(),
                              const SizedBox(height: 16),
                              _buildOrderSummary(price, totalPrice),
                            ],
                          ),
                        ),
                      ),
                      _buildPurchaseButton(totalPrice, data),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [primaryColor, Colors.orange, Colors.green, Colors.blue],
          numberOfParticles: 30,
          gravity: 0.1,
          emissionFrequency: 0.05,
        ),
      ],
    );
  }

  Widget _buildEventSummary(Map<String, dynamic> data) {
    final eventDate = data['eventDate'] as Timestamp?;
    final formattedDate = eventDate != null 
        ? DateFormat('EEE, MMM d, yyyy • h:mm a').format(eventDate.toDate())
        : 'Date TBD';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  data['imageUrl'] ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.event, color: primaryColor, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Event',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1E21),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['location'] ?? 'Location TBD',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              _buildInfoChip(Icons.confirmation_number_outlined, 'Ticket Type', 'General Admission'),
              const Spacer(),
              _buildInfoChip(Icons.access_time_outlined, 'Duration', 'Single Entry'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Number of Tickets",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C1E21)),
          ),
          Row(
            children: [
              _quantityButton(
                icon: Icons.remove,
                onTap: () => setState(() => quantity = quantity > 1 ? quantity - 1 : 1),
              ),
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "$quantity",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _quantityButton(
                icon: Icons.add,
                onTap: () => setState(() => quantity++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: primaryColor),
      ),
    );
  }

  Widget _buildOrderSummary(double price, double totalPrice) {
    final serviceFee = totalPrice * 0.05;
    final grandTotal = totalPrice + serviceFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Summary",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1E21)),
          ),
          const SizedBox(height: 16),
          _summaryRow('Ticket Price', _formatPrice(price)),
          const SizedBox(height: 8),
          _summaryRow('Quantity', 'x$quantity'),
          const SizedBox(height: 8),
          _summaryRow('Subtotal', _formatPrice(totalPrice)),
          const SizedBox(height: 8),
          _summaryRow('Service Fee (5%)', _formatPrice(serviceFee)),
          const Divider(height: 20),
          _summaryRow(
            'Total',
            _formatPrice(grandTotal),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Color(0xFF1C1E21) : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? primaryColor : Color(0xFF1C1E21),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseButton(double totalPrice, Map<String, dynamic> data) {
    final serviceFee = totalPrice * 0.05;
    final grandTotal = totalPrice + serviceFee;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Payment",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(grandTotal),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      '(${_formatPrice(totalPrice)} + fees)',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: primaryColor.withOpacity(0.6),
                ),
                onPressed: _isLoading ? null : () => _handlePurchase(data),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        "Continue to Payment",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}