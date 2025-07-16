import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'faculty_model.dart';

enum SortOption {
  nameAsc,
  nameDesc,
  departmentAsc,
  departmentDesc,
}

class FacultyDirectoryScreen extends StatefulWidget {
  const FacultyDirectoryScreen({Key? key}) : super(key: key);

  @override
  _FacultyDirectoryScreenState createState() => _FacultyDirectoryScreenState();
}

class _FacultyDirectoryScreenState extends State<FacultyDirectoryScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  SortOption _selectedSortOption = SortOption.nameAsc;

  List<Faculty> _facultyList = [];
  bool _isLoading = true;
  Timer? _debounce;

  Map<String, double> _userRatings = {};
  Map<String, double> _averageRatings = {}; // You may later compute actual averages

  late AnimationController _animationController;

  User? get user => FirebaseAuth.instance.currentUser;

  final firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchFacultyData();
    _loadUserRatings();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRatings() async {
    if (user == null) return;

    Map<String, double> userRatings = {};

    for (var faculty in _facultyList) {
      final doc = await firestore
          .collection('faculty_ratings')
          .doc(faculty.name)
          .collection('reviews')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['rating'] is num) {
          userRatings[faculty.name] = (data['rating'] as num).toDouble();
        }

      }
    }

    setState(() {
      _userRatings = userRatings;
    });
  }



  Future<void> _saveRating(String facultyName, double? rating) async {
    if (user == null) return;

    final docRef = firestore
        .collection('faculty_ratings')
        .doc(facultyName)
        .collection('reviews')
        .doc(user!.uid);

    try {
      if (rating == null) {
        await docRef.delete();
        _userRatings.remove(facultyName);
        _averageRatings.remove(facultyName);
      } else {
        await docRef.set({
          'rating': rating,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _userRatings[facultyName] = rating;
      }

      // After saving, fetch all ratings for this faculty to update average
      final querySnapshot = await firestore
          .collection('faculty_ratings')
          .doc(facultyName)
          .collection('reviews')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final ratings = querySnapshot.docs
            .map((doc) => (doc.data()['rating'] as num).toDouble())
            .toList();

        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        _averageRatings[facultyName] = avg;
      } else {
        _averageRatings.remove(facultyName);
      }
    } catch (e) {
      debugPrint('Error saving rating: $e');
    }

    setState(() {});
  }
  Future<void> _calculateAllAverageRatings() async {
    for (var faculty in _facultyList) {
      final querySnapshot = await firestore
          .collection('faculty_ratings')
          .doc(faculty.name)
          .collection('reviews')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final ratings = querySnapshot.docs
            .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0.0)
            .toList();

        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        _averageRatings[faculty.name] = avg;
      }
    }
    setState(() {});
  }

  Future<void> _fetchFacultyData() async {
    const url =
        'https://script.google.com/macros/s/AKfycbzkiXuZ5OuF8J82pDopYQyvYRDtXyGZRKDav8UuLbz24ITi23pM4XkGMtwY1U_RIkEy/exec';

    try {
      final response =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<Faculty> list =
        (jsonData as List).map((json) => Faculty.fromJson(json)).toList();

        setState(() {
          _facultyList = list;
          _isLoading = false;
        });
        await _calculateAllAverageRatings(); // <-- Add this
        await _loadUserRatings();
      } else {
        _showSnackBar('Failed to load faculty data (Status ${response.statusCode})');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Check your internet connection or try again later');
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanPhone(String input) =>
      input.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanedNumber = _cleanPhone(phoneNumber);
    if (cleanedNumber.length < 10) {
      _showSnackBar("Invalid phone number");
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleanedNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('Could not launch dialer');
    }
  }

  Future<void> _openWhatsAppChat(String phoneNumber) async {
    final cleanedNumber = _cleanPhone(phoneNumber);
    if (cleanedNumber.length < 10) {
      _showSnackBar("Invalid phone number");
      return;
    }
    final uri =
    Uri.parse("https://wa.me/$cleanedNumber?text=Hello%20Professor");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar("Could not open WhatsApp");
    }
  }

  void _showFacultyDetails(Faculty faculty) {
    double userRating = _userRatings[faculty.name] ?? 0.0;
    double averageRating = _averageRatings[faculty.name] ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  faculty.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${faculty.department} Department'),
                const SizedBox(height: 8),
                Text('Phone: ${faculty.phone}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Average Rating: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    ...List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        size: 24,
                        color: index < averageRating
                            ? Colors.orange
                            : Colors.grey.shade300,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(averageRating.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 24),
                StatefulBuilder(builder: (context, setModalState) {
                  return Row(
                    children: [
                      const Text('Your Rating: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      ...List.generate(5, (index) {
                        final isSelected = index < userRating;
                        return AnimatedScale(
                          scale: isSelected ? 1.3 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 32,
                            icon: Icon(
                              Icons.star,
                              color: isSelected
                                  ? Colors.amber
                                  : Colors.grey.shade400,
                            ),
                            onPressed: () {
                              double newRating = (index + 1).toDouble();
                              if (newRating == userRating) newRating = 0.0;
                              setModalState(() => userRating = newRating);
                              _saveRating(
                                  faculty.name, newRating == 0 ? null : newRating);
                            },
                          ),
                        );
                      }),
                    ],
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Faculty> get _filteredSortedList {
    final query = _searchQuery.toLowerCase().trim();

    var filtered = _facultyList.where((faculty) {
      return faculty.name.toLowerCase().contains(query) ||
          faculty.department.toLowerCase().contains(query) ||
          faculty.phone.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_selectedSortOption) {
        case SortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case SortOption.departmentAsc:
          return a.department.toLowerCase().compareTo(b.department.toLowerCase());
        case SortOption.departmentDesc:
          return b.department.toLowerCase().compareTo(a.department.toLowerCase());
      }
    });

    return filtered;
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        if (rating >= index + 1) {
          icon = Icons.star;
        } else if (rating >= index + 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }

        return Icon(
          icon,
          size: 16,
          color: Colors.orangeAccent,
        );
      }),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredList = _filteredSortedList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Directory'),
        centerTitle: true,

        actions: [
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'Add Faculty',
                  splashRadius: 24,
                  icon: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  onPressed: () async {
                    const url = 'https://docs.google.com/forms/d/e/1FAIpQLSfP7yEb9BQeXdEI-i0z8gBsOdDfTw5ru-iloKEh8s8buWKdqg/viewform?usp=dialog';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not open the link")),
                      );
                    }
                  },

                ),
              );
            },
          ),


          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Search and Sort Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, department, or phone',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey, width: 1.5),
                      ),
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 350), () {
                        setState(() => _searchQuery = value);
                      });
                    },
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Sort',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Material(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      child: InkWell(
                        onTap: () async {
                          final selected = await showDialog<SortOption>(
                            context: context,
                            builder: (context) {
                              return SimpleDialog(
                                title: const Text('Sort Faculty By'),
                                children: [
                                  RadioListTile<SortOption>(
                                    title: const Text('Name Ascending'),
                                    value: SortOption.nameAsc,
                                    groupValue: _selectedSortOption,
                                    onChanged: (value) => Navigator.pop(context, value),
                                  ),
                                  RadioListTile<SortOption>(
                                    title: const Text('Name Descending'),
                                    value: SortOption.nameDesc,
                                    groupValue: _selectedSortOption,
                                    onChanged: (value) => Navigator.pop(context, value),
                                  ),
                                  RadioListTile<SortOption>(
                                    title: const Text('Department Ascending'),
                                    value: SortOption.departmentAsc,
                                    groupValue: _selectedSortOption,
                                    onChanged: (value) => Navigator.pop(context, value),
                                  ),
                                  RadioListTile<SortOption>(
                                    title: const Text('Department Descending'),
                                    value: SortOption.departmentDesc,
                                    groupValue: _selectedSortOption,
                                    onChanged: (value) => Navigator.pop(context, value),
                                  ),
                                ],
                              );
                            },
                          );
                          if (selected != null && selected != _selectedSortOption) {
                            setState(() => _selectedSortOption = selected);
                          }
                        },
                        borderRadius: BorderRadius.circular(25),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.sort),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                  ? Center(
                child: Text(
                  'No faculty found matching your search.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final faculty = filteredList[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: GestureDetector(
                      onTapDown: (_) => _animationController.forward(),
                      onTapCancel: () => _animationController.reverse(),
                      onTapUp: (_) => _animationController.reverse(),
                      onTap: () => _showFacultyDetails(faculty),
                      child: ScaleTransition(
                        scale: Tween(begin: 1.0, end: 0.97).animate(
                          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          shadowColor: Colors.black26,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            title: Text(
                              faculty.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(faculty.department),
                                const SizedBox(height: 4),
                                Text(faculty.phone),
                                const SizedBox(height: 4),
                                _buildStars(_averageRatings[faculty.name] ?? 0.0),

                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Call ${faculty.name}',
                                  icon: const Icon(Icons.call),
                                  onPressed: () => _makePhoneCall(faculty.phone),
                                  color: theme.colorScheme.primary,
                                ),
                                IconButton(
                                  tooltip: 'WhatsApp ${faculty.name}',
                                  icon: const Icon(Icons.chat_bubble),
                                  onPressed: () => _openWhatsAppChat(faculty.phone),
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
