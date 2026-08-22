// lib/features/dashboard/presentation/student_dashboard.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _tabIndex = 0;

  // ---- MOCK DATA ----
  // AI summary numbers
  double overallProgress = 0.72; // 72%
  int verifiedCerts = 8;
  int pendingReviews = 2;
  int eventsThisMonth = 5;

  // Recent verified achievements
  final List<_Achievement> _recent = [
    _Achievement(
      title: 'Google Cloud Fundamentals',
      issuer: 'Google',
      date: '12 Jun 2025',
      type: 'Course',
      verified: true,
    ),
    _Achievement(
      title: 'Flutter Forward Hackathon — 1st Place',
      issuer: 'MLH',
      date: '02 Jun 2025',
      type: 'Competition',
      verified: true,
    ),
    _Achievement(
      title: 'Web Accessibility Workshop',
      issuer: 'W3C Chapter',
      date: '28 May 2025',
      type: 'Workshop',
      verified: true,
    ),
  ];

  // Event discovery
  final List<_EventItem> _events = [
    _EventItem(
      title: 'DevFest Campus',
      org: 'GDG',
      when: '16–17 Jul',
      mode: 'Onsite',
      tag: 'Ongoing',
    ),
    _EventItem(
      title: 'AWS DeepRacer League',
      org: 'AWS',
      when: '21 Jul',
      mode: 'Online',
      tag: 'Upcoming',
    ),
    _EventItem(
      title: 'UX Sprint: Design for Students',
      org: 'Figma EDU',
      when: '25–26 Jul',
      mode: 'Hybrid',
      tag: 'Upcoming',
    ),
  ];

  // Photo overview (mock, lively feed)
  final List<String> _photoUrls = const [
    // safe, generic shots (replace with Firestore later)
    'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800',
    'https://images.unsplash.com/photo-1523580846011-d3a5bc25702b?w=800',
    'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800',
    'https://images.unsplash.com/photo-1555949963-aa79dcee981d?w=800',
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800',
  ];

  bool _notifEnabled = true;

  // Prevent back (Android system back or app bar back)
  Future<bool> _onWillPop() async => false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _OverviewTab(
        overallProgress: overallProgress,
        verifiedCerts: verifiedCerts,
        pendingReviews: pendingReviews,
        eventsThisMonth: eventsThisMonth,
        recent: _recent,
        photoUrls: _photoUrls,
        onOpenAchievement: _openAchievement,
      ),
      _AchievementsTab(recent: _recent, onOpenAchievement: _openAchievement),
      _EventsTab(items: _events, onOpenEvent: _openEvent),
      _SupportTab(onRaiseTicket: _raiseTicket),
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
          title: const Text('Student Dashboard'),
          centerTitle: true,
          leading: const SizedBox.shrink(), // no back
        ),
        body: Stack(
          children: [
            // Ambient glow
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

        // ★ Sleek floating glass bottom bar
        bottomNavigationBar: _XenBottomNav(
          index: _tabIndex,
          onSelect: (i) => setState(() => _tabIndex = i),
        ),
      ),
    );
  }

  // ---- Actions ----
  void _openAchievement(_Achievement a) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CertificatePreview(a: a),
            const SizedBox(height: 12),
            Text(
              'This is a preview. Real files and verification stamps will appear here after integration.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _openEvent(_EventItem e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(e.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Organizer', e.org),
            _kv('Schedule', e.when),
            _kv('Mode', e.mode),
            _kv('Status', e.tag),
            const SizedBox(height: 8),
            const Text(
              'Details will appear here once integrated with Firestore.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registered (mock).')),
              );
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  void _raiseTicket() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _TicketSheet(),
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
    // Only way out is Settings → Logout
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }
}

//
// ------------------------ OVERVIEW TAB ------------------------
//

class _OverviewTab extends StatelessWidget {
  final double overallProgress;
  final int verifiedCerts;
  final int pendingReviews;
  final int eventsThisMonth;
  final List<_Achievement> recent;
  final List<String> photoUrls;
  final void Function(_Achievement) onOpenAchievement;

  const _OverviewTab({
    required this.overallProgress,
    required this.verifiedCerts,
    required this.pendingReviews,
    required this.eventsThisMonth,
    required this.recent,
    required this.photoUrls,
    required this.onOpenAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // AI Overview Card
        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ProgressRing(value: overallProgress, size: 90),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You’re on track. Keep a steady pace and aim for one achievement this week.',
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
                            icon: Icons.verified_outlined,
                            label: 'Verified',
                            value: '$verifiedCerts',
                          ),
                          _StatChip(
                            icon: Icons.pending_actions_outlined,
                            label: 'Pending',
                            value: '$pendingReviews',
                          ),
                          _StatChip(
                            icon: Icons.event_outlined,
                            label: 'Events',
                            value: '$eventsThisMonth',
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

        // “Today Highlights” Photos (lively overview)
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

        // “Path” Flow (mini flowchart vibe)
        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Best Steps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const _PathFlow(
                  steps: [
                    ('Complete Portfolio', 'Add 2 recent projects'),
                    ('Get Verified', 'Upload certificates for review'),
                    ('Apply to Events', 'Pick 1 event this week'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Recent Achievements
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recently Verified',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(onPressed: () {}, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _AchievementCard(
              a: recent[i],
              onTap: () => onOpenAchievement(recent[i]),
            ),
          ),
        ),
      ],
    );
  }
}

//
// ------------------------ ACHIEVEMENTS TAB ------------------------
//
class _AchievementsTab extends StatelessWidget {
  final List<_Achievement> recent;
  final void Function(_Achievement) onOpenAchievement;

  const _AchievementsTab({
    required this.recent,
    required this.onOpenAchievement,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: recent.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _GlassCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: CircleAvatar(
              radius: 22,
              child: Icon(
                recent[i].verified ? Icons.verified : Icons.pending_outlined,
              ),
            ),
            title: Text(recent[i].title),
            subtitle: Text('${recent[i].issuer} • ${recent[i].date}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenAchievement(recent[i]),
          ),
        ),
      ),
    );
  }
}

//
// ------------------------ EVENTS TAB ------------------------
//
class _EventsTab extends StatelessWidget {
  final List<_EventItem> items;
  final void Function(_EventItem) onOpenEvent;

  const _EventsTab({required this.items, required this.onOpenEvent});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _EventCard(item: items[i], onTap: () => onOpenEvent(items[i])),
      ),
    );
  }
}

//
// ------------------------ SUPPORT TAB ------------------------
//
class _SupportTab extends StatelessWidget {
  final VoidCallback onRaiseTicket;
  const _SupportTab({required this.onRaiseTicket});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        _GlassCard(
          child: ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Missing an achievement?'),
            subtitle: const Text(
              'Raise a support ticket to review and verify.',
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: onRaiseTicket,
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: ListTile(
            leading: const Icon(Icons.forum_outlined),
            title: const Text('General help & FAQs'),
            subtitle: const Text('Common questions and how-tos (mock).'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening FAQs (mock)…')),
              );
            },
          ),
        ),
      ],
    );
  }
}

//
// ------------------------ SETTINGS TAB ------------------------
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
    final name = user?.displayName ?? 'Student';
    final email = user?.email ?? 'student@xenchive.edu';

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
            subtitle: const Text(
              'Get updates about reviews, events and deadlines',
            ),
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
// ------------------------ SUPPORT: TICKET SHEET ------------------------
//
class _TicketSheet extends StatefulWidget {
  const _TicketSheet();

  @override
  State<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends State<_TicketSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();

  String _category = 'Missing certificate';

  // Attachment (mock): filename + sizeMB, up to 10MB
  String? _attName;
  double? _attSizeMB;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _addAttachmentDialog() {
    final nameCtrl = TextEditingController(text: _attName ?? '');
    final sizeCtrl = TextEditingController(
      text: _attSizeMB?.toStringAsFixed(2) ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add attachment (mock)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'File name',
                hintText: 'certificate.pdf',
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
                hintText: 'e.g., 2.5',
                prefixIcon: Icon(Icons.data_usage),
              ),
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Limit: 10 MB', style: TextStyle(fontSize: 12)),
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
                _attName = name;
                _attSizeMB = size;
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
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Raise Support Ticket',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(
                    value: 'Missing certificate',
                    child: Text('Missing certificate'),
                  ),
                  DropdownMenuItem(
                    value: 'Incorrect details',
                    child: Text('Incorrect details'),
                  ),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _title,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.short_text),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _desc,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Attachment row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilledButton.tonal(
                    onPressed: _addAttachmentDialog,
                    child: const Text('Add attachment (mock)'),
                  ),
                  const SizedBox(width: 8),
                  if (_attName != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          avatar: const Icon(Icons.attachment),
                          label: Text(
                            '${_attName!}  •  ${_attSizeMB?.toStringAsFixed(2)} MB',
                          ),
                          onDeleted: () => setState(() {
                            _attName = null;
                            _attSizeMB = null;
                          }),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_form.currentState?.validate() ?? false) {
                      if (_attSizeMB != null && _attSizeMB! > 10.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attachment too large (max 10 MB)'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _attName == null
                                ? 'Ticket submitted (mock).'
                                : 'Ticket submitted (mock) with "${_attName!}" (${_attSizeMB?.toStringAsFixed(2)} MB).',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ------------------------ CARDS & PREVIEWS ------------------------
//
class _AchievementCard extends StatelessWidget {
  final _Achievement a;
  final VoidCallback onTap;
  const _AchievementCard({required this.a, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 260,
      child: _GlassCard(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mock certificate thumb
                Container(
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF22304A), const Color(0xFF111822)]
                          : [const Color(0xFFEFF6FF), const Color(0xFFFDF7E7)],
                    ),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      size: 32,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  a.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${a.issuer} • ${a.date}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final _EventItem item;
  final VoidCallback onTap;
  const _EventCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chipColor = switch (item.tag) {
      'Ongoing' => Colors.green,
      'Upcoming' => Colors.orange,
      _ => Colors.grey,
    };
    return _GlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          child: Text(
            item.mode.isNotEmpty
                ? item.mode.substring(0, 1).toUpperCase()
                : '?',
          ),
        ),
        title: Text(item.title),
        subtitle: Text('${item.org} • ${item.when} • ${item.mode}'),
        trailing: Chip(
          label: Text(item.tag),
          backgroundColor: chipColor.withOpacity(0.15),
          labelStyle: TextStyle(color: chipColor),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _CertificatePreview extends StatelessWidget {
  final _Achievement a;
  const _CertificatePreview({required this.a});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _GlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 5 / 3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1B283D), const Color(0xFF0E1420)]
                    : [const Color(0xFFEEF5FF), const Color(0xFFFFF6E8)],
              ),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -18,
                  child: Icon(
                    Icons.workspace_premium,
                    size: 100,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(.15),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        a.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${a.issuer} • ${a.date}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Verified ✔',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
// ------------------------ LITTLE UI UTILITIES ------------------------
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

//
// ------------------------ MODELS ------------------------
//
class _Achievement {
  final String title;
  final String issuer;
  final String date;
  final String type;
  final bool verified;

  _Achievement({
    required this.title,
    required this.issuer,
    required this.date,
    required this.type,
    required this.verified,
  });
}

class _EventItem {
  final String title;
  final String org;
  final String when;
  final String mode; // Online | Onsite | Hybrid
  final String tag; // Ongoing | Upcoming

  _EventItem({
    required this.title,
    required this.org,
    required this.when,
    required this.mode,
    required this.tag,
  });
}

//
// ------------------------ SMALL HELPERS ------------------------
//
Widget _kv(String k, String v) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

// Simple confirm dialog helper (used by Settings → Logout)
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

//
// ------------------------ FLOATING GLASS BOTTOM NAV ------------------------
//
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
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: 'Overview',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.verified_outlined),
                    selectedIcon: Icon(Icons.verified),
                    label: 'Achievements',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.event_outlined),
                    selectedIcon: Icon(Icons.event),
                    label: 'Events',
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
