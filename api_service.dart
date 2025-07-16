import 'dart:convert';
import 'package:http/http.dart' as http;
import 'restaurant_review.dart';

class ApiService {
  static const String apiUrl = 'https://script.google.com/macros/s/AKfycbwPUcxwSPVWma6qe8YWjS7_OwO8t09Q6iTFpX4QCGsxrq3kIovsRzSz1OnSWiA6gE8Q/exec';

  static Future<List<RestaurantReview>> fetchReviews() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);

      return jsonData.map((item) => RestaurantReview.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }
}
