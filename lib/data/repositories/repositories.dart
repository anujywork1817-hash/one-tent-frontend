import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';

class AuthRepository {
  final _api = AppDio();

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String nationality,
    required String passportNumber,
    required String country,
    required String password,
  }) async {
    final res = await _api.dio.post('/auth/register', data: {
      'name': fullName,
      'email': email,
      'phone': phone,
      'nationality': nationality,
      'passport_no': passportNumber,
      'country': country,
      'password': password,
    });
    final token = res.data['data']['access_token'];
    if (token != null) await _api.saveToken(token);
    return res.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print('LOGIN request: email=$email');
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    print('LOGIN status: ${res.statusCode}');
    print('LOGIN body: ${res.data}');
    final token = res.data['data']['access_token'];
    if (token != null) await _api.saveToken(token);
    return res.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _api.dio.get('/auth/me');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    File? profileImageFile,
    bool removeProfileImage = false,
  }) async {
    if (profileImageFile != null) {
      final formData = FormData.fromMap({
        'name': name,
        'phone': phone,
        'profile_image': await MultipartFile.fromFile(profileImageFile.path),
      });
      final res = await _api.dio.patch('/auth/profile', data: formData);
      return res.data['data'] as Map<String, dynamic>;
    } else {
      final res = await _api.dio.patch('/auth/profile', data: {
        'name': name,
        'phone': phone,
        if (removeProfileImage) 'remove_profile_image': true,
      });
      return res.data['data'] as Map<String, dynamic>;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  Future<void> forgotPassword(String email) async {
    await _api.dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _api.dio.post('/auth/reset-password', data: {
      'token': token,
      'password': newPassword,
    });
  }

  Future<void> verifyEmail(String code) async {
    await _api.dio.post('/auth/verify-email', data: {'code': code});
  }

  Future<void> resendVerification() async {
    await _api.dio.post('/auth/resend-verification');
  }
}

class TentRepository {
  final _api = AppDio();

  Future<List<CapsuleTent>> listTents({String? tentType}) async {
    final params = <String, dynamic>{};
    if (tentType != null) params['type'] = tentType;
    final res = await _api.dio.get('/tents', queryParameters: params);
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => CapsuleTent.fromJson(e)).toList();
  }

  Future<CapsuleTent> getTent(String id) async {
    final res = await _api.dio.get('/tents/$id');
    return CapsuleTent.fromJson(res.data['data']);
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────
  // The list endpoint returns full tent records (same shape as /tents), so
  // saved tents render with the normal tent card without extra requests.

  Future<List<CapsuleTent>> wishlist() async {
    final res = await _api.dio.get('/wishlist');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => CapsuleTent.fromJson(e)).toList();
  }

  Future<void> addToWishlist(String tentId) async {
    await _api.dio.post('/wishlist/$tentId');
  }

  Future<void> removeFromWishlist(String tentId) async {
    await _api.dio.delete('/wishlist/$tentId');
  }

  Future<List<CapsuleTent>> checkAvailability({
    required String checkIn,
    required String checkOut,
    int guests = 1,
    String? tentType,
  }) async {
    final params = <String, dynamic>{
      'check_in': checkIn,
      'check_out': checkOut,
      'guests': guests,
    };
    if (tentType != null) params['type'] = tentType;
    final res =
        await _api.dio.get('/tents/availability', queryParameters: params);
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => CapsuleTent.fromJson(e['tent'])).toList();
  }

  /// Real per-day occupancy for every tent of the same type as [tentId], for
  /// the given calendar [month] ("YYYY-MM") — what the booking calendar
  /// colors green/yellow/red against, instead of guessing.
  Future<Map<String, DayAvailability>> dayAvailability({
    required String tentId,
    required String month,
  }) async {
    final res = await _api.dio.get('/tents/$tentId/day-availability',
        queryParameters: {'month': month});
    final list = res.data['data'] as List? ?? [];
    return {
      for (final e in list)
        (e['date'] as String): DayAvailability.fromJson(e as Map<String, dynamic>),
    };
  }

  Future<TentBooking> createBooking({
    required String tentId,
    required String checkInDate,
    required String checkOutDate,
    required int numGuests,
    String specialRequests = '',
    List<AdditionalGuest> additionalGuests = const [],
    String currency = 'INR',
    int roomCount = 1,
    String? couponCode,
    int childrenUnder5 = 0,
    int childrenAbove5 = 0,
  }) async {
    final res = await _api.dio.post('/bookings', data: {
      'tent_id': tentId,
      'check_in': checkInDate,
      'check_out': checkOutDate,
      'guests': numGuests,
      'special_request': specialRequests,
      'additional_guests': additionalGuests.map((g) => g.toJson()).toList(),
      'currency': currency,
      'room_count': roomCount,
      if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      'children_under5': childrenUnder5,
      'children_above5': childrenAbove5,
    });
    return TentBooking.fromJson(res.data['data']);
  }

  /// A few currently-usable coupon codes, for a "try one of these" strip —
  /// never fabricated; empty if none are active right now.
  Future<List<CouponPreview>> activeCoupons() async {
    final res = await _api.dio.get('/coupons');
    final list = res.data['data'] as List? ?? [];
    return list
        .map((e) => CouponPreview(
              valid: true,
              code: e['code'] as String?,
              discountType: e['discount_type'] as String?,
              discountValue: (e['discount_value'] as num?)?.toDouble() ?? 0,
            ))
        .toList();
  }

  /// Checks a coupon code against the server — the same check happens again,
  /// authoritatively, when the booking is actually created; this is just so
  /// the guest sees whether it's valid before they commit to it.
  Future<CouponPreview> validateCoupon(String code) async {
    final res = await _api.dio
        .get('/coupons/validate', queryParameters: {'code': code});
    return CouponPreview.fromJson(res.data['data']);
  }

  // ── Multi-currency preview ──────────────────────────────────────────────
  // Public endpoint, no auth needed — lets the booking screen show a foreign
  // guest their converted price before they book. The actual Razorpay charge
  // always stays INR; see gstRateForTent's sibling on the backend for why.
  Future<Map<String, double>> exchangeRates() async {
    final res = await _api.dio.get('/exchange-rates');
    final list = res.data['data'] as List? ?? [];
    return {
      for (final e in list)
        (e['currency'] as String): (e['rate_to_inr'] as num).toDouble(),
    };
  }

  Future<List<TentBooking>> myBookings() async {
    final res = await _api.dio.get('/bookings/my');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => TentBooking.fromJson(e)).toList();
  }

  Future<TentBooking> getBooking(String id) async {
    final res = await _api.dio.get('/bookings/$id');
    return TentBooking.fromJson(res.data['data']);
  }

  /// Asks the backend what a cancellation would refund, without cancelling.
  /// Returns { cancellable, refund_eligible, refund_amount, cancellation_fee,
  ///           expected_days_min, expected_days_max, message, ... }
  Future<Map<String, dynamic>> refundPreview(String bookingId) async {
    final res = await _api.dio.get('/bookings/$bookingId/refund-preview');
    return res.data['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId,
      {String? reason}) async {
    final res = await _api.dio.patch(
      '/bookings/$bookingId/cancel',
      data: reason == null || reason.isEmpty ? null : {'reason': reason},
    );
    return res.data['data'] as Map<String, dynamic>? ?? {};
  }

  // ── Reviews ───────────────────────────────────────────────────────────────

  Future<void> submitBookingReview({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    await _api.dio.post('/bookings/$bookingId/review',
        data: {'rating': rating, 'comment': comment});
  }

  /// Null when this booking hasn't been reviewed yet.
  Future<TentReview?> getBookingReview(String bookingId) async {
    final res = await _api.dio.get('/bookings/$bookingId/review');
    final data = res.data['data'];
    return data == null ? null : TentReview.fromJson(data);
  }

  /// Public — no auth needed, this is what other guests see while browsing
  /// or booking this tent.
  Future<TentReviewSummary> tentReviews(String tentId) async {
    final res = await _api.dio.get('/tents/$tentId/reviews');
    return TentReviewSummary.fromJson(res.data['data'] ?? {});
  }

  /// The refund attached to a booking, or null if there is none.
  Future<Map<String, dynamic>?> bookingRefund(String bookingId) async {
    final res = await _api.dio.get('/bookings/$bookingId/refund');
    return res.data['data'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>> getQRCode(String bookingId) async {
    final res = await _api.dio.get('/bookings/$bookingId/qr');
    return res.data['data'] as Map<String, dynamic>;
  }
}

class PaymentRepository {
  final _api = AppDio();

  Future<Map<String, dynamic>> createOrder(String bookingId) async {
    final res = await _api.dio.post('/payments/create-order/$bookingId');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<void> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await _api.dio.post('/payments/verify', data: {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    });
  }

  /// All refunds raised by the signed-in guest, newest first.
  Future<List<Map<String, dynamic>>> myRefunds() async {
    final res = await _api.dio.get('/refunds/my');
    final list = res.data['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getRefund(String refundId) async {
    final res = await _api.dio.get('/refunds/$refundId');
    return res.data['data'] as Map<String, dynamic>;
  }
}

class PassportRepository {
  final _api = AppDio();

  Future<Map<String, dynamic>> uploadPassport(String filePath) async {
    final formData = FormData.fromMap({
      'passport': await MultipartFile.fromFile(filePath),
    });
    final res = await _api.dio.post('/passport/upload', data: formData);
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStatus() async {
    final res = await _api.dio.get('/passport/status');
    return res.data['data'] as Map<String, dynamic>;
  }
}

class NotificationRepository {
  final _api = AppDio();

  Future<List<AppNotification>> getNotifications() async {
    final res = await _api.dio.get('/notifications');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<void> markAllRead() async {
    await _api.dio.patch('/notifications/read-all');
  }

  Future<void> saveToken(String fcmToken, {String platform = 'android'}) async {
    await _api.dio.post('/notifications/token', data: {
      'fcm_token': fcmToken,
      'platform': platform,
    });
  }
}

class NewsRepository {
  final _api = AppDio();

  Future<List<NewsItem>> list() async {
    final res = await _api.dio.get('/news');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => NewsItem.fromJson(e)).toList();
  }
}

class EventsRepository {
  final _api = AppDio();

  Future<List<KumbhEvent>> list() async {
    final res = await _api.dio.get('/events');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => KumbhEvent.fromJson(e)).toList();
  }
}

class OffersRepository {
  final _api = AppDio();

  Future<List<Offer>> list() async {
    final res = await _api.dio.get('/offers');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => Offer.fromJson(e)).toList();
  }
}

class SupportRepository {
  final _api = AppDio();

  /// [history] is `{role, content}` pairs (`role` is "user" or "assistant")
  /// in chronological order — the backend is stateless, so the app is what
  /// keeps the conversation and resends it each turn.
  Future<String> chat({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final res = await _api.dio.post('/support/chat', data: {
      'message': message,
      'history': history,
    });
    return res.data['data']['reply'] as String? ?? '';
  }
}

String dioErrorMessage(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'];
    return e.message ?? 'Network error';
  }
  return e.toString();
}
