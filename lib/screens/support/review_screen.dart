import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';

const _kHeroBg      = Color(0xFF4A1000);
const _kBodyBg      = Color(0xFFFFFFFF);
const _kCardBg      = Color(0xFFFFFFFF);
const _kBorderLight = Color(0xFFDDD0C4);
const _kGold        = Color(0xFFD4891A);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextLight   = Color(0xFFA07050);
const _kError       = Color(0xFFC0392B);
const _kSuccess     = Color(0xFF2E7D32);

/// Rate & review a specific stay. Reviews used to just open the guest's
/// email app with a mailto: link — nothing was ever stored, so no one could
/// see past reviews. This submits in-app instead, tied to the booking so
/// only guests who actually stayed can leave one, and other guests see it
/// on the tent's own detail page while browsing/booking.
class ReviewScreen extends StatefulWidget {
  final String bookingId;
  final String tentName;
  const ReviewScreen(
      {super.key, required this.bookingId, required this.tentName});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  String? _error;
  bool _sending = false;
  bool _loadingExisting = true;

  static const _labels = {
    1: 'Poor',
    2: 'Fair',
    3: 'Good',
    4: 'Very Good',
    5: 'Excellent',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  Future<void> _loadExisting() async {
    final existing =
        await context.read<TentProvider>().getBookingReview(widget.bookingId);
    if (!mounted) return;
    setState(() {
      if (existing != null) {
        _rating = existing.rating;
        _commentCtrl.text = existing.comment;
      }
      _loadingExisting = false;
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a star rating');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });

    final tentProv = context.read<TentProvider>();
    final ok = await tentProv.submitBookingReview(
      bookingId: widget.bookingId,
      rating: _rating,
      comment: _commentCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Thanks — your review is live for other guests to see.'),
        backgroundColor: _kSuccess,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } else {
      setState(() =>
          _error = tentProv.error ?? 'Could not submit your review');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        surfaceTintColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _kTextDark, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text('Rate & Review',
            style: TextStyle(
                color: _kTextDark, fontWeight: FontWeight.w700, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorderLight),
        ),
      ),
      body: _loadingExisting
          ? const Center(
              child: CircularProgressIndicator(color: _kGold, strokeWidth: 2))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tentName,
                style: const TextStyle(
                    fontSize: 13,
                    color: _kTextLight,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: _kHeroBg.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  const Text('How was your stay?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return IconButton(
                        onPressed: () => setState(() {
                          _rating = starIndex;
                          _error = null;
                        }),
                        icon: Icon(
                          starIndex <= _rating ? Icons.star : Icons.star_border,
                          color: _kGold,
                          size: 34,
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 4),
                    Text(_labels[_rating]!,
                        style: const TextStyle(
                            color: _kGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Your Comments (optional)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 5,
              style: const TextStyle(color: _kTextDark, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tell other guests what you liked or what we can improve…',
                hintStyle: const TextStyle(color: _kTextLight, fontSize: 13),
                filled: true,
                fillColor: _kCardBg,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kGold, width: 1.5),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _kError.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: _kError, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: _kError, fontSize: 13))),
                ]),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _kGold.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    )),
                child: _sending
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Review',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
