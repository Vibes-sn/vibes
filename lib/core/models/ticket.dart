class Ticket {
  const Ticket({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.qrCodeData,
    required this.paymentRef,
    required this.purchaseDate,
  });

  static const table = 'tickets';
  static const colId = 'id';
  static const colEventId = 'event_id';
  static const colUserId = 'user_id';
  static const colStatus = 'status';
  static const colQrCodeData = 'qr_code_data';
  static const colPaymentRef = 'payment_ref';
  static const colPurchaseDate = 'purchase_date';

  final String id;
  final String eventId;
  final String userId;
  final String status;
  final String qrCodeData;
  final String? paymentRef;
  final DateTime purchaseDate;

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map[colId] as String,
      eventId: map[colEventId] as String,
      userId: map[colUserId] as String,
      status: map[colStatus] as String? ?? 'paid',
      qrCodeData: map[colQrCodeData] as String? ?? '',
      paymentRef: map[colPaymentRef] as String?,
      purchaseDate:
          DateTime.tryParse(map[colPurchaseDate] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
