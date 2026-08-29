class AppConstants {
  // ✅ Real Android phone (same WiFi)
 // static const String baseUrl = 'http://192.168.1.32:8082/api/v1';
//static const String baseUrl = 'https://kumbh-booking.onrender.com/api/v1';
//static const String baseUrl = 'http://192.168.1.222:9191/api/v1';
  // static const String baseUrl = 'http://localhost:8082/api/v1'; // Chrome
   //static const String baseUrl = 'http://onebharat-foreigntent.ap-south-1.elasticbeanstalk.com/api/v1'; // Android emulator

//static const String baseUrl = 'http://onebharat-foreigntent.ap-south-1.elasticbeanstalk.com/api/v1';

   //static const String baseUrl = 'http://localhost:8082/api/v1'; // local backend via `adb reverse tcp:8082 tcp:8082`
   //static const String baseUrl = 'http://onebharat-foreigntent.ap-south-1.elasticbeanstalk.com/api/v1'; // Android emulator

   //static const String baseUrl = 'http://onebharat-foreigntent-env-2.eba-8m5cvcjn.ap-south-1.elasticbeanstalk.com/api/v1';

  // ── LOCAL DEVELOPMENT (kept for reference) ───────────────────────────────
  //static const String baseUrl = 'http://localhost:9090/api/v1'; // Chrome / desktop
  // static const String baseUrl = 'http://10.0.2.2:9090/api/v1';    // Android emulator
  //static const String baseUrl = 'http://192.168.1.43:9090/api/v1'; // real device on same WiFi

  // ── LIVE SERVER ───────────────────────────────────────────────────────────
  // Retired LAN box — beellz@192.168.1.222, systemd service "kumbh", port
  // 9191 (see deploy.ps1). Kept for reference in case of AWS rollback.
  // static const String baseUrl = 'http://192.168.1.222:9191/api/v1';

  // AWS: Elastic Beanstalk (ap-south-1) + RDS Postgres, migrated 2026-08-24.
  // EB's own URL is plain HTTP with no ACM cert attached (single-instance env,
  // no ALB) — fine for a native app, but the web build is served over HTTPS
  // via CloudFront and browsers block HTTP XHR from an HTTPS page outright
  // ("mixed content"), not just via CORS. This CloudFront distribution
  // (d1zv5r6hib9b8n) sits in front of the EB origin purely to terminate TLS,
  // using CloudFront's free default certificate — no custom domain needed.
  static const String baseUrl =
      'https://d1zv5r6hib9b8n.cloudfront.net/api/v1';






  /// Resolves a host-relative upload path such as `/uploads/passports/x.jpg`
  /// against whichever API host the app is pointed at. The backend stores these
  /// relative so the same row works from a phone, a browser and the admin
  /// console — it must not bake in a hostname.
  static String fileUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final origin = baseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
    return path.startsWith('/') ? '$origin$path' : '$origin/$path';
  }

  // Storage keys
  static const String tokenKey = 'visitor_token';
  static const String visitorKey = 'visitor_data';

  // Tent durations
  static const List<Map<String, dynamic>> durations = [
    {'label': '1 Day', 'value': '1'},
    {'label': '3 Days', 'value': '3'},
    {'label': '7 Days', 'value': '7'},
    {'label': '15 Days', 'value': '15'},
    {'label': '30 Days', 'value': '30'},
  ];

  // Tent types — must match backend exactly
  static const List<String> tentTypes = ['single', 'double', 'luxury'];

  // Booking statuses
  static const Map<String, String> bookingStatusLabels = {
    'confirmed': 'Confirmed',
    'cancelled': 'Cancelled',
    'completed': 'Completed',
    'pending': 'Pending',
  };
}

