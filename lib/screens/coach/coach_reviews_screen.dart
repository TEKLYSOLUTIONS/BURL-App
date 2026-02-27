import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/palette.dart';
import '../../services/review_service.dart';
import '../../utils/date_time_utils.dart';

class CoachReviewsScreen extends StatefulWidget {
  const CoachReviewsScreen({super.key});

  @override
  State<CoachReviewsScreen> createState() => _CoachReviewsScreenState();
}

class _CoachReviewsScreenState extends State<CoachReviewsScreen> {
  bool _isLoading = true;
  List<dynamic> _reviews = [];
  double _avgRating = 0.0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final data = await ReviewService.getMyCoachReviews();
      if (mounted) {
        final reviewList = (data['data'] as List<dynamic>?) ?? [];
        double total = 0;
        for (final r in reviewList) {
          total += _toDouble(r['rating']);
        }
        setState(() {
          _reviews = reviewList;
          _totalCount = reviewList.length;
          _avgRating = reviewList.isNotEmpty ? total / reviewList.length : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppPalette.navyPrimary,
                  AppPalette.navyPrimary.withValues(alpha: 0.85)
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        Text(
                          'My Reviews',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  // ── Summary block ────────────────────────────────────────
                  if (!_isLoading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                _avgRating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: List.generate(5, (i) {
                                  final filled = i < _avgRating.floor();
                                  final half = !filled && i < _avgRating;
                                  return Icon(
                                    half
                                        ? Icons.star_half_rounded
                                        : Icons.star_rounded,
                                    color: filled || half
                                        ? Colors.amber
                                        : Colors.white30,
                                    size: 20,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_totalCount ${_totalCount == 1 ? 'review' : 'reviews'}',
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 40),
                          Expanded(child: _buildRatingBars()),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // ── Review list ──────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _buildReviewCard(context, _reviews[i])
                                .animate()
                                .fadeIn(delay: (50 * i).ms)
                                .slideY(begin: 0.05),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBars() {
    final counts = List.filled(5, 0);
    for (final r in _reviews) {
      final val = _toDouble(r['rating']).round().clamp(1, 5);
      counts[val - 1]++;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final idx = 4 - i;
        final fraction = _totalCount > 0 ? counts[idx] / _totalCount : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text('${idx + 1}',
                  style:
                      GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 11),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    color: Colors.amber,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('${counts[idx]}',
                  style:
                      GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReviewCard(BuildContext context, dynamic review) {
    final Map<String, dynamic> r = Map<String, dynamic>.from(review as Map);
    final reviewer = r['user'] as Map<String, dynamic>? ??
        r['reviewer'] as Map<String, dynamic>?;
    final String reviewerName =
        reviewer?['fullName']?.toString() ?? 'Anonymous';
    final String? reviewerPhoto = reviewer?['profileUrl']?.toString() ??
        reviewer?['profilePhoto']?.toString();
    final double rating = _toDouble(r['rating']);
    final String comment = r['comment']?.toString() ?? '';
    final String sessionTitle =
        (r['session'] as Map<String, dynamic>?)?['title']?.toString() ??
            'Session';
    final String dateStr =
        r['createdAt']?.toString() ?? r['date']?.toString() ?? '';
    final String formattedDate = dateStr.isNotEmpty
        ? DateTimeUtils.formatDate(DateTime.tryParse(dateStr) ?? DateTime.now())
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppPalette.navyPrimary.withValues(alpha: 0.1),
                backgroundImage:
                    (reviewerPhoto != null && reviewerPhoto.isNotEmpty)
                        ? NetworkImage(reviewerPhoto)
                        : null,
                child: (reviewerPhoto == null || reviewerPhoto.isEmpty)
                    ? Text(
                        reviewerName.isNotEmpty
                            ? reviewerName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppPalette.navyPrimary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reviewerName,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface)),
                    Row(
                      children: [
                        Text(sessionTitle,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5))),
                        if (formattedDate.isNotEmpty) ...[
                          Text('  •  ',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3))),
                          Text(formattedDate,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Star rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded,
                      color: AppPalette.orangeAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      comment,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.75),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reviews from guardians and players\nwill appear here after sessions.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
