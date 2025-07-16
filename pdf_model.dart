class CoursePDF {
  final String title;
  final String subject;
  final String url;

  CoursePDF({
    required this.title,
    required this.subject,
    required this.url,
  });

  factory CoursePDF.fromJson(Map<String, dynamic> json) {
    return CoursePDF(
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subject': subject,
    'url': url,
  };
}
