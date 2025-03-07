class Hadith {
  final int id;
  final String url;

  Hadith({
    required this.id,
    required this.url,
  });

  String get title => 'Njangtuwol ${id.toString()}';

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as int? ?? 0,
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
    };
  }
}
