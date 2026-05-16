import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
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

  const PaymentScreen({
    super.key,
    required this.eventId,
    required this.ticketId,
    required this.totalAmount,
    required this.quantity,
    this.eventTitle,
    this.seats,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0;
  bool _isProcessing = false;
  final _promoController = TextEditingController();
  double _discount = 0;

  final List<_PaymentMethod> _methods = const [
    _PaymentMethod(icon: Icons.credit_card_outlined, label: 'Credit / Debit Card', subtitle: 'Visa, Mastercard, Verve'),
    _PaymentMethod(icon: Icons.phone_android_outlined, label: 'Paystack', subtitle: 'Pay with Paystack'),
    _PaymentMethod(icon: Icons.account_balance_outlined, label: 'Bank Transfer', subtitle: 'Direct bank transfer'),
  ];

  // Logic adjusted for router-passed totalAmount
  double get _serviceFee => (widget.totalAmount * 0.05);
  double get _total => widget.totalAmount + _serviceFee - _discount;

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code == 'EVENTRA10') {
      setState(() => _discount = widget.totalAmount * 0.1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('10% discount applied!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid promo code')),
      );
    }
  }

  Future<void> _pay() async {
    setState(() => _isProcessing = true);
    // Mimicking a payment gateway delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    setState(() => _isProcessing = false);
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          eventTitle: widget.eventTitle ?? 'Event Booking',
          seats: widget.seats ?? ['General Admission x${widget.quantity}'],
          total: _total,
          ticketId: widget.ticketId.isNotEmpty ? widget.ticketId : 'EVT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildPayBar(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.purpleGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.confirmation_number_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.eventTitle ?? 'Event Booking', style: AppTextStyles.titleMedium),
                    Text(
                      'Quantity: ${widget.quantity}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _PriceRow(label: 'Subtotal', value: widget.totalAmount),
          const SizedBox(height: 8),
          _PriceRow(label: 'Service fee (5%)', value: _serviceFee),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(label: 'Promo discount', value: -_discount, isDiscount: true),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.headlineSmall),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.accentOrange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // UI Methods: _buildPromoSection, _buildMethodTile, _buildPayBar 
  // remain largely the same as your original draft...
  
  Widget _buildPromoSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.local_offer_outlined, color: AppColors.accentPurple, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _promoController,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Promo code',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          TextButton(
            onPressed: _applyPromo,
            child: Text('Apply', style: AppTextStyles.labelLarge.copyWith(color: AppColors.accentPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(int index, _PaymentMethod method) {
    final isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPurple.withOpacity(0.08) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppColors.borderDefault,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentPurple.withOpacity(0.2) : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(method.icon, color: isSelected ? AppColors.accentPurple : AppColors.textHint, size: 20),
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
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accentPurple : AppColors.borderDefault,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.borderDefault)),
      ),
      child: GradientButton(
        label: _isProcessing ? 'Processing...' : 'Pay \$${_total.toStringAsFixed(2)}',
        onPressed: _isProcessing ? null : _pay,
      ),
    );
  }
}

// ─── Payment Success Screen ────────────────────────────────────────────────────
// (Keep your PaymentSuccessScreen, _SummaryRow, and _PriceRow as originally written)

class PaymentSuccessScreen extends StatefulWidget {
  final String eventTitle;
  final List<String> seats;
  final double total;
  final String ticketId;

  const PaymentSuccessScreen({
    super.key,
    required this.eventTitle,
    required this.seats,
    required this.total,
    required this.ticketId,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _scale;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4))..play();
    _scale = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _scale, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 200), _scale.forward);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scale.dispose();
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
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.08,
            numberOfParticles: 24,
            gravity: 0.12,
            colors: const [AppColors.accentPurple, AppColors.accentOrange, Colors.white],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: AppColors.purpleGradient),
                        boxShadow: [
                          BoxShadow(color: AppColors.accentPurple.withOpacity(0.4), blurRadius: 30, spreadRadius: 2),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Booking Confirmed!', style: AppTextStyles.displayMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('Your tickets are ready. Have a great time!', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(label: 'Event', value: widget.eventTitle),
                        const Divider(height: 20),
                        _SummaryRow(label: 'Seats', value: widget.seats.join(', ')),
                        const Divider(height: 20),
                        _SummaryRow(label: 'Total Paid', value: '\$${widget.total.toStringAsFixed(2)}'),
                        const Divider(height: 20),
                        _SummaryRow(label: 'Ticket ID', value: widget.ticketId, isAccent: true),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GradientButton(
                    label: 'View My Ticket',
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
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
  const _SummaryRow({required this.label, required this.value, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Flexible(child: Text(value, style: AppTextStyles.titleMedium.copyWith(color: isAccent ? AppColors.accentPurple : null), textAlign: TextAlign.right)),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isDiscount;
  const _PriceRow({required this.label, required this.value, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          isDiscount ? '-\$${value.abs().toStringAsFixed(2)}' : '\$${value.toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium.copyWith(color: isDiscount ? AppColors.success : AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _PaymentMethod {
  final IconData icon;
  final String label;
  final String subtitle;
  const _PaymentMethod({required this.icon, required this.label, required this.subtitle});
}