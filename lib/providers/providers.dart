import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../core/constants/app_constants.dart';

// ── helpers ────────────────────────────────────────────────────────────────

String dioErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    switch (e.response?.statusCode) {
      case 400:
        return 'Please check all fields and try again.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Not found.';
      case 409:
        return 'Email already registered. Please login instead.';
      case 500:
        return 'Server error. Please try again later.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Cannot connect to server. Check your internet connection.';
    }
    return e.message ?? 'Network error. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}

Map<String, dynamic>? _extractUserMap(Map<String, dynamic> responseData) {
  final inner = responseData['data'];
  if (inner == null) return null;

  if (inner is Map<String, dynamic>) {
    if (inner.containsKey('user') && inner['user'] is Map<String, dynamic>) {
      return inner['user'] as Map<String, dynamic>;
    }
    if (inner.containsKey('id') || inner.containsKey('email')) {
      return inner;
    }
  }
  return null;
}

String? _extractToken(Map<String, dynamic> responseData) {
  final inner = responseData['data'];
  if (inner is Map<String, dynamic>) {
    return inner['access_token'] as String?;
  }
  return null;
}

enum AuthState { initial, loading, authenticated, unauthenticated, error }

enum TentState { idle, loading, loaded, error }

// ── Auth Provider ──────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _authRepo = AuthRepository();
  final _passportRepo = PassportRepository();
  final _notifRepo = NotificationRepository();

  Visitor? _visitor;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  // One-shot flag: true for the single home-screen build right after email
  // verification succeeds, so the passport-upload prompt shows exactly once
  // instead of on every visit to the home screen.
  bool _justVerifiedEmail = false;

  Visitor? get visitor => _visitor;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get justVerifiedEmail => _justVerifiedEmail;

  void clearJustVerifiedEmail() => _justVerifiedEmail = false;

  AuthState get authState {
    if (_isLoading) return AuthState.loading;
    if (_isAuthenticated) return AuthState.authenticated;
    return AuthState.unauthenticated;
  }

  AuthProvider() {
    _init();
  }

  // ── Init (restore session) ────────────────────────────────────────────────
  Future<void> _init() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final visitorJson = await _storage.read(key: AppConstants.visitorKey);

    if (token != null && visitorJson != null) {
      try {
        _visitor =
            Visitor.fromJson(jsonDecode(visitorJson) as Map<String, dynamic>);
        _isAuthenticated = true;
        notifyListeners();

        try {
          final meMap = await _authRepo.getMe();
          _visitor = Visitor.fromJson(meMap);
          await _storage.write(
              key: AppConstants.visitorKey, value: jsonEncode(meMap));
          notifyListeners();
        } catch (_) {}
      } catch (_) {
        await _storage.deleteAll();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider.login: calling _authRepo.login for $email');
      final response = await _authRepo.login(email: email, password: password);
      print('AuthProvider.login: response=$response');

      final token = _extractToken(response);
      if (token != null) {
        await _storage.write(key: AppConstants.tokenKey, value: token);
      }

      Map<String, dynamic>? userMap;
      if (token != null) {
        try {
          userMap = await _authRepo.getMe();
        } catch (_) {}
      }

      userMap ??= _extractUserMap(response);

      if (userMap != null) {
        _visitor = Visitor.fromJson(userMap);
        await _storage.write(
            key: AppConstants.visitorKey, value: jsonEncode(userMap));
      }

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      print('LOGIN EXCEPTION: $e');
      print('STACK: $stack');
      _error = dioErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String nationality,
    required String passportNumber,
    required String country,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authRepo.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        nationality: nationality,
        passportNumber: passportNumber,
        country: country,
      );

      final token = _extractToken(response);
      if (token != null) {
        await _storage.write(key: AppConstants.tokenKey, value: token);
      }

      Map<String, dynamic>? userMap;
      if (token != null) {
        try {
          userMap = await _authRepo.getMe();
        } catch (_) {}
      }

      userMap ??= _extractUserMap(response);

      if (userMap == null || _isUserMapEmpty(userMap)) {
        userMap = _mergeWithInputs(
          serverMap: userMap ?? {},
          fullName: fullName,
          email: email,
          phone: phone,
          nationality: nationality,
          passportNumber: passportNumber,
          country: country,
        );
      }

      _visitor = Visitor.fromJson(userMap);
      await _storage.write(
          key: AppConstants.visitorKey, value: jsonEncode(userMap));

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = dioErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Email verification ────────────────────────────────────────────────────
  Future<bool> verifyEmail(String code) async {
    _error = null;
    try {
      await _authRepo.verifyEmail(code);
      // Flip this locally before the profile refresh below, which hits its
      // own endpoint and silently no-ops on failure (network blip, timeout).
      // Without this, a flaky refresh left `visitor.emailVerified` stuck at
      // false even though the code was accepted — the router's verification
      // gate would then bounce the guest straight back to this screen, with
      // no visible error, right after they'd just succeeded.
      if (_visitor != null) {
        _visitor = _visitor!.copyWith(emailVerified: true);
      }
      notifyListeners();
      // Runs in the background — refreshProfile() persists the full server
      // record to storage once it lands, but the router gate above is
      // already unblocked regardless of whether this succeeds.
      unawaited(refreshProfile());
      _justVerifiedEmail = true;
      return true;
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerification() async {
    _error = null;
    try {
      await _authRepo.resendVerification();
      return true;
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── Refresh Profile ───────────────────────────────────────────────────────
  Future<void> refreshProfile() async {
    try {
      final meMap = await _authRepo.getMe();
      _visitor = Visitor.fromJson(meMap);
      await _storage.write(
          key: AppConstants.visitorKey, value: jsonEncode(meMap));
      notifyListeners();
    } catch (_) {}
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  //
  // FIX: The server's PATCH /auth/profile response may only echo back the
  // fields it updated (name, phone, profile_image_url). We must NOT replace
  // the whole visitor with that partial response — we merge the server data
  // OVER the existing visitor so nationality, country, passport etc. survive.
  //
  Future<bool> updateProfile({
    required String name,
    required String phone,
    File? profileImageFile,
    bool removeProfileImage = false,
  }) async {
    _error = null;
    try {
      // Build the current visitor as a base map so we never lose fields
      final currentMap = _visitorToMap(_visitor);

      final serverData = await _authRepo.updateProfile(
        name: name,
        phone: phone,
        profileImageFile: profileImageFile,
        removeProfileImage: removeProfileImage,
      );

      // Merge: start from current visitor, overlay server response fields
      // (only non-null / non-empty values from the server win)
      final mergedMap = _mergeServerUpdate(
        base: currentMap,
        serverData: serverData,
        name: name,
        phone: phone,
        removeImage: removeProfileImage,
      );

      _visitor = Visitor.fromJson(mergedMap);
      await _storage.write(
          key: AppConstants.visitorKey, value: jsonEncode(mergedMap));
      notifyListeners();
      return true;
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _authRepo.logout();
    } catch (_) {}
    await _storage.deleteAll();
    _visitor = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    try {
      await _authRepo.forgotPassword(email);
      return true;
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _authRepo.resetPassword(token: token, newPassword: newPassword);
      return true;
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── Passport Upload ───────────────────────────────────────────────────────
  Future<bool> uploadPassport(String filePath) async {
    try {
      final result = await _passportRepo.uploadPassport(filePath);
      if (_visitor != null) {
        _visitor = Visitor(
          id: _visitor!.id,
          fullName: _visitor!.fullName,
          email: _visitor!.email,
          phone: _visitor!.phone,
          nationality: _visitor!.nationality,
          passportNumber: _visitor!.passportNumber,
          country: _visitor!.country,
          isVerified: _visitor!.isVerified,
          passportUrl: result['passport_url'] as String?,
          passportStatus: (result['passport_status'] as String?) ?? 'uploaded',
          profileImageUrl: _visitor!.profileImageUrl,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> getPassportStatus() async {
    return await _passportRepo.getStatus();
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<List<AppNotification>> getNotifications() async {
    return await _notifRepo.getNotifications();
  }

  Future<void> markAllNotificationsRead() async {
    await _notifRepo.markAllRead();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  bool _isUserMapEmpty(Map<String, dynamic> map) {
    return (map['phone']?.toString().isEmpty ?? true) &&
        (map['nationality']?.toString().isEmpty ?? true) &&
        (map['country']?.toString().isEmpty ?? true);
  }

  Map<String, dynamic> _mergeWithInputs({
    required Map<String, dynamic> serverMap,
    required String fullName,
    required String email,
    required String phone,
    required String nationality,
    required String passportNumber,
    required String country,
  }) {
    return {
      'id': serverMap['id'] ?? '',
      'full_name': serverMap['full_name'] ?? serverMap['name'] ?? fullName,
      'name': serverMap['name'] ?? serverMap['full_name'] ?? fullName,
      'email': serverMap['email'] ?? email,
      'phone': serverMap['phone']?.toString().isNotEmpty == true
          ? serverMap['phone']
          : phone,
      'nationality': serverMap['nationality']?.toString().isNotEmpty == true
          ? serverMap['nationality']
          : nationality,
      'passport_no': serverMap['passport_no']?.toString().isNotEmpty == true
          ? serverMap['passport_no']
          : serverMap['passport_number'] ?? passportNumber,
      'country': serverMap['country']?.toString().isNotEmpty == true
          ? serverMap['country']
          : country,
      'is_verified': serverMap['is_verified'] ?? false,
      'passport_url': serverMap['passport_url'],
      'passport_status': serverMap['passport_status'] ?? 'none',
      'profile_image_url':
          serverMap['profile_image_url'] ?? serverMap['avatar_url'],
    };
  }

  /// Converts the current Visitor object back to a map so we can use it
  /// as a base when merging partial server responses.
  Map<String, dynamic> _visitorToMap(Visitor? v) {
    if (v == null) return {};
    return {
      'id': v.id,
      'full_name': v.fullName,
      'name': v.fullName,
      'email': v.email,
      'phone': v.phone,
      'nationality': v.nationality,
      'passport_no': v.passportNumber,
      'passport_number': v.passportNumber,
      'country': v.country,
      'is_verified': v.isVerified,
      'passport_url': v.passportUrl,
      'passport_status': v.passportStatus,
      'profile_image_url': v.profileImageUrl,
      'email_verified': v.emailVerified,
    };
  }

  /// Merges a partial server PATCH response over the existing visitor map.
  /// - The locally entered name/phone always win (user just typed them).
  /// - Non-null server fields win over the base for other fields.
  /// - Existing base fields are kept for anything the server didn't return.
  Map<String, dynamic> _mergeServerUpdate({
    required Map<String, dynamic> base,
    required Map<String, dynamic> serverData,
    required String name,
    required String phone,
    bool removeImage = false,
  }) {
    // Helper: pick first non-null, non-empty value
    String? pick(dynamic a, dynamic b) {
      final sa = a?.toString().trim();
      if (sa != null && sa.isNotEmpty) return sa;
      final sb = b?.toString().trim();
      if (sb != null && sb.isNotEmpty) return sb;
      return null;
    }

    return {
      'id': pick(serverData['id'], base['id']) ?? '',
      // User just typed these — always use the local values
      'full_name': name,
      'name': name,
      'phone': phone,
      'email': pick(serverData['email'], base['email']) ?? '',
      // Locked fields — keep from base; server may not echo them
      'nationality': pick(base['nationality'], serverData['nationality']) ?? '',
      'passport_no': pick(base['passport_no'], serverData['passport_no']) ?? '',
      'passport_number':
          pick(base['passport_number'], serverData['passport_number']) ?? '',
      'country': pick(base['country'], serverData['country']) ?? '',
      'is_verified': serverData['is_verified'] ?? base['is_verified'] ?? false,
      'passport_url': pick(serverData['passport_url'], base['passport_url']),
      'passport_status':
          pick(serverData['passport_status'], base['passport_status']) ??
              'none',
      // Profile image: server's new URL wins; fall back to existing.
      // A removal must short-circuit that fallback — the server returns null
      // for a cleared picture, which would otherwise restore the old URL from
      // base and make the deleted photo reappear.
      'profile_image_url': removeImage
          ? null
          : pick(
              serverData['profile_image_url'] ?? serverData['avatar_url'],
              base['profile_image_url'],
            ),
    };
  }
}

// ── Tent Provider ──────────────────────────────────────────────────────────

class TentProvider extends ChangeNotifier {
  final _tentRepo = TentRepository();
  final _paymentRepo = PaymentRepository();

  List<CapsuleTent> _tents = [];
  List<TentBooking> _bookings = [];
  TentState _state = TentState.idle;
  String? _error;

  List<CapsuleTent> get tents => _tents;
  List<TentBooking> get bookings => _bookings;
  TentState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == TentState.loading;

  Future<void> loadTents({String? tentType}) async {
    _state = TentState.loading;
    _error = null;
    notifyListeners();
    try {
      _tents = await _tentRepo.listTents(tentType: tentType);
      _state = TentState.loaded;
    } catch (e) {
      _error = dioErrorMessage(e);
      _state = TentState.error;
    }
    notifyListeners();
  }

  Future<TentBooking?> createBooking({
    required String tentId,
    required String checkInDate,
    required int duration,
    required int numGuests,
    String specialRequests = '',
    List<AdditionalGuest> additionalGuests = const [],
    String currency = 'INR',
    int roomCount = 1,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final checkIn = DateTime.parse(checkInDate);
      final checkOut = checkIn.add(Duration(days: duration));
      final checkOutDate =
          '${checkOut.year}-${checkOut.month.toString().padLeft(2, '0')}-'
          '${checkOut.day.toString().padLeft(2, '0')}';

      return await _tentRepo.createBooking(
        tentId: tentId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        numGuests: numGuests,
        specialRequests: specialRequests,
        additionalGuests: additionalGuests,
        currency: currency,
        roomCount: roomCount,
      );
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  // ── Multi-currency preview ──────────────────────────────────────────────
  Map<String, double>? _exchangeRates;
  Map<String, double>? get exchangeRates => _exchangeRates;

  Future<void> loadExchangeRates() async {
    try {
      _exchangeRates = await _tentRepo.exchangeRates();
      notifyListeners();
    } catch (_) {
      // Silent: the booking screen just falls back to INR-only if this fails.
    }
  }

  Future<void> loadMyBookings() async {
    _state = TentState.loading;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _tentRepo.myBookings();
      _state = TentState.loaded;
    } catch (e) {
      _error = dioErrorMessage(e);
      _state = TentState.error;
    }
    notifyListeners();
  }

  /// One booking, re-fetched from the server. Used by the detail screen's
  /// pull-to-refresh, where status, check-in and refund state can all have
  /// moved on since the list was loaded. Returns null if the fetch fails.
  Future<TentBooking?> fetchBooking(String id) async {
    try {
      return await _tentRepo.getBooking(id);
    } catch (_) {
      return null;
    }
  }

  /// What the guest would get back if they cancelled right now. Returns null
  /// on failure, with the reason in [error].
  Future<Map<String, dynamic>?> refundPreview(String bookingId) async {
    _error = null;
    try {
      return await _tentRepo.refundPreview(bookingId);
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> cancelBooking(String bookingId,
      {String? reason}) async {
    _error = null;
    try {
      final data = await _tentRepo.cancelBooking(bookingId, reason: reason);
      // Update in place rather than removing — a cancelled booking still
      // belongs in the "Past" tab (my_bookings_screen.dart buckets by
      // status), it just doesn't belong in "Active" anymore. Deleting it
      // outright made it vanish from every tab until the next manual
      // pull-to-refresh re-fetched the real list from the server.
      final i = _bookings.indexWhere((b) => b.id == bookingId);
      if (i != -1) {
        _bookings[i] = _bookings[i].copyWith(status: 'cancelled');
      }
      notifyListeners();
      return data;
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  // ── Reviews ────────────────────────────────────────────────────────────

  Future<bool> submitBookingReview({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    _error = null;
    try {
      await _tentRepo.submitBookingReview(
          bookingId: bookingId, rating: rating, comment: comment);
      return true;
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<TentReview?> getBookingReview(String bookingId) async {
    try {
      return await _tentRepo.getBookingReview(bookingId);
    } catch (_) {
      return null;
    }
  }

  Future<TentReviewSummary> tentReviews(String tentId) async {
    try {
      return await _tentRepo.tentReviews(tentId);
    } catch (_) {
      return const TentReviewSummary();
    }
  }

  /// The refund raised against a booking, if any.
  Future<Map<String, dynamic>?> bookingRefund(String bookingId) async {
    try {
      return await _tentRepo.bookingRefund(bookingId);
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> myRefunds() async {
    try {
      return await _paymentRepo.myRefunds();
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return [];
    }
  }

  Future<Map<String, dynamic>?> getQRCode(String bookingId) async {
    try {
      return await _tentRepo.getQRCode(bookingId);
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> createPaymentOrder(String bookingId) async {
    try {
      return await _paymentRepo.createOrder(bookingId);
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      await _paymentRepo.verifyPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
      return true;
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
// ── Wishlist Provider ──────────────────────────────────────────────────────

/// Saved tents. Holds both the tent records (for the wishlist screen) and a
/// set of saved ids (so any heart icon can render its state without a lookup
/// through the list).
class WishlistProvider extends ChangeNotifier {
  final _tentRepo = TentRepository();

  List<CapsuleTent> _tents = [];
  Set<String> _savedIds = {};
  bool _isLoading = false;
  bool _loadedOnce = false;
  String? _error;

  List<CapsuleTent> get tents => _tents;
  bool get isLoading => _isLoading;
  bool get isEmpty => _tents.isEmpty;
  int get count => _savedIds.length;
  String? get error => _error;

  bool isSaved(String tentId) => _savedIds.contains(tentId);

  Future<void> load({bool force = false}) async {
    if (_loadedOnce && !force) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _tents = await _tentRepo.wishlist();
      _savedIds = _tents.map((t) => t.id).toSet();
      _loadedOnce = true;
    } catch (e) {
      _error = dioErrorMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Flips the saved state and returns the new value. The UI updates before
  /// the request completes so the heart never lags behind the tap; if the
  /// server rejects it, the change is rolled back and [error] is set.
  Future<bool> toggle(CapsuleTent tent) async {
    final wasSaved = _savedIds.contains(tent.id);
    final previousTents = List<CapsuleTent>.from(_tents);

    if (wasSaved) {
      _savedIds.remove(tent.id);
      _tents.removeWhere((t) => t.id == tent.id);
    } else {
      _savedIds.add(tent.id);
      _tents.insert(0, tent);
    }
    _error = null;
    notifyListeners();

    try {
      if (wasSaved) {
        await _tentRepo.removeFromWishlist(tent.id);
      } else {
        await _tentRepo.addToWishlist(tent.id);
      }
      return !wasSaved;
    } catch (e) {
      if (wasSaved) {
        _savedIds.add(tent.id);
      } else {
        _savedIds.remove(tent.id);
      }
      _tents = previousTents;
      _error = dioErrorMessage(e);
      notifyListeners();
      return wasSaved;
    }
  }

  /// Signing out must not leak one guest's saved tents into the next session.
  void clear() {
    _tents = [];
    _savedIds = {};
    _loadedOnce = false;
    _error = null;
    notifyListeners();
  }
}

// ── AI Support Chat ──────────────────────────────────────────────────────────
class SupportProvider extends ChangeNotifier {
  final _supportRepo = SupportRepository();

  String? get error => _error;
  String? _error;

  Future<String?> chat({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    _error = null;
    try {
      return await _supportRepo.chat(message: message, history: history);
    } catch (e) {
      _error = dioErrorMessage(e);
      notifyListeners();
      return null;
    }
  }
}
