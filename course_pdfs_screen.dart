import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class CoursePDFsScreen extends StatefulWidget {
  const CoursePDFsScreen({super.key});

  @override
  State<CoursePDFsScreen> createState() => _CoursePDFsScreenState();
}

class _CoursePDFsScreenState extends State<CoursePDFsScreen> {
  List<dynamic> pdfList = [];
  List<dynamic> filteredList = [];
  bool isLoading = true;
  bool sortAscending = true;
  TextEditingController searchController = TextEditingController();

  Future<void> fetchPDFs() async {
    try {
      final response = await http.get(Uri.parse(
          "https://script.google.com/macros/s/AKfycby7nTuMpkyfgoCK9LDQDuDm8F7d4s31yPMrLzL4l0XDPwiUYI_L6lIYOXQduKPhedW9/exec"));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          pdfList = data;
          filteredList = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load PDFs");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred while fetching PDFs: $e")),
      );
    }
  }

  void searchPDFs(String query) {
    final results = pdfList.where((pdf) {
      final title = pdf['title'].toLowerCase();
      final subject = pdf['subject'].toLowerCase();
      return title.contains(query.toLowerCase()) ||
          subject.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredList = results;
    });
  }

  void sortPDFsByTitle() {
    setState(() {
      filteredList.sort((a, b) => sortAscending
          ? a['title'].toLowerCase().compareTo(b['title'].toLowerCase())
          : b['title'].toLowerCase().compareTo(a['title'].toLowerCase()));
      sortAscending = !sortAscending;
    });
  }

  void _launchGoogleForm() async {
    final url =
        'https://docs.google.com/forms/d/e/1FAIpQLScYc0ej4dtYQNcJZxbGNbGpzHuW79C9pXiARSxclYQB3PxQ-Q/viewform?usp=dialog';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Form")),
      );
    }
  }

  Future<void> downloadPDF(
      BuildContext context, String url, String filename) async {
    try {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }

      Directory dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      String filePath = '${dir.path}/$filename.pdf';
      Dio dio = Dio();

      double progress = 0.0;
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Downloading..."),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(value: progress),
                    Text("${(progress * 100).toStringAsFixed(0)}%"),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Please wait while the file is downloading."),
              ],
            ),
          ),
        ),
      );

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress = received / total;
            setState(() {});
          }
        },
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Download Complete"),
            content: Text("Your PDF has been downloaded to:\n$filePath"),
            actions: [
              TextButton(
                child: const Text("Open"),
                onPressed: () {
                  Navigator.of(context).pop();
                  OpenFile.open(filePath);
                },
              ),
              TextButton(
                child: const Text("Close"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download failed: $e")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPDFs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Course PDFs'),
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Add PDF',
                icon: Icon(Icons.upload_file_rounded, color: theme.colorScheme.onPrimary),
                onPressed: _launchGoogleForm,
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by title or subject',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    onChanged: searchPDFs,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: sortAscending ? "Sort A-Z" : "Sort Z-A",
                  icon: Icon(sortAscending
                      ? Icons.sort
                      : Icons.sort_sharp),
                  onPressed: sortPDFsByTitle,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? const Center(child: Text("No PDFs found."))
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filteredList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pdf = filteredList[index];
                return Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  color: theme.cardColor,
                  child: ListTile(
                    title: Text(
                      pdf['title'],
                      style: theme.textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      pdf['subject'],
                      style: theme.textTheme.bodySmall!
                          .copyWith(color: theme.hintColor),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Download',
                          icon: const Icon(Icons.download),
                          color: theme.colorScheme.primary,
                          onPressed: () => downloadPDF(
                              context, pdf['url'], pdf['title']),
                        ),
                        IconButton(
                          tooltip: 'View',
                          icon: const Icon(
                              Icons.picture_as_pdf_rounded),
                          color: Colors.redAccent,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PDFViewerScreen(
                                  title: pdf['title'],
                                  pdfUrl: pdf['url'],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String title;
  final String pdfUrl;

  const PDFViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
