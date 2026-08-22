// lib/features/dashboard/presentation/admin_dashboard.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;
  bool _notifEnabled = true;

  // -------- MOCK DATA --------
  // Overview KPIs
  int _students = 1240;
  int _faculty = 86;
  int _clubs = 18;
  int _pending = 39;

  // Final approvals
  final List<_ApprovalItem> _toApprove = [
    _ApprovalItem(
      kind: 'Certificate',
      title: 'DevFest Campus – Winner',
      user: '22CS102 • Aditi V',
      meta: 'Event • GDG',
      evidence: 'devfest_winner.pdf',
    ),
    _ApprovalItem(
      kind: 'Certificate',
      title: 'AWS DeepRacer – Finalist',
      user: '22CS131 • Samiksha P',
      meta: 'Event • AWS',
      evidence: 'deepracer.csv',
    ),
    _ApprovalItem(
      kind: 'Event',
      title: 'UX Sprint (Figma EDU)',
      user: 'Club: Design Circle',
      meta: 'Date: 25–26 Jul',
      evidence: 'poster.png',
    ),
    _ApprovalItem(
      kind: 'Account',
      title: 'New Faculty Account',
      user: 'rahul.sharma@inst.edu',
      meta: 'Role: Faculty',
      evidence: 'idcard.jpg',
    ),
  ];
  final List<_ApprovalItem> _approved = [];

  // Users
  final List<_UserRow> _users = List.generate(
    20,
    (i) => _UserRow(
      name: 'User $i',
      email: 'user$i@inst.edu',
      role: i % 7 == 0 ? 'Admin' : (i % 2 == 0 ? 'Faculty' : 'Student'),
      status: 'Active',
    ),
  );
  String _userQuery = '';

  // Analytics
  final List<double> _weekActivity = const [120, 160, 210, 180, 260, 220, 140];
  final List<String> _weekLabels = const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  Future<bool> _onWillPop() async => false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _OverviewTab(
        students: _students,
        faculty: _faculty,
        clubs: _clubs,
        pending: _pending,
        onBroadcast: _openBroadcast,
        weekLabels: _weekLabels,
        weekValues: _weekActivity,
      ),
      _ApprovalsTab(
        queue: _toApprove,
        approved: _approved,
        onApprove: (it) {
          setState(() {
            _toApprove.remove(it);
            _approved.add(it.copyWith(status: 'Approved'));
            _pending = (_pending - 1).clamp(0, 9999);
          });
          _snack('Approved: ${it.title}');
        },
        onReject: (it) async {
          final yes = await _confirm(
            context,
            title: 'Reject Request',
            message: 'Reject "${it.title}"?',
          );
          if (!yes) return;
          setState(() {
            _toApprove.remove(it);
            _pending = (_pending - 1).clamp(0, 9999);
          });
          _snack('Rejected: ${it.title}');
        },
        onView: _viewEvidence,
      ),
      _UsersTab(
        rows: _users,
        query: _userQuery,
        onQuery: (q) => setState(() => _userQuery = q),
        onChangeRole: (row) async {
          final newRole = await _pickRole(context, current: row.role);
          if (newRole == null) return;
          setState(() => row.role = newRole);
          _snack('Role changed to $newRole for ${row.name}');
        },
        onToggleStatus: (row) {
          setState(
            () => row.status = row.status == 'Active' ? 'Suspended' : 'Active',
          );
          _snack('${row.name} is now ${row.status}');
        },
        onResetPwd: (row) =>
            _snack('Password reset email sent to ${row.email} (mock)'),
      ),
      _AnalyticsTab(labels: _weekLabels, values: _weekActivity),
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
          title: const Text('Admin Dashboard'),
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
                        .withOpacity(.18),
              ),
            ),
            Positioned(
              bottom: -160,
              left: -110,
              child: _GlowOrb(
                size: 360,
                color:
                    (isDark ? const Color(0xFFCBA135) : const Color(0xFF3F8CFF))
                        .withOpacity(.16),
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
              icon: Icon(Icons.apartment_outlined),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_outlined),
              label: 'Approvals',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              label: 'Analytics',
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

  // ------- helpers / actions -------
  void _snack(String msg, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? cs.error : cs.primary,
      ),
    );
  }

  void _viewEvidence(_ApprovalItem it) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Evidence Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Container(
                height: 160,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 40),
                    const SizedBox(height: 6),
                    Text(it.evidence),
                    const SizedBox(height: 4),
                    Text(
                      '(${it.kind} • ${it.meta})',
                      style: Theme.of(context).textTheme.bodySmall,
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

  void _openBroadcast() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
                'Publish Institute Announcement',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: msgCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _snack(
                      'Announcement sent: "${titleCtrl.text.trim().isEmpty ? 'Untitled' : titleCtrl.text.trim()}"',
                    );
                  },
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Send (mock)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _pickRole(
    BuildContext context, {
    required String current,
  }) async {
    String temp = current;
    final roles = ['Student', 'Faculty', 'Admin'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Role'),
        content: DropdownButtonFormField<String>(
          value: temp,
          items: roles
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => temp = v ?? temp,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    return ok == true ? temp : null;
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
}

//
// ===================== OVERVIEW TAB =====================
class _OverviewTab extends StatelessWidget {
  final int students;
  final int faculty;
  final int clubs;
  final int pending;
  final VoidCallback onBroadcast;
  final List<String> weekLabels;
  final List<double> weekValues;

  const _OverviewTab({
    required this.students,
    required this.faculty,
    required this.clubs,
    required this.pending,
    required this.onBroadcast,
    required this.weekLabels,
    required this.weekValues,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // KPI Row
        Row(
          children: [
            Expanded(
              child: _KpiBox(
                icon: Icons.school_outlined,
                label: 'Students',
                value: '$students',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiBox(
                icon: Icons.badge_outlined,
                label: 'Faculty',
                value: '$faculty',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiBox(
                icon: Icons.groups_2_outlined,
                label: 'Clubs',
                value: '$clubs',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiBox(
                icon: Icons.hourglass_bottom_outlined,
                label: 'Pending',
                value: '$pending',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // System Health + Broadcast
        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Health', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Auth: OK • Firestore: OK • Storage: OK (mock)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onBroadcast,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Announcement'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Weekly activity chart
        _GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Activity', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _BarChart(labels: weekLabels, values: weekValues),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _KpiBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

//
// ===================== APPROVALS TAB =====================
class _ApprovalsTab extends StatelessWidget {
  final List<_ApprovalItem> queue;
  final List<_ApprovalItem> approved;
  final void Function(_ApprovalItem) onApprove;
  final void Function(_ApprovalItem) onReject;
  final void Function(_ApprovalItem) onView;

  const _ApprovalsTab({
    required this.queue,
    required this.approved,
    required this.onApprove,
    required this.onReject,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Text(
          'Final Approval Queue',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...queue.map(
          (it) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GlassCard(
              child: ListTile(
                leading: _kindIcon(it.kind),
                title: Text(it.title),
                subtitle: Text('${it.user} • ${it.meta}'),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    IconButton(
                      onPressed: () => onView(it),
                      tooltip: 'View Evidence',
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    IconButton(
                      onPressed: () => onReject(it),
                      tooltip: 'Reject',
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                    ),
                    IconButton(
                      onPressed: () => onApprove(it),
                      tooltip: 'Approve',
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
          (it) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GlassCard(
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(it.title),
                subtitle: Text('${it.user} • Approved'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kindIcon(String kind) {
    switch (kind) {
      case 'Certificate':
        return const CircleAvatar(
          child: Icon(Icons.workspace_premium_outlined),
        );
      case 'Event':
        return const CircleAvatar(child: Icon(Icons.event_outlined));
      case 'Account':
        return const CircleAvatar(child: Icon(Icons.person_add_alt_1_outlined));
      default:
        return const CircleAvatar(child: Icon(Icons.folder_outlined));
    }
  }
}

//
// ===================== USERS TAB =====================
class _UsersTab extends StatelessWidget {
  final List<_UserRow> rows;
  final String query;
  final ValueChanged<String> onQuery;
  final void Function(_UserRow) onChangeRole;
  final void Function(_UserRow) onToggleStatus;
  final void Function(_UserRow) onResetPwd;

  const _UsersTab({
    required this.rows,
    required this.query,
    required this.onQuery,
    required this.onChangeRole,
    required this.onToggleStatus,
    required this.onResetPwd,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = rows.where((r) {
      final q = query.toLowerCase();
      return r.name.toLowerCase().contains(q) ||
          r.email.toLowerCase().contains(q) ||
          r.role.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: onQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name, email, role…',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _exportUsers(context, filtered.length),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Export (mock)'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: filtered
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(Text(r.name)),
                        DataCell(Text(r.email)),
                        DataCell(Text(r.role)),
                        DataCell(Text(r.status)),
                        DataCell(
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => onChangeRole(r),
                                child: const Text('Change Role'),
                              ),
                              TextButton(
                                onPressed: () => onToggleStatus(r),
                                child: Text(
                                  r.status == 'Active' ? 'Suspend' : 'Restore',
                                ),
                              ),
                              IconButton(
                                onPressed: () => onResetPwd(r),
                                tooltip: 'Reset Password',
                                icon: const Icon(Icons.key_outlined),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _exportUsers(BuildContext context, int count) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exported $count users (mock CSV)')));
  }
}

//
// ===================== ANALYTICS TAB =====================
class _AnalyticsTab extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  const _AnalyticsTab({required this.labels, required this.values});

  @override
  Widget build(BuildContext context) {
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
                  'This Week — Total Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _BarChart(labels: labels, values: values),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _GlassCard(
          child: ListTile(
            leading: const Icon(Icons.auto_graph_outlined),
            title: const Text('Top Signals (mock)'),
            subtitle: const Text(
              'High engagement on Wed/Fri • Certificate approvals spiked Fri',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Open deep dive (mock)')),
            ),
          ),
        ),
      ],
    );
  }
}

//
// ===================== SETTINGS TAB =====================
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
    final name = user?.displayName ?? 'Admin';
    final email = user?.email ?? 'admin@xenchive.edu';
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
            title: const Text('Institute Notifications'),
            subtitle: const Text('System alerts, approvals, escalations'),
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
// ===================== SHARED UI =====================
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

class _BarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  const _BarChart({required this.labels, required this.values});

  @override
  Widget build(BuildContext context) {
    final maxVal = values.fold<double>(0.0, (p, c) => math.max(p, c));
    return LayoutBuilder(
      builder: (ctx, c) {
        final count = values.length;
        final slot = c.maxWidth / count;
        final barWidth = slot * .5;
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
                  for (final t in labels)
                    SizedBox(
                      width: slot,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            t,
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
// ===================== MODELS =====================
class _ApprovalItem {
  final String kind; // Certificate | Event | Account
  final String title;
  final String user;
  final String meta;
  final String evidence;
  final String status;
  _ApprovalItem({
    required this.kind,
    required this.title,
    required this.user,
    required this.meta,
    required this.evidence,
    this.status = 'Pending',
  });

  _ApprovalItem copyWith({String? status}) => _ApprovalItem(
    kind: kind,
    title: title,
    user: user,
    meta: meta,
    evidence: evidence,
    status: status ?? this.status,
  );
}

class _UserRow {
  final String name;
  final String email;
  String role;
  String status; // Active | Suspended
  _UserRow({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });
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
