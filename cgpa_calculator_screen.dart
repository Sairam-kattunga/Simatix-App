import 'package:flutter/material.dart';

class CGPACalculatorScreen extends StatefulWidget {
  @override
  _CGPACalculatorScreenState createState() => _CGPACalculatorScreenState();
}

class _CGPACalculatorScreenState extends State<CGPACalculatorScreen> {
  final TextEditingController sGradeController = TextEditingController();
  final TextEditingController aGradeController = TextEditingController();
  final TextEditingController bGradeController = TextEditingController();
  final TextEditingController cGradeController = TextEditingController();
  final TextEditingController dGradeController = TextEditingController();
  final TextEditingController eGradeController = TextEditingController();

  double cgpa = 0.0;

  void calculateCGPA() {
    int s = int.tryParse(sGradeController.text) ?? 0;
    int a = int.tryParse(aGradeController.text) ?? 0;
    int b = int.tryParse(bGradeController.text) ?? 0;
    int c = int.tryParse(cGradeController.text) ?? 0;
    int d = int.tryParse(dGradeController.text) ?? 0;
    int e = int.tryParse(eGradeController.text) ?? 0;

    final totalPoints = (s * 10) + (a * 9) + (b * 8) + (c * 7) + (d * 6) + (e * 5);
    final totalSubjects = s + a + b + c + d + e;

    setState(() {
      cgpa = totalSubjects > 0 ? totalPoints / totalSubjects : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    final inputFields = [
      _buildGradeInputField('S Grade (10 points)', sGradeController, context),
      _buildGradeInputField('A Grade (9 points)', aGradeController, context),
      _buildGradeInputField('B Grade (8 points)', bGradeController, context),
      _buildGradeInputField('C Grade (7 points)', cGradeController, context),
      _buildGradeInputField('D Grade (6 points)', dGradeController, context),
      _buildGradeInputField('E Grade (5 points)', eGradeController, context),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Enter the number of subjects for each grade',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ...inputFields,
                    const SizedBox(height: 25),
                    ElevatedButton.icon(
                      onPressed: calculateCGPA,
                      icon: const Icon(Icons.calculate),
                      label: const Text(
                        'Calculate CGPA',
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
            if (cgpa > 0)
              Card(
                color:
                isDark ? Colors.grey[800] : primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Your CGPA is:',
                        style: TextStyle(fontSize: 18, color: primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cgpa.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
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

  Widget _buildGradeInputField(
      String label, TextEditingController controller, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
          prefixIcon: const Icon(Icons.school),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
