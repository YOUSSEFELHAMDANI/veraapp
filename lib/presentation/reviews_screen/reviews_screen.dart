import '../../core/app_export.dart';
import '../../services/vera_api_service.dart';

class ReviewsScreen extends StatefulWidget {
  final String? serviceName;
  final String? serviceType;

  const ReviewsScreen({this.serviceName, this.serviceType, super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final String _sortBy = 'Most Recent';
  int _filterRating = 0;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await VeraApiService.instance.fetchReviews(
        targetId: widget.serviceName ?? '',
        targetType: widget.serviceType ?? 'service',
      );
      if (!mounted) return;
      setState(() {
        _reviews = reviews.map(_reviewToMap).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _reviewToMap(VeraReview r) {
    return {
      'name': r.authorName,
      'avatar': r.authorAvatar,
      'rating': r.rating.round(),
      'date': r.createdAt,
      'text': r.comment,
      'helpful': 0,
      'images': const <String>[],
    };
  }

  List<Map<String, dynamic>> get _filteredReviews {
    var list = _filterRating == 0
        ? _reviews
        : _reviews.where((r) => r['rating'] == _filterRating).toList();
    if (_sortBy == 'Most Helpful') {
      list = [...list]
        ..sort((a, b) => (b['helpful'] as int).compareTo(a['helpful'] as int));
    }
    return list;
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0.0, (sum, r) => sum + (r['rating'] as int)) /
        _reviews.length;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: AppTheme.grayText,
            ),
            const SizedBox(height: 12),
            Text(
              'No reviews yet',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to share your experience.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppTheme.grayText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.ivoryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppTheme.charcoal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reviews',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        if (widget.serviceName != null)
                          Text(
                            widget.serviceName!,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppTheme.grayText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPinkLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: AppTheme.primaryPinkDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Write',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryPinkDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reviews.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                          children: [
                            // Rating summary
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.borderLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        _avgRating.toStringAsFixed(1),
                                        style: GoogleFonts.cairo(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.charcoal,
                                          height: 1,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < _avgRating.round()
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            size: 16,
                                            color: AppTheme.goldAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_reviews.length} reviews',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: AppTheme.grayText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      children: [5, 4, 3, 2, 1]
                                          .where(
                                            (star) => _reviews.any(
                                              (r) => r['rating'] == star,
                                            ),
                                          )
                                          .map((star) {
                                        final count = _reviews
                                            .where((r) => r['rating'] == star)
                                            .length;
                                        final pct = _reviews.isEmpty
                                            ? 0.0
                                            : count / _reviews.length;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                '$star',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12,
                                                  color: AppTheme.grayText,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 12,
                                                color: AppTheme.goldAccent,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: pct,
                                                    backgroundColor:
                                                        AppTheme.borderLight,
                                                    valueColor:
                                                        const AlwaysStoppedAnimation(
                                                      AppTheme.goldAccent,
                                                    ),
                                                    minHeight: 6,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '$count',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12,
                                                  color: AppTheme.grayText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Sort & filter
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [0, 5, 4, 3, 2, 1].map((r) {
                                        final isActive = _filterRating == r;
                                        return GestureDetector(
                                          onTap: () => setState(
                                            () => _filterRating = r,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? AppTheme.primaryPink
                                                  : AppTheme.surfaceLight,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isActive
                                                    ? AppTheme.primaryPink
                                                    : AppTheme.borderLight,
                                              ),
                                            ),
                                            child: r == 0
                                                ? Text(
                                                    'All',
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 12,
                                                      fontWeight: isActive
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                      color: isActive
                                                          ? Colors.white
                                                          : AppTheme.charcoal,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.star_rounded,
                                                        size: 12,
                                                        color: isActive
                                                            ? Colors.white
                                                            : AppTheme.goldAccent,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '$r',
                                                        style: GoogleFonts.cairo(
                                                          fontSize: 12,
                                                          fontWeight: isActive
                                                              ? FontWeight.w600
                                                              : FontWeight.w400,
                                                          color: isActive
                                                              ? Colors.white
                                                              : AppTheme.charcoal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Review cards
                            if (_filteredReviews.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    'No reviews match this filter.',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: AppTheme.grayText,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._filteredReviews.map(
                                (r) => _ReviewCard(review: r),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _markedHelpful = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final images = r['images'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: CustomImageWidget(
                  imageUrl: r['avatar'] as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  semanticLabel: '${r['name']} profile photo',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['name'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    Text(
                      r['date'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < (r['rating'] as int)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: AppTheme.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            r['text'] as String,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppTheme.charcoal,
              height: 1.5,
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: images[i] as String,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    semanticLabel: 'Review photo ${i + 1}',
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _markedHelpful = !_markedHelpful),
                child: Row(
                  children: [
                    Icon(
                      _markedHelpful
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 14,
                      color: _markedHelpful
                          ? AppTheme.primaryPinkDark
                          : AppTheme.grayText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${(r['helpful'] as int) + (_markedHelpful ? 1 : 0)})',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: _markedHelpful
                            ? AppTheme.primaryPinkDark
                            : AppTheme.grayText,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Report',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppTheme.grayText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
