import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_viewer_screen.dart';

class DepartmentSubjectsScreen extends StatefulWidget {
  const DepartmentSubjectsScreen({Key? key}) : super(key: key);

  @override
  State<DepartmentSubjectsScreen> createState() => _DepartmentSubjectsScreenState();
}

class _DepartmentSubjectsScreenState extends State<DepartmentSubjectsScreen> {
  final String grbAssetPath = 'assets/sample_pdfs/GRB_Reference_1.pdf';
  final String grbFileName = 'GRB_Reference_1.pdf';

  List<String> departments = [
    "Aeronautical Engineering",
    "Agricultural Engineering",
    "Artificial Intelligence & Data Science",
    "Artificial Intelligence & Machine Learning",
    "Automobile Engineering",
    "Bioinformatics",
    "Biomedical Engineering",
    "Biotechnology",
    "Chemical Engineering",
    "Civil Engineering",
    "Computer Science and Engineering",
    "Electrical and Electronics Engineering",
    "Electronics and Communication Engineering",
    "Electronics and Instrumentation Engineering",
    "Food Technology",
    "Information Technology",
    "Mechanical Engineering",
    "Mechatronics Engineering",
    "Nanotechnology",
    "Robotics and Automation",
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700;
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF2F6F9);
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black87;
    final appBarTextColor = isDark ? Colors.black : Colors.white;

    final filteredDepartments = departments
        .where((dept) => dept.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Departments & Curriculum', style: TextStyle(color: appBarTextColor)),
        iconTheme: IconThemeData(color: appBarTextColor),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 4,
      ),
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Text(
                      'GRB Reference Book',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '2020 Batch - PDF from assets',
                      style: TextStyle(color: hintColor),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('View'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: appBarTextColor,
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: _openPdfViewer,
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: appBarTextColor,
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: _downloadAndOpenPdf,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search departments...',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.white,
              ),
              style: TextStyle(color: textColor),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredDepartments.isEmpty
                  ? Center(
                child: Text(
                  'No departments found!',
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              )
                  : ListView.builder(
                itemCount: filteredDepartments.length,
                itemBuilder: (context, index) {
                  final department = filteredDepartments[index];
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: const Icon(Icons.school, color: Colors.white),
                      ),
                      title: Text(department,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                      trailing: Icon(Icons.info_outline_rounded, color: textColor),
                      onTap: () => _showStillCookingDialog(department),
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

  void _openPdfViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          title: 'GRB Reference Book',
          assetPath: grbAssetPath,
        ),
      ),
    );
  }

  Future<void> _downloadAndOpenPdf() async {
    try {
      final bytes = await rootBundle.load(grbAssetPath);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$grbFileName');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      final result = await OpenFile.open(file.path);
      print('Open result: ${result.type}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  void _showStillCookingDialog(String department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Hold your horses! 🐴', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          '$department curriculum is still cooking in our app kitchen! 🍳\nStay tuned for the next release 😎',
          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            child: const Text('Okay, cool!'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
