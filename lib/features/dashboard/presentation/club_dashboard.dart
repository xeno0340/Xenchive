// lib/features/dashboard/presentation/club_dashboard.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClubDashboard extends StatefulWidget {
  const ClubDashboard({super.key});

  @override
  State<ClubDashboard> createState() => _ClubDashboardState();
}

class _ClubDashboardState extends State<ClubDashboard> {
  int _tabIndex = 0;

  // ---------- MOCK DATA ----------
  int eventsHosted = 12;
  int participantsThisMonth = 284;
  double avgSatisfaction = 4.4; // /5
  double clubHealth = 0.81; // 81%

  final List<_ClubEvent> _events = [
    _ClubEvent(
      id: 'e1',
      title: 'Flutter Bootcamp',
      date: '12 Jul 2025',
      status: 'Completed',
      participants: 120,
    ),
    _ClubEvent(
      id: 'e2',
      title: 'AI for Beginners',
      date: '03 Jul 2025',
      status: 'Completed',
      participants: 86,
    ),
    _ClubEvent(
      id: 'e3',
      title: 'Hack Night: Campus',
      date: '28 Jun 2025',
      status: 'Completed',
      participants: 152,
    ),
    _ClubEvent(
      id: 'e4',
      title: 'Design Sprint Workshop',
      date: '21 Jun 2025',
      status: 'Completed',
      participants: 74,
    ),
  ];

  // Event -> attachments (mock)
  final Map<String, List<_Attachment>> _uploads = {};

  // Photo highlights (lively mock)
  final List<String> _photoUrls = const [
    'https://images.unsplash.com/photo-1515165562835-c3b8c1ea5a9a?w=800',
    'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=800',
    'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2?w=800',
    'https://images.unsplash.com/photo-1519336555923-59663e0ac1ad?w=800',
  ];

  bool _notifEnabled = true;

  // Prevent back navigation (stay logged in unless Settings → Logout)
  Future<bool> _onWillPop() async => false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _OverviewTab(
        clubHealth: clubHealth,
        eventsHosted: eventsHosted,
        participantsThisMonth: participantsThisMonth,
        avgSatisfaction: avgSatisfaction,
        photoUrls: _photoUrls,
      ),
      _ManageEventsTab(
        events: _events,
        uploads: _uploads,
        onOpenUpload: _openUploadSheet,
      ),
      _InsightsTab(events: _events),
      _SupportTab(onContact: _contactSupport),
      _SettingsTab(
        notifEnabled: _notifEnabled,
        onToggleNotif: (v) => setState(() => _notifEnabled = v),
        onSaveProfile: _saveProfileMock,
        onLogout: _logout,
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        backgroundColor: isDark
            ? const Color(0xFF0A0F16)
            : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Club Lead Dashboard'),
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
                duration: const Duration(milliseconds: 250),
                child: pages[_tabIndex],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _XenBottomNav(
          index: _tabIndex,
          onSelect: (i) => setState(() => _tabIndex = i),
        ),
      ),
    );
  }

  // ---------- Actions ----------
  void _openUploadSheet(_ClubEvent event) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UploadSheet(
        event: event,
        existing: _uploads[event.id] ?? const [],
        onSave: (items) {
          setState(() => _uploads[event.id] = items);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saved ${items.length} attachment(s) for "${event.title}" (mock).',
              ),
            ),
          );
        },
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Contact Coordinator'),
        content: const Text(
          'Email sent to student-affairs@college.edu (mock).',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _saveProfileMock(String name, String email) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved (mock): $name • $email')));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }
}

//
// ------------------------ OVERVIEW ------------------------
//
class _OverviewTab extends StatelessWidget {
  final double clubHealth; // 0..1
  final int eventsHosted;
  final int participantsThisMonth;
  final double avgSatisfaction;
  final List<String> photoUrls;

  const _OverviewTab({
    required this.clubHealth,
    required this.eventsHosted,
    required this.participantsThisMonth,
    required this.avgSatisfaction,
    required this.photoUrls,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ProgressRing(value: clubHealth, size: 92),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Club Health',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Overall health is stable. Keep engagement high with a micro-event next week.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: (isDark ? Colors.white70 : Colors.black87)
                              .withOpacity(.85),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatChip(
                            icon: Icons.event_available_outlined,
                            label: 'Events',
                            value: '$eventsHosted',
                          ),
                          _StatChip(
                            icon: Icons.groups_2_outlined,
                            label: 'Participants',
                            value: '$participantsThisMonth',
                          ),
                          _StatChip(
                            icon: Icons.star_rate_rounded,
                            label: 'Rating',
                            value: avgSatisfaction.toStringAsFixed(1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today Highlights',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          photoUrls[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const Icon(Icons.photo_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _PathFlow(
                  steps: [
                    (
                      'Follow-up Survey',
                      'Close the post-event NPS for “Flutter Bootcamp”.',
                    ),
                    (
                      'Collab Request',
                      'Draft MoU with GDG Campus for DevFest.',
                    ),
                    (
                      'Mentor Roster',
                      'Confirm 3 mentors for “AI for Beginners”.',
                    ),
                  ],
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
// ------------------------ MANAGE EVENTS ------------------------
//
class _ManageEventsTab extends StatelessWidget {
  final List<_ClubEvent> events;
  final Map<String, List<_Attachment>> uploads;
  final void Function(_ClubEvent) onOpenUpload;

  const _ManageEventsTab({
    required this.events,
    required this.uploads,
    required this.onOpenUpload,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final e = events[i];
        final count = uploads[e.id]?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _GlassCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: CircleAvatar(
                child: Text(
                  e.title.isNotEmpty
                      ? e.title.substring(0, 1).toUpperCase()
                      : '?',
                ),
              ),
              title: Text(e.title),
              subtitle: Text(
                '${e.date} • ${e.status} • ${e.participants} participants',
              ),
              trailing: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (count > 0)
                    Chip(
                      label: Text('$count files'),
                      avatar: const Icon(Icons.attachment, size: 18),
                    ),
                  FilledButton.tonal(
                    onPressed: () => onOpenUpload(e),
                    child: const Text('Upload assets'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UploadSheet extends StatefulWidget {
  final _ClubEvent event;
  final List<_Attachment> existing;
  final void Function(List<_Attachment>) onSave;
  const _UploadSheet({
    required this.event,
    required this.existing,
    required this.onSave,
  });

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  // Local working copy
  late List<_Attachment> _items;

  @override
  void initState() {
    super.initState();
    _items = List<_Attachment>.from(widget.existing);
  }

  void _addItemDialog() {
    String type = 'Participants List';
    final nameCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add asset (mock)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: type,
              items: const [
                DropdownMenuItem(
                  value: 'Participants List',
                  child: Text('Participants List'),
                ),
                DropdownMenuItem(
                  value: 'Winners List',
                  child: Text('Winners List'),
                ),
                DropdownMenuItem(value: 'Photos', child: Text('Photos (.zip)')),
                DropdownMenuItem(
                  value: 'Certificates',
                  child: Text('Certificates (.zip / pdf)'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => type = v ?? type,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'File name',
                hintText: 'participants.xlsx / photos.zip / winners.pdf',
                prefixIcon: Icon(Icons.insert_drive_file_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: sizeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Approx. size (MB)',
                hintText: 'e.g., 3.8',
                prefixIcon: Icon(Icons.data_usage),
              ),
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Limit per file: 10 MB',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final size = double.tryParse(sizeCtrl.text.trim());
              final name = nameCtrl.text.trim();
              if (name.isEmpty || size == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter file and size')),
                );
                return;
              }
              if (size > 10.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Max size is 10 MB')),
                );
                return;
              }
              setState(() {
                _items.add(_Attachment(type: type, name: name, sizeMB: size));
              });
              Navigator.pop(context);
            },
            child: const Text('Attach'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload assets — ${widget.event.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _addItemDialog,
                    child: const Text('Add attachment'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('No files added yet.'),
              )
            else
              ..._items.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _GlassCard(
                    child: ListTile(
                      leading: const Icon(Icons.attachment),
                      title: Text(a.name),
                      subtitle: Text(
                        '${a.type}  •  ${a.sizeMB.toStringAsFixed(2)} MB',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _items.remove(a)),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => widget.onSave(_items),
                    child: const Text('Save (mock)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//
// ------------------------ INSIGHTS ------------------------
//
class _InsightsTab extends StatelessWidget {
  final List<_ClubEvent> events;
  const _InsightsTab({required this.events});

  @override
  Widget build(BuildContext context) {
    final values = events.map((e) => e.participants.toDouble()).toList();
    final labels = events.map((e) => e.title.split(' ').first).toList();

    final total = values.fold<double>(0, (a, b) => a + b);
    final maxVal = values.isEmpty ? 1 : values.reduce(math.max);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participants by Event',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: _BarChart(values: values, labels: labels),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _StatChip(
                      icon: Icons.groups,
                      label: 'Total',
                      value: total.toStringAsFixed(0),
                    ),
                    _StatChip(
                      icon: Icons.trending_up,
                      label: 'Max',
                      value: maxVal.toStringAsFixed(0),
                    ),
                    _StatChip(
                      icon: Icons.calculate_outlined,
                      label: 'Avg',
                      value: (values.isEmpty ? 0 : total / values.length)
                          .toStringAsFixed(0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Insight'),
            subtitle: const Text(
              'Workshops with hands-on labs drove 25–35% higher attendance than talks.',
            ),
          ),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  const _BarChart({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarPainter(
        values: values,
        labels: labels,
        textStyle: Theme.of(context).textTheme.bodySmall,
      ),
      size: Size.infinite,
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final TextStyle? textStyle;
  _BarPainter({
    required this.values,
    required this.labels,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double maxVal = values.reduce(math.max);
    final double barWidth = size.width / (values.length * 2);
    final paint = Paint()..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;

    // x-axis
    canvas.drawLine(
      Offset(0, size.height - 24),
      Offset(size.width, size.height - 24),
      axisPaint,
    );

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < values.length; i++) {
      // Force double
      final double x = ((i * 2 + 1) * barWidth).toDouble();
      final double h = (((values[i] / maxVal) * (size.height - 50)).clamp(
        0.0,
        size.height - 50,
      )).toDouble();

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - 24 - h, barWidth, h),
        const Radius.circular(8),
      );

      paint.shader = const LinearGradient(
        colors: [Color(0xFF3F8CFF), Color(0xFFCBA135)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);

      // label
      textPainter.text = TextSpan(text: labels[i], style: textStyle);
      textPainter.layout(minWidth: barWidth + 8.0, maxWidth: barWidth + 8.0);
      textPainter.paint(canvas, Offset(x - 4, size.height - 20));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.labels != labels ||
      oldDelegate.textStyle != textStyle;
}

//
// ------------------------ SUPPORT ------------------------
//
class _SupportTab extends StatelessWidget {
  final VoidCallback onContact;
  const _SupportTab({required this.onContact});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        _GlassCard(
          child: ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Need help with an event?'),
            subtitle: const Text(
              'Ping Student Affairs with event link & question.',
            ),
            trailing: FilledButton.tonal(
              onPressed: onContact,
              child: const Text('Contact'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Event Guidelines'),
            subtitle: const Text(
              'Budget caps, vendor policy, branding kit, safety checklist (mock).',
            ),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening guidelines (mock)…')),
            ),
          ),
        ),
      ],
    );
  }
}

//
// ------------------------ SETTINGS ------------------------
//
class _SettingsTab extends StatelessWidget {
  final bool notifEnabled;
  final ValueChanged<bool> onToggleNotif;
  final void Function(String name, String email) onSaveProfile;
  final Future<void> Function() onLogout;

  const _SettingsTab({
    required this.notifEnabled,
    required this.onToggleNotif,
    required this.onSaveProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Club Lead';
    final email = user?.email ?? 'clublead@xenchive.edu';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _GlassCard(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
            title: Text(name),
            subtitle: Text(email),
            trailing: TextButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
              onPressed: () => _showEditProfileSheet(context, name, email),
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
            subtitle: const Text('Event reminders, approvals and escalations'),
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
            onTap: () async {
              final yes = await _confirm(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout from XENCHIVE?',
              );
              if (yes) await onLogout();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    String curName,
    String curEmail,
  ) async {
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
                  labelText: 'Club Lead Name',
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
                    onSaveProfile(nameCtrl.text.trim(), emailCtrl.text.trim());
                    Navigator.pop(context);
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
// ------------------------ SHARED WIDGETS / UTILS ------------------------
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
            color: isDark ? Colors.white10 : Colors.white.withOpacity(0.8),
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

class _ProgressRing extends StatelessWidget {
  final double value; // 0..1
  final double size;
  const _ProgressRing({required this.value, this.size = 90});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).clamp(0, 100).toStringAsFixed(0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size.square(size), painter: _RingPainter(value)),
          Text(
            '$pct%',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
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
    final radius = size.width / 2 - 6;
    final base = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF3F8CFF), Color(0xFFCBA135)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
    );
  }
}

class _PathFlow extends StatelessWidget {
  final List<(String, String)> steps;
  const _PathFlow({required this.steps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Node
              Container(
                width: 26,
                alignment: Alignment.topCenter,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Content
              Expanded(
                child: _GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].$1, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(steps[i].$2, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (i != steps.length - 1)
            Row(
              children: [
                const SizedBox(width: 26),
                Container(
                  width: 2,
                  height: 16,
                  color: theme.dividerColor.withOpacity(.4),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

// Simple confirm dialog helper
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _XenBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const _XenBottomNav({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 66,
                backgroundColor: Colors.transparent,
                indicatorColor:
                    (isDark ? const Color(0xFFCBA135) : const Color(0xFF3F8CFF))
                        .withOpacity(0.18),
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final sel = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: sel ? 12 : 11,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final sel = states.contains(WidgetState.selected);
                  return IconThemeData(size: sel ? 24 : 22);
                }),
              ),
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: onSelect,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.health_and_safety_outlined),
                    selectedIcon: Icon(Icons.health_and_safety),
                    label: 'Overview',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.event_note_outlined),
                    selectedIcon: Icon(Icons.event_note),
                    label: 'Manage',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights),
                    label: 'Insights',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.support_agent_outlined),
                    selectedIcon: Icon(Icons.support_agent),
                    label: 'Support',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//
// ------------------------ MODELS ------------------------
//
class _ClubEvent {
  final String id;
  final String title;
  final String date;
  final String status;
  final int participants;
  _ClubEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.participants,
  });
}

class _Attachment {
  final String
  type; // Participants List | Winners List | Photos | Certificates | Other
  final String name;
  final double sizeMB;
  _Attachment({required this.type, required this.name, required this.sizeMB});
}
