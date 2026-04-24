class TicketModel {
  final String ticketId;
  final String eventId;
  final String userId;
  final String eventTitle;
  final String imageUrl;
  final DateTime createdAt;
  final int quantity;
  final double price;

  TicketModel({
    required this.ticketId,
    required this.eventId,
    required this.userId,
    required this.eventTitle,
    required this.imageUrl,
    required this.createdAt,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'eventId': eventId,
      'userId': userId,
      'eventTitle': eventTitle,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'quantity': quantity,
      'price': price,
    };
  }
}