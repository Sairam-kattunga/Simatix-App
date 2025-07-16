import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'restaurant_review.dart';

class CanteenReviewsScreen extends StatefulWidget {
  @override
  _CanteenReviewsScreenState createState() => _CanteenReviewsScreenState();
}

class _CanteenReviewsScreenState extends State<CanteenReviewsScreen> {
  late Future<List<RestaurantReview>> _futureReviews;
  String _searchQuery = '';
  String _itemQuery = '';
  double _minRating = 1;

  final String formUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSd8XbWMYK-da5jTD4cPwUkXTV-wA0MqMCbqKuffGovG9NdtVA/viewform?usp=dialog';

  @override
  void initState() {
    super.initState();
    _futureReviews = ApiService.fetchReviews();
  }

  void _openGoogleForm() async {
    final uri = Uri.parse(formUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch form';
    }
  }

  String formattedDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (_) {
      return dateString;
    }
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(
        5,
            (i) => Icon(
          i < rating ? Icons.star : Icons.star_border_outlined,
          size: 20,
          color: Colors.amber.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF2F6F9);
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Canteen Reviews",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 3,
        shadowColor: primaryColor.withOpacity(0.6),
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Search and Filters...
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                prefixIcon: Icon(Icons.search, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.white,
              ),
              onChanged: (query) {
                setState(() => _searchQuery = query.toLowerCase());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search food items...',
                    prefixIcon: Icon(Icons.fastfood, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    hintStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.white,
                  ),
                  onChanged: (query) {
                    setState(() => _itemQuery = query.toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Min Rating:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Slider(
                        value: _minRating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _minRating.toStringAsFixed(0),
                        activeColor: primaryColor,
                        inactiveColor: primaryColor.withOpacity(0.3),
                        onChanged: (value) {
                          setState(() => _minRating = value);
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _minRating.toStringAsFixed(0),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: FutureBuilder<List<RestaurantReview>>(
              future: _futureReviews,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading data:\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent.shade400),
                    ),
                  );
                }

                final reviews = snapshot.data ?? [];

                final uniqueRestaurants = reviews
                    .map((e) => e.restaurant)
                    .toSet()
                    .where((name) => name.toLowerCase().contains(_searchQuery))
                    .toList()
                  ..sort();

                if (uniqueRestaurants.isEmpty) {
                  return Center(
                    child: Text(
                      "No restaurants found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: uniqueRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = uniqueRestaurants[index];

                    final filteredReviews = reviews.where((r) {
                      final matchesItem = r.item.toLowerCase().contains(_itemQuery);
                      final meetsRating = r.rating >= _minRating;
                      return r.restaurant == restaurant && matchesItem && meetsRating;
                    }).toList();

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor: primaryColor.withOpacity(0.4),
                        color: cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (filteredReviews.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    "No reviews matching filters",
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ...filteredReviews.map((r) => Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: isDark ? Colors.grey[850] : Colors.grey[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.item,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 17,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          _buildRatingStars(r.rating),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        r.review,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 15,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          formattedDate(r.date),
                                          style: TextStyle(
                                            color: isDark ? Colors.white54 : Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          const SizedBox(width: 12),
          FloatingActionButton.extended(
            backgroundColor: primaryColor,
            onPressed: _openGoogleForm,
            icon: Icon(Icons.add, color: textColor),
            label: Text("Add Review", style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }
}
