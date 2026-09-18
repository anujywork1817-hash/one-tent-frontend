// ─── Visitor ──────────────────────────────────────────────────────────────────

class Visitor {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String nationality;
  final String passportNumber;
  final String country;
  final bool isVerified;
  final String? passportUrl;
  final String passportStatus;
  final String? profileImageUrl;
  final bool emailVerified;

  const Visitor({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.nationality,
    required this.passportNumber,
    required this.country,
    required this.isVerified,
    this.passportUrl,
    this.passportStatus = 'none',
    this.profileImageUrl,
    this.emailVerified = false,
  });

  factory Visitor.fromJson(Map<String, dynamic> j) => Visitor(
        id: j['id'] ?? '',
        fullName: j['full_name'] ?? j['name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] ?? '',
        nationality: j['nationality'] ?? '',
        passportNumber: j['passport_no'] ?? j['passport_number'] ?? '',
        country: j['country'] ?? '',
        isVerified: j['is_verified'] ?? j['is_active'] ?? false,
        passportUrl: j['passport_url'],
        passportStatus: j['passport_status'] ?? 'none',
        profileImageUrl: j['profile_image_url'] ?? j['avatar_url'],
        emailVerified: j['email_verified'] ?? false,
      );

  Visitor copyWith({bool? emailVerified, String? email}) => Visitor(
        id: id,
        fullName: fullName,
        email: email ?? this.email,
        phone: phone,
        nationality: nationality,
        passportNumber: passportNumber,
        country: country,
        isVerified: isVerified,
        passportUrl: passportUrl,
        passportStatus: passportStatus,
        profileImageUrl: profileImageUrl,
        emailVerified: emailVerified ?? this.emailVerified,
      );
}

// ─── CapsuleTent ──────────────────────────────────────────────────────────────

class CapsuleTent {
  final String id;
  final String name;
  final String tentTypeStr;
  final String description;
  final int capacity;
  final String? imageUrl;
  /// Every photo the admin uploaded for this tent, in order — imageUrl is
  /// just imageUrls.first, kept for the many call sites that only show one.
  final List<String> imageUrls;
  final bool isAvailable;
  final String locationStr;

  final double price1Day;
  final double price3Days;
  final double price7Days;
  final double price15Days;
  final double price30Days;

  final bool hasAC;
  final bool hasWifi;
  final bool hasBathroom;
  final bool hasTV;
  final bool hasFridge;
  final bool hasSofa;
  final bool hasAirPurifier;
  final bool hasPowerBackup;
  final bool instantConfirm;

  String get tentNumber => name;
  String get tentType => tentTypeStr;
  String get location => locationStr;
  int get maxOccupancy => capacity;
  double get pricePerNight => price1Day;

  /// "Single Bed" / "Double Bed" — read off the tent type when it says so
  /// directly, otherwise inferred from capacity (2+ guests needs a double).
  /// A type like "luxury" doesn't name a bed config itself, so this always
  /// falls through to capacity for it.
  String get bedLabel {
    final t = tentTypeStr.toLowerCase();
    if (t.contains('single')) return 'Single Bed';
    if (t.contains('double')) return 'Double Bed';
    return capacity <= 1 ? 'Single Bed' : 'Double Bed';
  }

  List<String> get amenities {
    final list = <String>[];
    if (hasAC) list.add('AC');
    if (hasWifi) list.add('WiFi');
    if (hasBathroom) list.add('Bathroom');
    if (hasTV) list.add('TV');
    if (hasFridge) list.add('Fridge');
    if (hasSofa) list.add('Sofa');
    if (hasAirPurifier) list.add('Air Purifier');
    if (hasPowerBackup) list.add('Power Backup');
    return list;
  }

  const CapsuleTent({
    required this.id,
    required this.name,
    required this.tentTypeStr,
    required this.description,
    required this.capacity,
    this.imageUrl,
    this.imageUrls = const [],
    required this.isAvailable,
    required this.locationStr,
    required this.price1Day,
    required this.price3Days,
    required this.price7Days,
    required this.price15Days,
    required this.price30Days,
    this.hasAC = false,
    this.hasWifi = false,
    this.hasBathroom = false,
    this.hasTV = false,
    this.hasFridge = false,
    this.hasSofa = false,
    this.hasAirPurifier = false,
    this.hasPowerBackup = false,
    this.instantConfirm = true,
  });

  factory CapsuleTent.fromJson(Map<String, dynamic> j) {
    final isNewBackend =
        j.containsKey('price_1_day') || j.containsKey('max_occupancy');

    final rawAmenities = List<String>.from(j['amenities'] ?? []);
    bool fromAmenities(String keyword) =>
        rawAmenities.any((a) => a.toLowerCase().contains(keyword));

    final pricePerDay = (j['price_per_day'] ?? 0).toDouble();

    return CapsuleTent(
      id: j['id'] ?? '',
      name: j['tent_number'] ?? j['name'] ?? '',
      tentTypeStr: j['tent_type'] ?? j['type'] ?? 'regular',
      description: j['description'] ?? '',
      capacity: j['max_occupancy'] ?? j['capacity'] ?? 1,
      imageUrl:
          (j['image_urls'] is List && (j['image_urls'] as List).isNotEmpty)
              ? j['image_urls'][0] as String
              : j['image_url'],
      imageUrls: j['image_urls'] is List
          ? List<String>.from(
              (j['image_urls'] as List).where((u) => u is String && u.isNotEmpty))
          : (j['image_url'] != null && (j['image_url'] as String).isNotEmpty
              ? [j['image_url'] as String]
              : const []),
      isAvailable: j['is_available'] ?? j['is_active'] ?? true,
      locationStr: j['location'] ?? 'Nashik Kumbh Mela',
      price1Day: isNewBackend
          ? (j['price_1_day'] ?? pricePerDay).toDouble()
          : pricePerDay,
      price3Days: isNewBackend
          ? (j['price_3_days'] ?? pricePerDay * 3).toDouble()
          : pricePerDay * 3 * 0.95,
      price7Days: isNewBackend
          ? (j['price_7_days'] ?? pricePerDay * 7).toDouble()
          : pricePerDay * 7 * 0.90,
      price15Days: isNewBackend
          ? (j['price_15_days'] ?? pricePerDay * 15).toDouble()
          : pricePerDay * 15 * 0.85,
      price30Days: isNewBackend
          ? (j['price_30_days'] ?? pricePerDay * 30).toDouble()
          : pricePerDay * 30 * 0.80,
      hasAC: j['has_ac'] ?? fromAmenities('ac'),
      hasWifi: j['has_wifi'] ?? fromAmenities('wifi'),
      hasBathroom: j['has_bathroom'] ?? fromAmenities('bath'),
      hasTV: j['has_tv'] ?? fromAmenities('tv'),
      hasFridge: j['has_fridge'] ?? fromAmenities('fridge'),
      hasSofa: j['has_sofa'] ?? fromAmenities('sofa'),
      hasAirPurifier: j['has_air_purifier'] ?? fromAmenities('air purifier'),
      hasPowerBackup: j['has_power_backup'] ?? fromAmenities('power'),
      instantConfirm: j['instant_confirm'] ?? true,
    );
  }

  double priceFor(int days) {
    if (days >= 30) return price30Days;
    if (days >= 15) return price15Days;
    if (days >= 7) return price7Days;
    if (days >= 3) return price3Days;
    return price1Day * days;
  }
}

// ─── AdditionalGuest ────────────────────────────────────────────────────────

class AdditionalGuest {
  final String name;
  final String phone;

  const AdditionalGuest({required this.name, required this.phone});

  factory AdditionalGuest.fromJson(Map<String, dynamic> j) => AdditionalGuest(
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
      );

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
}

/// Real per-day occupancy for one date, across every tent of a given type —
/// what the booking calendar colors green ("available"), yellow ("limited",
/// a few rooms of this type left), or red ("booked", none left).
class DayAvailability {
  final int total;
  final int booked;
  final int free;
  final String status; // "available" | "limited" | "booked"

  const DayAvailability({
    required this.total,
    required this.booked,
    required this.free,
    required this.status,
  });

  factory DayAvailability.fromJson(Map<String, dynamic> j) => DayAvailability(
        total: (j['total'] as num?)?.toInt() ?? 0,
        booked: (j['booked'] as num?)?.toInt() ?? 0,
        free: (j['free'] as num?)?.toInt() ?? 0,
        status: j['status'] as String? ?? 'available',
      );
}

/// Result of checking a coupon code with the server before booking —
/// preview only, re-validated for real when the booking is created.
class CouponPreview {
  final bool valid;
  final String? code;
  final String? discountType; // "percent" | "flat"
  final double discountValue;
  final String message;

  const CouponPreview({
    required this.valid,
    this.code,
    this.discountType,
    this.discountValue = 0,
    this.message = '',
  });

  factory CouponPreview.fromJson(Map<String, dynamic> j) => CouponPreview(
        valid: j['valid'] as bool? ?? false,
        code: j['code'] as String?,
        discountType: j['discount_type'] as String?,
        discountValue: (j['discount_value'] as num?)?.toDouble() ?? 0,
        message: j['message'] as String? ?? '',
      );

  /// This coupon's discount off [preTaxAmount] — mirrors the server's own
  /// Discount() so the preview matches what booking creation will compute.
  double discountFor(double preTaxAmount) {
    if (!valid) return 0;
    if (discountType == 'percent') return preTaxAmount * discountValue / 100;
    return discountValue > preTaxAmount ? preTaxAmount : discountValue;
  }
}

// ─── TentBooking ──────────────────────────────────────────────────────────────

class TentBooking {
  final String id;
  final String tentId;
  final String? tentName;
  final String checkInDate;
  final String checkOutDate;
  final int numGuests;
  final double totalPrice;
  final String status;
  final String? qrToken;
  final String? bookingRefStr;
  final DateTime? createdAt;
  final int nights;
  final List<AdditionalGuest> additionalGuests;
  final double baseAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double gstRate;
  // Foreign-currency preview, frozen at booking time — the actual Razorpay
  // charge is always totalPrice in INR regardless. displayCurrency is "INR"
  // when the guest didn't pick a foreign currency.
  final String displayCurrency;
  final double exchangeRate;
  final double? foreignAmount;

  // Set only when this booking is the primary room of a multi-room "Rooms &
  // Guests" checkout (see backend migration 018) — a plain single-room
  // booking leaves all three null/1, unchanged from before this existed.
  final String? groupId;
  final int roomCount;
  final double? groupTotalAmount;
  final String? couponCode;
  final double discountAmount;
  // Children traveling with the party — under-5s are free (kept only for
  // the record), above-5s each added childFee to the total once, not per
  // night and not split across rooms. See backend migration 025.
  final int childrenUnder5;
  final int childrenAbove5;
  final double childFee;

  const TentBooking({
    required this.id,
    required this.tentId,
    this.tentName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numGuests,
    required this.totalPrice,
    required this.status,
    this.qrToken,
    this.bookingRefStr,
    this.createdAt,
    this.nights = 1,
    this.additionalGuests = const [],
    this.baseAmount = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.gstRate = 0,
    this.displayCurrency = 'INR',
    this.exchangeRate = 1,
    this.foreignAmount,
    this.groupId,
    this.roomCount = 1,
    this.groupTotalAmount,
    this.couponCode,
    this.discountAmount = 0,
    this.childrenUnder5 = 0,
    this.childrenAbove5 = 0,
    this.childFee = 0,
  });

  factory TentBooking.fromJson(Map<String, dynamic> j) {
    String parseDate(dynamic val) {
      if (val == null) return '';
      final s = val.toString();
      if (s.isEmpty) return '';
      return s.length > 10 ? s.substring(0, 10) : s;
    }

    return TentBooking(
      id: j['id']?.toString() ?? '',
      tentId: j['tent_id']?.toString() ?? '',
      tentName: j['tent_name'] ?? j['tent']?['number'],
      checkInDate: parseDate(j['check_in_date'] ?? j['check_in']),
      checkOutDate: parseDate(j['check_out_date'] ?? j['check_out']),
      numGuests: j['guests'] ?? j['num_guests'] ?? 1,
      totalPrice: (j['total_amount'] ?? j['total_price'] ?? 0).toDouble(),
      status: j['status'] ?? 'pending',
      qrToken: j['qr_token'],
      bookingRefStr: j['booking_ref'],
      nights: j['nights'] ?? 1,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
      additionalGuests: (j['additional_guests'] as List<dynamic>? ?? [])
          .map((g) => AdditionalGuest.fromJson(g as Map<String, dynamic>))
          .toList(),
      baseAmount: (j['base_amount'] ?? 0).toDouble(),
      cgstAmount: (j['cgst_amount'] ?? 0).toDouble(),
      sgstAmount: (j['sgst_amount'] ?? 0).toDouble(),
      gstRate: (j['gst_rate'] ?? 0).toDouble(),
      displayCurrency: j['display_currency'] ?? 'INR',
      exchangeRate: (j['exchange_rate'] ?? 1).toDouble(),
      foreignAmount: j['foreign_amount'] != null
          ? (j['foreign_amount'] as num).toDouble()
          : null,
      groupId: j['group_id']?.toString(),
      roomCount: (j['room_count'] as num?)?.toInt() ?? 1,
      groupTotalAmount: j['group_total_amount'] != null
          ? (j['group_total_amount'] as num).toDouble()
          : null,
      couponCode: j['coupon_code']?.toString(),
      discountAmount: (j['discount_amount'] ?? 0).toDouble(),
      childrenUnder5: (j['children_under5'] as num?)?.toInt() ?? 0,
      childrenAbove5: (j['children_above5'] as num?)?.toInt() ?? 0,
      childFee: (j['child_fee'] ?? 0).toDouble(),
    );
  }

  /// What the guest is actually charged — the group total for a multi-room
  /// booking, or just this booking's own total otherwise.
  double get amountDue => groupTotalAmount ?? totalPrice;

  TentBooking copyWith({String? status}) => TentBooking(
        id: id,
        tentId: tentId,
        tentName: tentName,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        numGuests: numGuests,
        totalPrice: totalPrice,
        status: status ?? this.status,
        qrToken: qrToken,
        bookingRefStr: bookingRefStr,
        createdAt: createdAt,
        nights: nights,
        additionalGuests: additionalGuests,
        baseAmount: baseAmount,
        cgstAmount: cgstAmount,
        sgstAmount: sgstAmount,
        gstRate: gstRate,
        displayCurrency: displayCurrency,
        exchangeRate: exchangeRate,
        foreignAmount: foreignAmount,
        groupId: groupId,
        roomCount: roomCount,
        groupTotalAmount: groupTotalAmount,
        couponCode: couponCode,
        discountAmount: discountAmount,
        childrenUnder5: childrenUnder5,
        childrenAbove5: childrenAbove5,
        childFee: childFee,
      );

  String get bookingRef =>
      bookingRefStr ??
      (id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase());
  DateTime get bookedAt => createdAt ?? DateTime.now();
  String get currency => 'INR';
  double get totalAmount => totalPrice;
  String get paymentStatus =>
      (status == 'confirmed' || status == 'completed') ? 'paid' : 'pending';
  String get specialRequests => '';
  String get adminNotes => '';

  int get duration {
    if (nights > 0) return nights;
    try {
      return DateTime.parse(checkOutDate)
          .difference(DateTime.parse(checkInDate))
          .inDays;
    } catch (_) {
      return 1;
    }
  }

  DateTime get checkInDateTime {
    try {
      return DateTime.parse(checkInDate);
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTime get checkOutDateTime {
    try {
      return DateTime.parse(checkOutDate);
    } catch (_) {
      return DateTime.now().add(const Duration(days: 1));
    }
  }
}

// ─── AppNotification ──────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        message: j['message'] ?? j['body'] ?? '',
        type: j['type'] ?? 'general',
        isRead: j['is_read'] ?? j['read'] ?? false,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
// ─── News ─────────────────────────────────────────────────────────────────────

class NewsItem {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime createdAt;

  /// Set only for live-fetched articles (NewsAPI/GNews), never for
  /// admin-posted announcements. The app links out to [sourceUrl] instead of
  /// rendering these as a full in-app post, since the body is just a snippet.
  final bool isExternal;
  final String? sourceName;
  final String? sourceUrl;

  const NewsItem({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.createdAt,
    this.isExternal = false,
    this.sourceName,
    this.sourceUrl,
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        imageUrl: j['image_url'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isExternal: j['is_external'] ?? false,
        sourceName: j['source_name'] as String?,
        sourceUrl: j['source_url'] as String?,
      );
}

// ─── Kumbh Event (calendar of bathing / festival dates) ───────────────────────

class KumbhEvent {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String eventType; // snan | festival | general

  const KumbhEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.eventType,
  });

  factory KumbhEvent.fromJson(Map<String, dynamic> j) => KumbhEvent(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        eventDate: DateTime.tryParse(j['event_date']?.toString() ?? '') ??
            DateTime.now(),
        eventType: j['event_type'] ?? 'general',
      );
}

// ─── Offer ─────────────────────────────────────────────────────────────────

class Offer {
  final String id;
  final String title;
  final String description;
  final String? discountText;
  final String? imageUrl;
  final DateTime? validUntil;

  const Offer({
    required this.id,
    required this.title,
    required this.description,
    this.discountText,
    this.imageUrl,
    this.validUntil,
  });

  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        discountText: (j['discount_text'] as String?)?.isEmpty ?? true
            ? null
            : j['discount_text'],
        imageUrl: j['image_url'] as String?,
        validUntil: j['valid_until'] != null
            ? DateTime.tryParse(j['valid_until'].toString())
            : null,
      );
}

// ─── Tent Reviews ───────────────────────────────────────────────────────────

class TentReview {
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final String guestName;

  const TentReview({
    required this.rating,
    this.comment = '',
    this.createdAt,
    this.guestName = 'Guest',
  });

  factory TentReview.fromJson(Map<String, dynamic> j) => TentReview(
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        comment: j['comment'] ?? '',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
        guestName: (j['guest_name'] as String?)?.isNotEmpty == true
            ? j['guest_name']
            : 'Guest',
      );
}

class TentReviewSummary {
  final List<TentReview> reviews;
  final double averageRating;
  final int totalReviews;

  const TentReviewSummary({
    this.reviews = const [],
    this.averageRating = 0,
    this.totalReviews = 0,
  });

  factory TentReviewSummary.fromJson(Map<String, dynamic> j) {
    final list = j['reviews'] as List? ?? [];
    return TentReviewSummary(
      reviews: list.map((e) => TentReview.fromJson(e)).toList(),
      averageRating: (j['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (j['total_reviews'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A booking of this guest's that's actually eligible to be reviewed — see
/// TentRepository.myReviewableBooking.
class ReviewableBooking {
  final String bookingId;
  final bool alreadyReviewed;

  const ReviewableBooking({
    required this.bookingId,
    required this.alreadyReviewed,
  });

  factory ReviewableBooking.fromJson(Map<String, dynamic> j) =>
      ReviewableBooking(
        bookingId: j['booking_id']?.toString() ?? '',
        alreadyReviewed: j['already_reviewed'] as bool? ?? false,
      );
}
