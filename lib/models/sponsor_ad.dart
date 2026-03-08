class SponsorAd {
  final String id;
  final String title;
  final String sponsorName;
  final String image;
  final String link;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int clickCount;
  final int impressionCount;

  SponsorAd({
    required this.id,
    required this.title,
    required this.sponsorName,
    required this.image,
    required this.link,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.clickCount,
    required this.impressionCount,
  });

  factory SponsorAd.fromJson(Map<String, dynamic> json) {
    return SponsorAd(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      sponsorName: json['sponsorName'] ?? '',
      image: json['image'] ?? '',
      link: json['link'] ?? '',
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'] ?? 'pending',
      clickCount: json['clickCount'] ?? 0,
      impressionCount: json['impressionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sponsorName': sponsorName,
      'image': image,
      'link': link,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'clickCount': clickCount,
      'impressionCount': impressionCount,
    };
  }
}
