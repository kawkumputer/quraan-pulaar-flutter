
class VerseModel {
  final int number;
  final String arabic;
  final String pulaar;

  VerseModel({
    required this.number,
    required this.arabic,
    required this.pulaar,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    return VerseModel(
      number: json['number'],
      arabic: json['arabic'],
      pulaar: json['pulaar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'arabic': arabic,
      'pulaar': pulaar,
    };
  }
}
