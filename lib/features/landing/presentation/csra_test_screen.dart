import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CSRATestScreen extends StatefulWidget {
  const CSRATestScreen({super.key});
  @override
  State<CSRATestScreen> createState() => _CSRATestScreenState();
}

class _CSRATestScreenState extends State<CSRATestScreen> {
  // Your functions deployed to us-central1 (see deploy log)
  final funcs = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<void> _show(String title, Object data) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text('$data')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _testTimetable() async {
    final r = await funcs.httpsCallable('timetableByPersonnel').call({
      'personName': 'Dr. Smith',
      'dayOfWeek': 'Tuesday',
    });
    await _show('Timetable', r.data);
  }

  Future<void> _testChart() async {
    final r = await funcs.httpsCallable('getChartData').call({
      'metric': 'Room Utilization (%)',
      'groupBy': 'dayOfWeek',
      'type': 'bar',
    });
    await _show('Chart', r.data);
  }

  Future<void> _testEmailDraft() async {
    final r = await funcs.httpsCallable('emailDraftFromTemplate').call({
      'courseName': 'Physics 101',
      'template': 'Timetable Update',
      'vars': {
        'newTime': '11:00',
        'newRoom': 'B-204',
        'audience': 'Students',
        'senderName': 'Admin',
        'date': '2025-11-08',
      },
    });
    await _show('Email Draft', r.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSRA Function Tester')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Btn('Test Timetable (FR1.1/1.3)', _testTimetable),
            const SizedBox(height: 12),
            _Btn('Test Chart (FR2.1/2.2)', _testChart),
            const SizedBox(height: 12),
            _Btn('Test Email Draft (FR3.1–3.4)', _testEmailDraft),
            const Spacer(),
            const Text('If you see JSON dialogs, your backend is working.'),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Future<void> Function() onTap;
  const _Btn(this.label, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onTap, child: Text(label)),
    );
  }
}
