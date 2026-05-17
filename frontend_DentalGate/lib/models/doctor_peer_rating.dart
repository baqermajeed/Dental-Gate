/// تقييم طبيب من زميل.
class DoctorPeerRatingItem {
  const DoctorPeerRatingItem({
    required this.id,
    required this.stars,
    required this.comment,
    required this.raterUserId,
    this.raterName,
    this.raterImageUrl,
    this.createdAt,
  });

  final String id;
  final int stars;
  final String comment;
  final String raterUserId;
  final String? raterName;
  final String? raterImageUrl;
  final String? createdAt;

  factory DoctorPeerRatingItem.fromJson(Map<String, dynamic> json) {
    final starsRaw = json['stars'];
    final stars = starsRaw is int
        ? starsRaw
        : (starsRaw is num ? starsRaw.round() : 0);
    return DoctorPeerRatingItem(
      id: '${json['id'] ?? ''}',
      stars: stars.clamp(1, 5),
      comment: json['comment'] as String? ?? '',
      raterUserId: '${json['rater_user_id'] ?? ''}',
      raterName: json['rater_name'] as String?,
      raterImageUrl: json['rater_image_url'] as String?,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class DoctorPeerRatingsPage {
  const DoctorPeerRatingsPage({
    required this.ratings,
    this.averageStars,
    required this.totalCount,
    required this.currentUserHasRated,
    this.currentUserRating,
    this.ratingsGivenCount = 0,
  });

  final List<DoctorPeerRatingItem> ratings;
  final double? averageStars;
  final int totalCount;
  final bool currentUserHasRated;
  final DoctorPeerRatingItem? currentUserRating;
  final int ratingsGivenCount;

  /// دمج تقييم جديد فوراً بعد الإرسال حتى يظهر قبل إعادة الجلب.
  DoctorPeerRatingsPage withAddedRating(DoctorPeerRatingItem item) {
    final existing = ratings.indexWhere((r) => r.id == item.id);
    final next = List<DoctorPeerRatingItem>.from(ratings);
    if (existing >= 0) {
      next[existing] = item;
    } else {
      next.insert(0, item);
    }
    final sum = next.fold<int>(0, (a, r) => a + r.stars);
    return DoctorPeerRatingsPage(
      ratings: next,
      averageStars: next.isEmpty ? null : sum / next.length,
      totalCount: next.length,
      currentUserHasRated: true,
      currentUserRating: item,
      ratingsGivenCount: ratingsGivenCount,
    );
  }

  factory DoctorPeerRatingsPage.fromJson(Map<String, dynamic> json) {
    final list = <DoctorPeerRatingItem>[];
    final raw = json['ratings'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(DoctorPeerRatingItem.fromJson(e));
        } else if (e is Map) {
          list.add(DoctorPeerRatingItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    DoctorPeerRatingItem? mine;
    final mineRaw = json['current_user_rating'];
    if (mineRaw is Map<String, dynamic>) {
      mine = DoctorPeerRatingItem.fromJson(mineRaw);
    } else if (mineRaw is Map) {
      mine = DoctorPeerRatingItem.fromJson(Map<String, dynamic>.from(mineRaw));
    }
    return DoctorPeerRatingsPage(
      ratings: list,
      averageStars: (json['average_stars'] as num?)?.toDouble(),
      totalCount: json['total_count'] as int? ?? list.length,
      currentUserHasRated: json['current_user_has_rated'] == true,
      currentUserRating: mine,
      ratingsGivenCount: json['ratings_given_count'] as int? ?? 0,
    );
  }
}
