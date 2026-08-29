import '../../core/network/api_client.dart';

class PaymentRepository {
  final _api = AppDio();

  /// Creates a Stripe PaymentIntent for the given booking.
  /// Returns { client_secret, amount, currency, booking_ref }
  Future<Map<String, dynamic>> createPaymentIntent(String bookingId) async {
    final res = await _api.dio.post('/api/payments/create-intent', data: {
      'booking_id': bookingId,
    });
    return res.data as Map<String, dynamic>;
  }
}