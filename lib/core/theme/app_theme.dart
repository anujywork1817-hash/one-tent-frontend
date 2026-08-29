import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  One Tent — Maroon & Gold Theme
// ─────────────────────────────────────────────
//  Primary bg      : #0D0401  (near-black maroon)
//  Surface         : #1C0906  (dark maroon card)
//  Surface border  : #3D1A0D
//  Gold accent     : #D4891A  (primaryBlue → gold)
//  Gold light      : #E8A93A  (accentCyan  → gold light)
//  Cream text      : #F5E6C8
//  Muted text      : #A07850
//  Error           : #C0392B
// ─────────────────────────────────────────────

class AppColors {
  // ── Primary palette ───────────────────────
  /// Main interactive colour — gold (was primaryBlue)
  static const Color primaryBlue    = Color(0xFFD4891A);
  /// Deep maroon hero/app-bar background (was darkBlue)
  static const Color darkBlue       = Color(0xFF0D0401);
  /// Lighter gold highlight — "Stay" text etc. (was accentCyan)
  static const Color accentCyan     = Color(0xFFE8A93A);
  /// Dark maroon chip / icon backgrounds (was lightBlue)
  static const Color lightBlue      = Color(0xFF1C0906);
  /// Mid maroon (was skyBlue)
  static const Color skyBlue        = Color(0xFF3D1A0D);

  // ── Neutral palette ───────────────────────
  /// Pure white — kept for overlays / badges
  static const Color white          = Color(0xFFFFFFFF);
  /// Page background — near-black maroon (was off-white)
  static const Color background     = Color(0xFF0D0401);
  /// Card background — dark maroon surface
  static const Color cardSurface    = Color(0xFF1C0906);
  /// Subtle borders / dividers
  static const Color divider        = Color(0xFF3D1A0D);
  /// Input field fill — slightly lighter maroon
  static const Color inputBg        = Color(0xFF170603);

  // ── Text ──────────────────────────────────
  /// Near-white cream for headings (was near-black)
  static const Color textPrimary    = Color(0xFFF5E6C8);
  /// Muted warm-brown for body text
  static const Color textSecondary  = Color(0xFFA07850);
  /// Placeholder / hint
  static const Color textHint       = Color(0xFF7A5535);
  /// Text on dark backgrounds (same as textPrimary here)
  static const Color textOnDark     = Color(0xFFF5E6C8);
  /// Muted text on dark backgrounds
  static const Color textOnDarkMuted = Color(0xFFBE9060);

  // ── Semantic ──────────────────────────────
  static const Color success        = Color(0xFF22C55E);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color error          = Color(0xFFC0392B);
  static const Color starGold       = Color(0xFFD4891A);

  // ── Bottom nav ────────────────────────────
  static const Color navActive      = Color(0xFFD4891A);
  static const Color navInactive    = Color(0xFF7A5535);
  static const Color navBackground  = Color(0xFF1C0906);

  // ── Legacy aliases ────────────────────────
  static const Color kumbhSaffron   = primaryBlue;
  static const Color kumbhBlue      = darkBlue;
  static const Color kumbhGold      = accentCyan;
  static const Color primaryRed     = primaryBlue;
  static const Color secondaryRed   = skyBlue;
}

class AppTextStyles {
  // Display
  static const TextStyle heroTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnDark,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnDarkMuted,
    height: 1.4,
  );

  // Section headings
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionLink = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,   // gold
  );

  // Card
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle priceTag = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryBlue,   // gold
  );

  static const TextStyle priceUnit = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Search form
  static const TextStyle searchLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
    letterSpacing: 0.2,
  );

  static const TextStyle searchValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Category
  static const TextStyle categoryLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Amenity chip
  static const TextStyle amenityText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Button
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonOutline = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
  );

  // Nav bar
  static const TextStyle navLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // Rating
  static const TextStyle ratingText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
  );

  // App bar title
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnDark,
    letterSpacing: -0.3,
  );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary:    AppColors.primaryBlue,    // gold
        onPrimary:  AppColors.darkBlue,       // near-black text on gold btn
        secondary:  AppColors.accentCyan,     // gold-light
        onSecondary: AppColors.darkBlue,
        error:      AppColors.error,
        onError:    AppColors.white,
        surface:    AppColors.cardSurface,    // dark maroon
        onSurface:  AppColors.textPrimary,    // cream
      ),
      scaffoldBackgroundColor: AppColors.background,

      // ── App bar ──────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: IconThemeData(color: AppColors.textOnDark),
      ),

      // ── Card ─────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated button ──────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF7A1F0A),   // deep maroon button
          foregroundColor: AppColors.textOnDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(
                color: AppColors.primaryBlue.withValues(alpha: 0.5)),
          ),
          textStyle: AppTextStyles.buttonPrimary,
        ),
      ),

      // ── Outlined button ──────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTextStyles.buttonOutline,
        ),
      ),

      // ── Input decoration ─────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(
            color: AppColors.error, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),

      // ── Bottom nav ───────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: AppTextStyles.navLabel,
        unselectedLabelStyle: AppTextStyles.navLabel,
      ),

      // ── Divider ──────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ─────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBlue,
        labelStyle: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Icon ─────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.primaryBlue,   // gold
        size: 20,
      ),

      // ── Text theme ───────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ── Gradient helpers ─────────────────────

  /// Hero section gradient — deep maroon to transparent
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D0401),
      Color(0xFF2A0E05),
      Color(0x882A0E05),
      Colors.transparent,
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  /// Card image overlay gradient
  static const LinearGradient cardOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x990D0401),
    ],
  );

  /// Primary action button gradient — maroon
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF9A2A0E),
      Color(0xFF7A1F0A),
    ],
  );

  // ── Decoration helpers ───────────────────

  static BoxDecoration get whiteCard => BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get searchCard => BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get categoryChip => BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      );

  static BoxDecoration get primaryButton => BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get ratingBadge => BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      );

  // ── Legacy static getters ────────────────

  static Color get saffron    => AppColors.primaryBlue;
  static Color get gold       => AppColors.accentCyan;
  static Color get riverBlue  => AppColors.darkBlue;
  static Color get error      => AppColors.error;
  static Color get success    => AppColors.success;
  static Color get textDark   => AppColors.textPrimary;
  static Color get textLight  => AppColors.textSecondary;
  static Color get divider    => AppColors.divider;
  static Color get background => AppColors.background;
  static Color get white      => AppColors.white;
}