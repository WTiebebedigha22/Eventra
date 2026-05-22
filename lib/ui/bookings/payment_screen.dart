import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ventra/ui/bookings/qr_ticket_screen.dart';
import '../../app/app_theme.dart';
import '../../core/shared_widget.dart';

// ─── Payment Screen ────────────────────────────────────────────────────────────

class PaymentScreen extends StatefulWidget {
  final String eventId;
  final String ticketId;
  final double totalAmount;
  final int quantity;
  final String? eventTitle;
  final List<String>? seats;
  final String? eventDate;
  final String? venue;

  const PaymentScreen({
    super.key,
    required this.eventId,
    required this.ticketId,
    required this.totalAmount,
    required this.quantity,
    this.eventTitle,
    this.seats,
    this.eventDate,
    this.venue,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  int _selectedMethod = 0;
  bool _isProcessing = false;
  final _promoController = TextEditingController();
  double _discount = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<_PaymentMethod> _methods = const [
    _PaymentMethod(icon: Icons.credit_card_rounded, label: 'Credit / Debit Card', subtitle: 'Visa, Mastercard, Verve'),
    _PaymentMethod(icon: Icons.phone_android_rounded, label: 'Mobile Money', subtitle: 'Pay with mobile wallet'),
    _PaymentMethod(icon: Icons.account_balance_rounded, label: 'Bank Transfer', subtitle: 'Direct bank transfer'),
  ];

  double get _serviceFee => (widget.totalAmount * 0.05);
  double get _total => widget.totalAmount + _serviceFee - _discount;
  
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _promoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code == 'EVENTRA10') {
      setState(() => _discount = widget.totalAmount * 0.1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('10% discount applied! 🎉'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (code == 'WELCOME20') {
      setState(() => _discount = widget.totalAmount * 0.2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('20% welcome discount applied! 🎉'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _promoController.clear();
  }

  String _generateTicketId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'EVT-$timestamp';
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isProcessing = false);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final generatedTicketId = _generateTicketId();
        
        final bookingData = {
          'userId': user.uid,
          'userEmail': user.email,
          'eventId': widget.eventId,
          'eventTitle': widget.eventTitle ?? 'Event Booking',
          'eventDate': widget.eventDate,
          'venue': widget.venue,
          'seats': widget.seats ?? ['General Admission x${widget.quantity}'],
          'quantity': widget.quantity,
          'subtotal': widget.totalAmount,
          'serviceFee': _serviceFee,
          'discount': _discount,
          'total': _total,
          'paymentMethod': _methods[_selectedMethod].label,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
          'ticketId': generatedTicketId,
        };
        
        await FirebaseFirestore.instance.collection('bookings').add(bookingData);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                eventTitle: widget.eventTitle ?? 'Event Booking',
                seats: widget.seats ?? ['General Admission x${widget.quantity}'],
                total: _total,
                ticketId: generatedTicketId,
                eventDate: widget.eventDate,
                venue: widget.venue,
              ),
            ),
          );
        }
      } catch (e) {
        print('Error saving booking: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error processing payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(),
                    const SizedBox(height: 20),
                    _buildPromoSection(),
                    const SizedBox(height: 20),
                    Text('Payment Method', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 12),
                    ..._methods.asMap().entries.map((e) => _buildMethodTile(e.key, e.value)),
                    const SizedBox(height: 20),
                    _buildSecurityNote(),
                  ],
                ),
              ),
            ),
            _buildPayBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              const Icon(Icons.receipt_long_rounded, color: AppColors.accentPurple),
              const SizedBox(width: 8),
              Text('Order Summary', style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.purpleGradient),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eventTitle ?? 'Event Booking',
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quantity: ${widget.quantity}',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (widget.seats != null && widget.seats!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Seats: ${widget.seats!.join(', ')}',
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          _PriceRow(label: 'Subtotal', value: widget.totalAmount),
          const SizedBox(height: 8),
          _PriceRow(label: 'Service Fee (5%)', value: _serviceFee),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(label: 'Promo Discount', value: -_discount, isDiscount: true),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.headlineSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currencyFormat.format(_total),
                  style: AppTextStyles.headlineMedium.copyWith(color: AppColors.accentOrange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_offer_outlined, color: AppColors.accentPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _promoController,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Enter promo code',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          TextButton(
            onPressed: _applyPromo,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.accentPurple.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Apply', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accentPurple)),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMethodTile(int index, _PaymentMethod method) {
    final isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedMethod = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPurple.withValues(alpha: 0.08) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppColors.borderDefault,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentPurple.withValues(alpha: 0.15) : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(method.icon, color: isSelected ? AppColors.accentPurple : AppColors.textHint, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: AppTextStyles.titleMedium),
                  Text(method.subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accentPurple : AppColors.borderDefault,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Secure payment powered by Eventra',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GradientButton(
        label: _isProcessing ? 'Processing...' : 'Pay ${_currencyFormat.format(_total)}',
        onPressed: _isProcessing ? null : _processPayment,
        icon: Icons.lock_rounded,
      ),
    );
  }
}

// ─── Payment Success Screen ────────────────────────────────────────────────────
// FIXED: Changed SingleTickerProviderStateMixin to TickerProviderStateMixin

class PaymentSuccessScreen extends StatefulWidget {
  final String eventTitle;
  final List<String> seats;
  final double total;
  final String ticketId;
  final String? eventDate;
  final String? venue;

  const PaymentSuccessScreen({
    super.key,
    required this.eventTitle,
    required this.seats,
    required this.total,
    required this.ticketId,
    this.eventDate,
    this.venue,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

// FIXED: Changed from SingleTickerProviderStateMixin to TickerProviderStateMixin
class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {  // ← THIS IS THE FIX
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _scaleController.forward();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            colors: const [
              AppColors.accentPurple,
              AppColors.accentOrange,
              Colors.green,
              Colors.blue,
              Colors.pink,
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: AppColors.purpleGradient),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentPurple.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      children: [
                        Text(
                          'Booking Confirmed!',
                          style: AppTextStyles.displayMedium.copyWith(fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your tickets are ready. Have a great time!',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeTransition(
                    opacity: _fadeController,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderDefault),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Event', value: widget.eventTitle),
                          const Divider(height: 20),
                          _SummaryRow(label: 'Seats', value: widget.seats.join(', ')),
                          if (widget.eventDate != null) ...[
                            const Divider(height: 20),
                            _SummaryRow(label: 'Date', value: widget.eventDate!),
                          ],
                          if (widget.venue != null) ...[
                            const Divider(height: 20),
                            _SummaryRow(label: 'Venue', value: widget.venue!),
                          ],
                          const Divider(height: 20),
                          _SummaryRow(label: 'Total Paid', value: '₦${widget.total.toStringAsFixed(2)}'),
                          const Divider(height: 20),
                          _SummaryRow(label: 'Ticket ID', value: widget.ticketId, isAccent: true),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      children: [
                        GradientButton(
                          label: 'View My Ticket',
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TicketScreen(ticketId: widget.ticketId),
                              ),
                            );
                          },
                          icon: Icons.confirmation_number_outlined,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.home_rounded, size: 18),
                          label: const Text('Back to Home'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isAccent;
  
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: isAccent ? AppColors.accentPurple : null,
              fontWeight: isAccent ? FontWeight.bold : null,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isDiscount;
  
  const _PriceRow({
    required this.label,
    required this.value,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          isDiscount ? '- ₦${value.abs().toStringAsFixed(2)}' : '₦${value.toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDiscount ? Colors.green : AppColors.textPrimary,
            fontWeight: isDiscount ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethod {
  final IconData icon;
  final String label;
  final String subtitle;
  
  const _PaymentMethod({
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}