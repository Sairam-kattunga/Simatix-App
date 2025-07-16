class RestaurantReview {
  final String restaurant;
  final String item;
  final int rating;
  final String review;
  final String timeStamp;
  final String date;

  RestaurantReview({
    required this.restaurant,
    required this.item,
    required this.rating,
    required this.review,
    required this.timeStamp,
    required this.date,
  });

  factory RestaurantReview.fromJson(Map<String, dynamic> json) {
    int parsedRating = 0;
    if (json['  Rating  '] != null) {
      if (json['  Rating  '] is int) {
        parsedRating = json['  Rating  '];
      } else {
        parsedRating = int.tryParse(json['  Rating  '].toString()) ?? 0;
      }
    }

    return RestaurantReview(
      restaurant: (json['Restaurant '] ?? '').toString().trim(),
      item: (json['Item Name'] ?? '').toString().trim(),
      rating: parsedRating,
      review: (json['  Review  '] ?? '').toString().trim(),
      timeStamp: (json['Timestamp'] ?? '').toString().trim(),
      date: (json['Date'] ?? '').toString().split('T').first,
    );
  }
}
