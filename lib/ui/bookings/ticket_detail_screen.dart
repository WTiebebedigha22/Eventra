import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../app/app_theme.dart';
import '../../core/shared_widget.dart';

class TicketDetailScreen extends StatelessWidget {
  final String ticketId;
  final String eventTitle;
  final String date;
  final String time;
  final String venue;
  final String seat;
  final String section;
  final String price;
  final String organiser;
  final String eventImageUrl;
  final bool isUsed;
  final String? orderId;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.eventTitle,
    required this.date,
    required this.time,
    required this.venue,
    required this.seat,
    required this.section,
    required this.price,
    required this.organiser,
    required this.eventImageUrl,
    this.isUsed = false,
    this.orderId,
  });

  void _shareTicket(BuildContext context) async {
    try {
      await Share.share(
        '🎫 My Ticket for $eventTitle\n'
        '📅 Date: $date\n'
        '⏰ Time: $time\n'
        '📍 Venue: $venue\n'
        '💺 Seat: $section - $seat\n'
        '🎟️ Ticket ID: $ticketId\n\n'
        'Powered by Eventra',
        subject: 'My Event Ticket',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sharing ticket'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveToWallet(BuildContext context) async {
    try {
      // Simulate saving to wallet
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket added to wallet! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving to wallet'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadPDF(BuildContext context) async {
    try {
      // Simulate PDF download
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket downloaded! 📄'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error downloading ticket'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('My Ticket'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _shareTicket(context),
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Ticket',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            Hero(
              tag: 'ticket_$ticketId',
              child: _buildTicketBody(context),
            ),
            const SizedBox(height: 24),
            _buildActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketBody(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Event header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: const LinearGradient(
                  colors: AppColors.purpleGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUsed)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'USED',
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    eventTitle,
                    style: AppTextStyles.displayMedium.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.event_seat, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        'Organized by $organiser',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ticket info row
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _InfoBlock(label: 'Date', value: date, icon: Icons.calendar_today),
                  _Divider(),
                  _InfoBlock(label: 'Time', value: time, icon: Icons.access_time),
                  _Divider(),
                  _InfoBlock(label: 'Section', value: section, icon: Icons.map),
                  _Divider(),
                  _InfoBlock(label: 'Seat', value: seat, icon: Icons.event_seat),
                ],
              ),
            ),

            // Venue
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.accentPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Venue', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          venue,
                          style: AppTextStyles.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Dashed cut line
            _CutLine(),

            // QR code section
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isUsed ? 'Already Used' : 'Scan to Enter',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isUsed ? Colors.red : AppColors.textSecondary,
                        fontWeight: isUsed ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // QR code with styled container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: isUsed ? 0.4 : 1.0,
                      child: QrImageView(
                        data: ticketId,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ticket ID
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Ticket ID',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: ticketId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ticket ID copied!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: SelectableText(
                            ticketId,
                            style: AppTextStyles.bodySmall.copyWith(
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentOrange.withValues(alpha: 0.15), AppColors.accentOrange.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      price,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Order ID if available
            if (orderId != null && orderId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Order #${orderId!.substring(0, orderId!.length > 8 ? 8 : orderId!.length)}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: GradientButton(
            label: 'Add to Wallet',
            onPressed: isUsed ? null : () => _saveToWallet(context),
            icon: Icons.wallet_outlined,
            colors: isUsed ? [Colors.grey, Colors.grey] : AppColors.purpleGradient,
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Download PDF',
          variant: AppButtonVariant.outlined,
          icon: Icons.download_outlined,
          onPressed: () => _downloadPDF(context),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _shareTicket(context),
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Share Ticket'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoBlock({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderDefault,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _CutLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashW = 6.0;
              const gap = 5.0;
              final count = (constraints.maxWidth / (dashW + gap)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  count,
                  (index) => Container(
                    width: dashW,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: gap / 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.borderDefault, AppColors.borderDefault.withValues(alpha: 0.5)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}