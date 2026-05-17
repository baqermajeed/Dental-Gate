class HomeSliderItem {
  HomeSliderItem({
    required this.id,
    required this.jobId,
    required this.imageUrl,
  });

  final String id;
  final String jobId;
  final String imageUrl;

  factory HomeSliderItem.fromJson(Map<String, dynamic> j) {
    return HomeSliderItem(
      id: j['id'] as String? ?? '',
      jobId: j['job_id'] as String? ?? '',
      imageUrl: j['image_url'] as String? ?? '',
    );
  }
}
