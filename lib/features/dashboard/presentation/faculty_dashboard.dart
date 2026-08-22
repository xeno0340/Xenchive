// lib/features/dashboard/presentation/faculty_dashboard.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  int _tab = 0;
  bool _notifEnabled = true;

  // ---------- MOCK DATA ----------
  // Records
  final _rollCtrl = TextEditingController();
  final _marksCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String _recType = 'Class Test';
  final List<_Attachment> _attachments = [];

  // Issuance / Event verification
  final List<_Participant> _pendingParticipants = [
    _Participant(
      name: 'Aditi Verma',
      roll: '22CS102',
      event: 'DevFest Campus',
      score: 86,
    ),
    _Participant(
      name: 'Rohan Mehta',
      roll: '22CS119',
      event: 'UX Sprint',
      score: 74,
    ),
    _Participant(
      name: 'Samiksha P',
      roll: '22CS131',
      event: 'AWS DeepRacer',
      score: 91,
    ),
  ];
  final List<_Participant> _approved = [];

  // Mentor
  final List<_Mentee> _mentees = [
    _Mentee(
      name: 'Nihal S',
      roll: '22CS077',
      lastAction: 'Uploaded Portfolio',
      risk: 0.20,
    ),
    _Mentee(
      name: 'Juhi N',
      roll: '22CS044',
      lastAction: 'Event: UX Sprint',
      risk: 0.10,
    ),
    _Mentee(
      name: 'Varun R',
      roll: '22CS143',
      lastAction: 'Pending Verification',
      risk: 0.55,
    ),
    _Mentee(
      name: 'Aisha K',
      roll: '22CS058',
      lastAction: 'New Certificate Added',
      risk: 0.15,
    ),
  ];

  // Insights
  final List<String> _kpiLabels = const [
    'Class Test',
    'Assignments',
    'Projects',
    'Events',
    'Certificates',
  ];
  final List<double> _kpiValues = const [61, 67, 74, 5, 12];

  // Prevent back to keep session unless logout
  Future<bool> _onWillPop() async => false;

  @override
  void dispose() {
    _rollCtrl.dispose();
    _marksCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _RecordsTab(
        rollCtrl: _rollCtrl,
        marksCtrl: _marksCtrl,
        remarksCtrl: _remarksCtrl,
        recType: _recType,
        onChangeType: (v) => setState(() => _recType = v),
        attachments: _attachments,
        onAddAttachment: _addAttachment,
        onRemoveAttachment: (a) => setState(() => _attachments.remove(a)),
        onSave: _saveRecord,
      ),
      _IssuanceTab(
        pending: _pendingParticipants,
        approved: _approved,
        onApprove: _approveParticipant,
        onReject: _rejectParticipant,
      ),
      _MentorTab(
        mentees: _mentees,
        onAddNote: _addMentorNote,
        onNudge: _nudgeMentee,
      ),
      _InsightsTab(
        labels: _kpiLabels,
        values: _kpiValues,
        onApplyIssuance: _openApplyIssuance, // NEW
      ),
      _SettingsTab(
        notifEnabled: _notifEnabled,
        onToggleNotif: (v) => setState(() => _notifEnabled = v),
        onLogout: _logout,
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: const Text('Faculty Dashboard'),
          centerTitle: true,
          leading: const SizedBox.shrink(),
        ),
        body: Stack(
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: _GlowOrb(
                size: 300,
                color:
                    (isDark ? const Color(0xFF3F8CFF) : const Color(0xFFCBA135))
                        .withOpacity(0.18),
              ),
            ),
            Positioned(
              bottom: -160,
              left: -110,
              child: _GlowOrb(
                size: 360,
                color:
                    (isDark ? const Color(0xFFCBA135) : const Color(0xFF3F8CFF))
                        .withOpacity(0.16),
              ),
            ),
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: pages[_tab],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              label: 'Records',
            ),
            NavigationDestination(
              icon: Icon(Icons.workspace_premium_outlined),
              label: 'Issuance',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              label: 'Mentor',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Actions (mocked) ----------
  void _addAttachment() async {
    final file = await _promptAttachment(context);
    if (file == null) return;
    setState(() => _attachments.add(file));
  }

  Future<void> _saveRecord() async {
    if (_rollCtrl.text.trim().isEmpty || _marksCtrl.text.trim().isEmpty) {
      _snack('Please enter Roll No and Marks', error: true);
      return;
    }
    _snack('Record saved (mock) for ${_rollCtrl.text} • $_recType');
    _marksCtrl.clear();
    _remarksCtrl.clear();
    _attachments.clear();
  }

  void _approveParticipant(_Participant p) {
    setState(() {
      _pendingParticipants.remove(p);
      _approved.add(p.copyWith(approved: true));
    });
    _snack('Approved issuance for ${p.name}');
  }

  void _rejectParticipant(_Participant p) async {
    final yes = await _confirm(
      context,
      title: 'Reject Issuance',
      message: 'Reject certificate for ${p.name}?',
    );
    if (!yes) return;
    setState(() => _pendingParticipants.remove(p));
    _snack('Rejected issuance for ${p.name}');
  }

  void _addMentorNote(_Mentee m) async {
    final note = await _promptText(context, title: 'Add Mentor Note');
    if (note == null || note.trim().isEmpty) return;
    _snack('Note added for ${m.name} (mock)');
  }

  void _nudgeMentee(_Mentee m) => _snack('Nudge sent to ${m.name} (mock)');

  // NEW: open issuance application sheet (mock)
  void _openApplyIssuance() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ApplyIssuanceSheet(),
    );
  }

  Future<void> _logout() async {
    final yes = await _confirm(
      context,
      title: 'Logout',
      message: 'Do you want to sign out of XENCHIVE?',
    );
    if (!yes) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  void _snack(String msg, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? cs.error : cs.primary,
      ),
    );
  }
}

//
// ======================= RECORDS TAB =======================
//
class _RecordsTab extends StatelessWidget {
  final TextEditingController rollCtrl;
  final TextEditingController marksCtrl;
  final TextEditingController remarksCtrl;
  final String recType;
  final ValueChanged<String> onChangeType;
  final List<_Attachment> attachments;
  final VoidCallback onAddAttachment;
  final ValueChanged<_Attachment> onRemoveAttachment;
  final Future<void> Function() onSave;

  const _RecordsTab({
    required this.rollCtrl,
    required this.marksCtrl,
    required this.remarksCtrl,
    required this.recType,
    required this.onChangeType,
    required this.attachments,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload & Verify Student Records',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: rollCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Roll Number',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: recType,
                  items: const [
                    DropdownMenuItem(
                      value: 'Class Test',
                      child: Text('Class Test'),
                    ),
                    DropdownMenuItem(
                      value: 'Assignment',
                      child: Text('Assignment'),
                    ),
                    DropdownMenuItem(value: 'Project', child: Text('Project')),
                    DropdownMenuItem(value: 'Event', child: Text('Event')),
                  ],
                  onChanged: (v) => onChangeType(v ?? recType),
                  decoration: const InputDecoration(
                    labelText: 'Record Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks',
                    prefixIcon: Icon(Icons.score_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: remarksCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAddAttachment,
                        icon: const Icon(Icons.attachment_outlined),
                        label: const Text('Add Attachment (max 10 MB)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 56,
                        maxWidth: 80,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${attachments.fold<double>(0, (p, a) => p + a.sizeMB).toStringAsFixed(1)} MB',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color:
                                    (isDark ? Colors.white70 : Colors.black87)
                                        .withOpacity(.85),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (attachments.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: attachments
                        .map(
                          (a) => Chip(
                            label: Text(
                              '${a.name} • ${a.sizeMB.toStringAsFixed(1)} MB',
                            ),
                            onDeleted: () => onRemoveAttachment(a),
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Verify & Save (mock)'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Submissions (mock)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Roll')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Marks')),
                      DataColumn(label: Text('Remarks')),
                      DataColumn(label: Text('Files')),
                    ],
                    rows: const [
                      DataRow(
                        cells: [
                          DataCell(Text('22CS102')),
                          DataCell(Text('Assignment')),
                          DataCell(Text('18/20')),
                          DataCell(Text('Good structure')),
                          DataCell(Text('report.pdf')),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('22CS119')),
                          DataCell(Text('Class Test')),
                          DataCell(Text('15/20')),
                          DataCell(Text('Revise Unit-2')),
                          DataCell(Text('photo.jpg')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//
// ======================= ISSUANCE TAB =======================
//
class _IssuanceTab extends StatelessWidget {
  final List<_Participant> pending;
  final List<_Participant> approved;
  final void Function(_Participant) onApprove;
  final void Function(_Participant) onReject;

  const _IssuanceTab({
    required this.pending,
    required this.approved,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text(
          'Verify Event Participants',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...pending.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GlassCard(
              child: ListTile(
                leading: CircleAvatar(child: Text(p.name.characters.first)),
                title: Text('${p.name} • ${p.roll}'),
                subtitle: Text('${p.event} • Score: ${p.score}'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Reject',
                      onPressed: () => onReject(p),
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                    ),
                    IconButton(
                      tooltip: 'Approve',
                      onPressed: () => onApprove(p),
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Recently Approved',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        ...approved.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GlassCard(
              child: ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text('${p.name} • ${p.roll}'),
                subtitle: const Text('Certificate Issuance Approved'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//
// ======================= MENTOR TAB =======================
//
class _MentorTab extends StatelessWidget {
  final List<_Mentee> mentees;
  final void Function(_Mentee) onAddNote;
  final void Function(_Mentee) onNudge;

  const _MentorTab({
    required this.mentees,
    required this.onAddNote,
    required this.onNudge,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text(
          'Mentee Activities',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...mentees.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GlassCard(
              child: ListTile(
                leading: _RiskRing(value: m.risk),
                title: Text('${m.name} • ${m.roll}'),
                subtitle: Text('Recent: ${m.lastAction}'),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    IconButton(
                      tooltip: 'Add Note',
                      onPressed: () => onAddNote(m),
                      icon: const Icon(Icons.note_add_outlined),
                    ),
                    IconButton(
                      tooltip: 'Nudge',
                      onPressed: () => onNudge(m),
                      icon: const Icon(Icons.send_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//
// ======================= INSIGHTS TAB (refined) =======================
//
class _InsightsTab extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final VoidCallback onApplyIssuance;

  const _InsightsTab({
    required this.labels,
    required this.values,
    required this.onApplyIssuance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avg = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length.toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.grade_outlined,
                title: 'Average',
                subtitle: 'Across CT/Assignment/Project',
                value: avg.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: _KpiCard(
                icon: Icons.people_outline,
                title: 'Mentees',
                subtitle: 'Assigned to you',
                value: '24',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Apply for Graduation Certificates (mock)
        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  child: const Icon(Icons.workspace_premium_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Graduation Certificates',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submit a request to issue graduation certificates for your batch. Attach CSV and specify program & year.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: onApplyIssuance,
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Apply for Issuance'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This Month', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _BarChart(labels: labels, values: values),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  const _KpiCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(subtitle, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  const _BarChart({required this.labels, required this.values});

  @override
  Widget build(BuildContext context) {
    final maxVal = values.fold<double>(0.0, (p, c) => math.max(p, c));
    return LayoutBuilder(
      builder: (ctx, c) {
        final barCount = values.length;
        final slot = c.maxWidth / barCount; // equal space for each bar+label
        final barWidth = slot * 0.5;

        return SizedBox(
          height: 220,
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size(c.maxWidth, 170),
                  painter: _BarsPainter(
                    values: values,
                    maxVal: maxVal <= 0 ? 1 : maxVal,
                    barWidth: barWidth,
                    slotWidth: slot,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final text in labels)
                    SizedBox(
                      width: slot,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            text,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<double> values;
  final double maxVal;
  final double barWidth;
  final double slotWidth;

  _BarsPainter({
    required this.values,
    required this.maxVal,
    required this.barWidth,
    required this.slotWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 30;

    final axis = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), axis);

    for (int i = 0; i < values.length; i++) {
      final left = i * slotWidth + (slotWidth - barWidth) / 2;
      final h = ((values[i] / maxVal) * (baseline - 10)).toDouble();

      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baseline - h, barWidth, h),
        const Radius.circular(10),
      );

      final paint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF3F8CFF), Color(0xFFCBA135)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rr.outerRect);

      canvas.drawRRect(rr, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.values != values ||
      old.maxVal != maxVal ||
      old.barWidth != barWidth ||
      old.slotWidth != slotWidth;
}

//
// ======================= SETTINGS TAB =======================
//
class _SettingsTab extends StatelessWidget {
  final bool notifEnabled;
  final ValueChanged<bool> onToggleNotif;
  final Future<void> Function() onLogout;

  const _SettingsTab({
    required this.notifEnabled,
    required this.onToggleNotif,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Faculty';
    final email = user?.email ?? 'faculty@xenchive.edu';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _GlassCard(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(name),
            subtitle: Text(email),
            trailing: TextButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
              onPressed: () => _editProfile(context, name, email),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: SwitchListTile(
            value: notifEnabled,
            onChanged: onToggleNotif,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Activity, approvals, mentee updates'),
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            subtitle: const Text(
              'You remain signed in unless you log out here',
            ),
            onTap: onLogout,
          ),
        ),
      ],
    );
  }

  void _editProfile(BuildContext context, String curName, String curEmail) {
    final nameCtrl = TextEditingController(text: curName);
    final emailCtrl = TextEditingController(text: curEmail);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved (mock)')),
                    );
                  },
                  child: const Text('Save (mock)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// ======================= SHARED WIDGETS / HELPERS =======================
//
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? Colors.white10 : Colors.white.withOpacity(0.86),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RiskRing extends StatelessWidget {
  final double value; // 0..1
  const _RiskRing({required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).clamp(0, 100).toStringAsFixed(0);
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(40),
            painter: _RingPainter(value),
          ),
          Text(pct, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final base = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF3F8CFF), Color(0xFFCBA135)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base);
    final sweep = (math.pi * 2) * value.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value;
}

// ---------- Models ----------
class _Attachment {
  final String name;
  final double sizeMB; // mock size
  _Attachment({required this.name, required this.sizeMB});
}

class _Participant {
  final String name;
  final String roll;
  final String event;
  final int score;
  final bool approved;
  _Participant({
    required this.name,
    required this.roll,
    required this.event,
    required this.score,
    this.approved = false,
  });

  _Participant copyWith({bool? approved}) => _Participant(
    name: name,
    roll: roll,
    event: event,
    score: score,
    approved: approved ?? this.approved,
  );
}

class _Mentee {
  final String name;
  final String roll;
  final String lastAction;
  final double risk;
  _Mentee({
    required this.name,
    required this.roll,
    required this.lastAction,
    required this.risk,
  });
}

// ---------- Small dialogs ----------
Future<_Attachment?> _promptAttachment(BuildContext context) async {
  final nameCtrl = TextEditingController(text: 'document.csv');
  final sizeCtrl = TextEditingController(text: '2.4');

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Add Attachment (mock)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'File Name'),
            controller: nameCtrl,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Size (MB, ≤ 10)'),
            controller: sizeCtrl,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Add'),
        ),
      ],
    ),
  );

  if (ok != true) return null;
  final name = nameCtrl.text.trim().isEmpty ? 'file.bin' : nameCtrl.text.trim();
  final size = double.tryParse(sizeCtrl.text.trim()) ?? 1.2;
  if (size <= 0 || size > 10) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Attachment must be 0–10 MB')));
    return null;
  }
  return _Attachment(name: name, sizeMB: size);
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
}) async {
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        maxLines: 4,
        decoration: const InputDecoration(hintText: 'Type here…'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  return ok == true ? ctrl.text : null;
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  return res ?? false;
}

//
// ============== APPLY FOR GRADUATION CERTIFICATES SHEET (mock) ==============
//
class _ApplyIssuanceSheet extends StatefulWidget {
  const _ApplyIssuanceSheet();

  @override
  State<_ApplyIssuanceSheet> createState() => _ApplyIssuanceSheetState();
}

class _ApplyIssuanceSheetState extends State<_ApplyIssuanceSheet> {
  final _form = GlobalKey<FormState>();
  final _programs = const ['B.Tech CSE', 'B.Tech ECE', 'BCA', 'MCA', 'MBA'];
  String _program = 'B.Tech CSE';
  String _batch = '2025';
  final _studentsCtrl = TextEditingController(text: '120');
  final _deadlineCtrl = TextEditingController(text: '2025-08-15');
  final _notesCtrl = TextEditingController();
  _Attachment? _csv;

  @override
  void dispose() {
    _studentsCtrl.dispose();
    _deadlineCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Apply for Graduation Certificates',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _program,
                items: _programs
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _program = v ?? _program),
                decoration: const InputDecoration(
                  labelText: 'Program',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _batch,
                items: ['2025', '2024', '2023', '2022']
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (v) => setState(() => _batch = v ?? _batch),
                decoration: const InputDecoration(
                  labelText: 'Batch Year',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _studentsCtrl,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                decoration: const InputDecoration(
                  labelText: 'No. of Students',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _deadlineCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expected Issue Date (YYYY-MM-DD)',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _notesCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final pick = await _promptAttachment(context);
                        if (pick == null) return;
                        if (!pick.name.toLowerCase().endsWith('.csv')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please attach a .csv file'),
                            ),
                          );
                          return;
                        }
                        setState(() => _csv = pick);
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        _csv == null
                            ? 'Attach CSV (≤10 MB)'
                            : 'Attached: ${_csv!.name} (${_csv!.sizeMB.toStringAsFixed(1)} MB)',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (!(_form.currentState?.validate() ?? false)) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Issuance request submitted (mock): $_program • $_batch • ${_studentsCtrl.text} students',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Submit Request (mock)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
