import 'package:flutter/material.dart';

class AttendanceCalculatorScreen extends StatefulWidget {
  const AttendanceCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceCalculatorScreen> createState() =>
      _AttendanceCalculatorScreenState();
}

class _AttendanceCalculatorScreenState
    extends State<AttendanceCalculatorScreen> {
  final _heldController = TextEditingController();
  final _attendedController = TextEditingController();

  double? _percentage;
  String _status = '';
  String _suggestion = '';

  void _calculate() {
    final held = int.tryParse(_heldController.text);
    final attended = int.tryParse(_attendedController.text);

    if (held == null || attended == null || held == 0 || attended > held) {
      setState(() {
        _status = 'Invalid input';
        _percentage = null;
        _suggestion = '';
      });
      return;
    }

    const thresholdPercent = 80.0;
    final percent = (attended / held) * 100;
    String status;
    String suggestion;

    if (percent >= thresholdPercent) {
      status = 'Safe';
      int maxSkips = ((attended / (thresholdPercent / 100)) - held).floor();
      suggestion = maxSkips > 0
          ? 'You can skip $maxSkips more classes. 😉'
          : 'You are right on the edge, no classes to skip! 👀';
    } else {
      status = 'Low Attendance';
      double t = thresholdPercent / 100;
      double rawX = (t * held - attended) / (1 - t);
      double x = double.parse(rawX.toStringAsFixed(8));
      int needed = x.ceil();
      suggestion = needed <= 0
          ? 'You are very close to $thresholdPercent%, just attend the next class! 👀'
          : 'You must attend next $needed classes to reach $thresholdPercent%.';
    }

    setState(() {
      _percentage = percent;
      _status = status;
      _suggestion = suggestion;
    });
  }

  @override
  void dispose() {
    _heldController.dispose();
    _attendedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Calculate your attendance status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                        'Total Classes Held', _heldController, Icons.event_note),
                    _buildInputField('Classes Attended', _attendedController,
                        Icons.check_circle),
                    const SizedBox(height: 25),
                    ElevatedButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(Icons.calculate),
                      label: const Text(
                        'Calculate',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_percentage != null)
              Card(
                color: isDark
                    ? surfaceColor.withOpacity(0.6)
                    : primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Attendance: ${_percentage!.toStringAsFixed(2)}%',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Status: $_status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _status == 'Safe' ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _suggestion,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
