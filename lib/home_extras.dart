// LifeNest - extra screens that were TODO stubs on Home:
// Notifications, Timeline, Collections (+ detail) and a Home item detail.
//
// Styled with the same palette / Plus Jakarta Sans / Caveat look as the rest
// of the app. Data is a small in-memory sample set that matches the cards
// shown on Home. Replace HxData with your real store when you have one.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _C {
  static const forest = Color(0xFF16402B);
  static const cream = Color(0xFFFAF8F3);
  static const border = Color(0xFFEFEDE7);
  static const muted = Color(0xFF6E7F75);
  static const leaf = Color(0xFF5E9B6F);
  static const peachAccent = Color(0xFFE9795A);

  static const mint = Color(0xFFDDEEE3);
  static const mintIcon = Color(0xFF2F6B4A);
  static const blue = Color(0xFFDCE9F7);
  static const blueIcon = Color(0xFF3F6FA8);
  static const slate = Color(0xFFE3E8EE);
  static const slateIcon = Color(0xFF56667A);
  static const lavender = Color(0xFFE9E4F6);
  static const lavenderIcon = Color(0xFF7463B0);
  static const peach = Color(0xFFFCE4DC);
  static const peachIcon = Color(0xFFD9683F);
}

TextStyle _t(
  double size, {
  FontWeight w = FontWeight.w500,
  Color color = _C.forest,
  double? height,
  double? spacing,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: w,
  color: color,
  height: height,
  letterSpacing: spacing,
);

BoxDecoration _cardDecoration([Color color = Colors.white]) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: _C.border),
  boxShadow: const [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ],
);

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

enum HxTone { blue, lavender, peach, mint, slate }

extension HxToneX on HxTone {
  Color get bg => switch (this) {
    HxTone.blue => _C.blue,
    HxTone.lavender => _C.lavender,
    HxTone.peach => _C.peach,
    HxTone.mint => _C.mint,
    HxTone.slate => _C.slate,
  };
  Color get fg => switch (this) {
    HxTone.blue => _C.blueIcon,
    HxTone.lavender => _C.lavenderIcon,
    HxTone.peach => _C.peachIcon,
    HxTone.mint => _C.mintIcon,
    HxTone.slate => _C.slateIcon,
  };
}

enum HxStatus { now, soon, later, someday }

extension HxStatusX on HxStatus {
  String get label => switch (this) {
    HxStatus.now => 'NOW',
    HxStatus.soon => 'SOON',
    HxStatus.later => 'LATER',
    HxStatus.someday => 'SOMEDAY',
  };
  Color get bg => switch (this) {
    HxStatus.now => const Color(0xFFFFE2D2),
    HxStatus.soon => const Color(0xFFFBEBDD),
    HxStatus.later => const Color(0xFFE3E8EE),
    HxStatus.someday => const Color(0xFFEDE5FA),
  };
  Color get fg => switch (this) {
    HxStatus.now => const Color(0xFF5E2F1B),
    HxStatus.soon => const Color(0xFF3A2C20),
    HxStatus.later => const Color(0xFF3E4A5C),
    HxStatus.someday => const Color(0xFF3B2F63),
  };
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _relative(int d) {
  if (d == 0) return 'Today';
  if (d == 1) return 'Tomorrow';
  if (d == -1) return 'Yesterday';
  if (d < -1) return '${-d} days ago';
  return 'In $d days';
}

class HxItem {
  const HxItem({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.tone,
    this.subtitle,
    this.dayOffset,
    this.collectionId,
    this.attachments = 0,
  });

  final String id;
  final String title;
  final String category;
  final IconData icon;
  final HxTone tone;
  final String? subtitle;

  /// Days from today. null = no date.
  final int? dayOffset;
  final String? collectionId;
  final int attachments;

  DateTime? get date {
    final d = dayOffset;
    if (d == null) return null;
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + d);
  }

  HxStatus get status {
    final d = dayOffset;
    if (d == null) return HxStatus.someday;
    if (d <= 0) return HxStatus.now;
    if (d <= 14) return HxStatus.soon;
    return HxStatus.later;
  }

  /// e.g. "Oct 14 - In 2 days"
  String? get dateText {
    final dt = date;
    final d = dayOffset;
    if (dt == null || d == null) return null;
    return '${_months[dt.month - 1]} ${dt.day} · ${_relative(d)}';
  }
}

class HxCollection {
  const HxCollection({
    required this.id,
    required this.title,
    required this.icon,
    required this.tone,
  });

  final String id;
  final String title;
  final IconData icon;
  final HxTone tone;
}

class HxData {
  static const collections = <HxCollection>[
    HxCollection(
      id: 'japan',
      title: 'Japan Trip',
      icon: Icons.temple_buddhist_outlined,
      tone: HxTone.blue,
    ),
    HxCollection(
      id: 'house',
      title: 'New House',
      icon: Icons.home_outlined,
      tone: HxTone.mint,
    ),
    HxCollection(
      id: 'gifts',
      title: 'Birthday Gifts',
      icon: Icons.card_giftcard_outlined,
      tone: HxTone.lavender,
    ),
  ];

  static const items = <HxItem>[
    HxItem(
      id: 'bill',
      title: 'Check important bill',
      subtitle: 'London Heathrow → Singapore',
      category: 'Travel',
      icon: Icons.flight_takeoff_rounded,
      tone: HxTone.blue,
      dayOffset: 0,
      collectionId: 'japan',
      attachments: 1,
    ),
    HxItem(
      id: 'dentist',
      title: 'Dentist appointment',
      subtitle: 'Appointments',
      category: 'Appointments',
      icon: Icons.event_available_outlined,
      tone: HxTone.lavender,
      dayOffset: 0,
    ),
    HxItem(
      id: 'nike',
      title: 'Nike Air Max',
      subtitle: 'Return window closes soon',
      category: 'Shopping',
      icon: Icons.shopping_bag_outlined,
      tone: HxTone.peach,
      dayOffset: 2,
      attachments: 1,
    ),
    HxItem(
      id: 'adobe',
      title: 'Adobe trial renews',
      subtitle: 'Renews monthly after the trial',
      category: 'Finance',
      icon: Icons.autorenew_rounded,
      tone: HxTone.blue,
      dayOffset: 5,
    ),
    HxItem(
      id: 'flowers',
      title: 'Order flowers',
      category: 'Shopping',
      icon: Icons.local_florist_outlined,
      tone: HxTone.lavender,
      dayOffset: 6,
      collectionId: 'gifts',
    ),
    HxItem(
      id: 'school',
      title: 'School notice — Insert day',
      subtitle: 'No school on the 19th',
      category: 'Family',
      icon: Icons.description_outlined,
      tone: HxTone.slate,
      dayOffset: 9,
      attachments: 1,
    ),
    HxItem(
      id: 'carins',
      title: 'Car insurance due',
      category: 'Finance',
      icon: Icons.shield_outlined,
      tone: HxTone.blue,
      dayOffset: 21,
    ),
    HxItem(
      id: 'homeins',
      title: 'Home insurance',
      subtitle: 'Renewal quote ready',
      category: 'Finance',
      icon: Icons.verified_user_outlined,
      tone: HxTone.mint,
      dayOffset: 21,
      collectionId: 'house',
      attachments: 1,
    ),
    HxItem(
      id: 'passport',
      title: 'Passport renewal',
      subtitle: 'Expires soon',
      category: 'Documents',
      icon: Icons.badge_outlined,
      tone: HxTone.blue,
      dayOffset: 60,
      collectionId: 'japan',
      attachments: 1,
    ),
    HxItem(
      id: 'dishoom',
      title: 'Dishoom',
      subtitle: 'Black daal, bacon naan roll',
      category: 'Travel',
      icon: Icons.restaurant_outlined,
      tone: HxTone.blue,
    ),
    HxItem(
      id: 'sony',
      title: 'Sony WH-1000XM5',
      subtitle: 'Wait for a sale',
      category: 'Shopping',
      icon: Icons.headphones_outlined,
      tone: HxTone.peach,
    ),
    HxItem(
      id: 'kyoto',
      title: 'Kyoto, Japan',
      subtitle: "Philosopher's Path in the morning",
      category: 'Travel',
      icon: Icons.place_outlined,
      tone: HxTone.blue,
      collectionId: 'japan',
    ),
    HxItem(
      id: 'book',
      title: 'Thinking, Fast and Slow',
      category: 'Read & Watch',
      icon: Icons.menu_book_outlined,
      tone: HxTone.slate,
    ),
    HxItem(
      id: 'lamp',
      title: 'Rattan lamp',
      subtitle: 'Saved from Instagram',
      category: 'Ideas',
      icon: Icons.lightbulb_outline_rounded,
      tone: HxTone.mint,
      collectionId: 'house',
    ),
    HxItem(
      id: 'giftcard',
      title: 'Gift card for Emma',
      category: 'Shopping',
      icon: Icons.redeem_outlined,
      tone: HxTone.lavender,
      collectionId: 'gifts',
    ),
    HxItem(
      id: 'wrap',
      title: 'Buy wrapping paper',
      category: 'Lists',
      icon: Icons.checklist_rounded,
      tone: HxTone.lavender,
      collectionId: 'gifts',
    ),
    HxItem(
      id: 'cardmsg',
      title: 'Write birthday card',
      category: 'Lists',
      icon: Icons.edit_note_rounded,
      tone: HxTone.lavender,
      collectionId: 'gifts',
    ),
  ];

  /// Matches an exact title first, then a title that starts with [title]
  /// (so Home's short label "School notice" finds "School notice — Insert day").
  static HxItem? itemByTitle(String title) {
    final t = title.trim().toLowerCase();
    for (final i in items) {
      if (i.title.toLowerCase() == t) return i;
    }
    for (final i in items) {
      if (i.title.toLowerCase().startsWith(t)) return i;
    }
    return null;
  }

  static HxCollection? collectionByTitle(String title) {
    final t = title.trim().toLowerCase();
    for (final c in collections) {
      if (c.title.toLowerCase() == t) return c;
    }
    return null;
  }

  static HxCollection? collectionById(String id) {
    for (final c in collections) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<HxItem> itemsIn(String collectionId) =>
      items.where((i) => i.collectionId == collectionId).toList();
}

/// Opens the right screen for a title tapped on Home: an item detail,
/// or a collection if the title is a collection name.
void openHomeItem(BuildContext context, String title) {
  final item = HxData.itemByTitle(title);
  if (item != null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HomeItemDetailScreen(item: item)),
    );
    return;
  }
  final c = HxData.collectionByTitle(title);
  if (c != null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CollectionDetailScreen(collection: c)),
    );
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Nothing saved for "$title" yet.')),
  );
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, this.tone, {this.size = 40});

  final IconData icon;
  final HxTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: tone.fg),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final HxStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: _t(10.5, w: FontWeight.w800, color: status.fg, spacing: 0.8),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(side: BorderSide(color: _C.border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: _C.forest,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _t(28, w: FontWeight.w800, spacing: -0.8, height: 1.1),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: GoogleFonts.caveat(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: _C.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap, this.showDate = true});

  final HxItem item;
  final VoidCallback onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      item.category,
      if (showDate && item.dateText != null) item.dateText!,
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _IconBox(item.icon, item.tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _t(14.5, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(12, color: _C.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(item.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.icon, this.message);

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: _C.leaf),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _C.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openItemScreen(BuildContext context, HxItem item) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => HomeItemDetailScreen(item: item)),
  );
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

class _Notice {
  const _Notice(this.id, this.item, this.text);

  final String id;
  final HxItem item;
  final String text;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _read = {};
  late final List<_Notice> _notices = _build();

  List<_Notice> _build() {
    final due = HxData.items
        .where((i) => i.dayOffset != null && i.dayOffset! <= 3)
        .toList()
      ..sort((a, b) => a.dayOffset!.compareTo(b.dayOffset!));
    return [
      for (final i in due)
        _Notice(
          i.id,
          i,
          switch (i.dayOffset!) {
            < 0 => '${i.title} is overdue',
            0 => '${i.title} is due today',
            1 => '${i.title} is due tomorrow',
            final d => '${i.title} is due in $d days',
          },
        ),
    ];
  }

  int get _unread => _notices.where((n) => !_read.contains(n.id)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: SafeArea(
        child: Column(
          children: [
            _ScreenHeader(
              title: 'Notifications',
              subtitle: _unread == 0
                  ? 'All caught up.'
                  : '$_unread ${_unread == 1 ? 'thing needs' : 'things need'} you.',
              trailing: TextButton(
                onPressed: _unread == 0
                    ? null
                    : () => setState(
                        () => _read.addAll(_notices.map((n) => n.id)),
                      ),
                child: Text(
                  'Mark all read',
                  style: _t(
                    12.5,
                    w: FontWeight.w700,
                    color: _unread == 0 ? _C.muted : _C.forest,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _notices.isEmpty
                  ? const _EmptyState(
                      Icons.notifications_none_rounded,
                      'Nothing needs you right now.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: _notices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final n = _notices[index];
                        final unread = !_read.contains(n.id);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              setState(() => _read.add(n.id));
                              _openItemScreen(context, n.item);
                            },
                            child: Ink(
                              padding: const EdgeInsets.all(12),
                              decoration: _cardDecoration(
                                unread ? Colors.white : _C.cream,
                              ),
                              child: Row(
                                children: [
                                  _IconBox(n.item.icon, n.item.tone),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.text,
                                          style: _t(
                                            14,
                                            w: unread
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          n.item.category,
                                          style: _t(12, color: _C.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (unread)
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: _C.peachAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
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

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  static String _dayLabel(HxItem i) {
    final d = i.dayOffset!;
    final dt = i.date!;
    final base = '${_weekdays[dt.weekday - 1]}, ${_months[dt.month - 1]} ${dt.day}';
    if (d == 0) return 'Today · $base';
    if (d == 1) return 'Tomorrow · $base';
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final dated = HxData.items.where((i) => i.dayOffset != null).toList()
      ..sort((a, b) => a.dayOffset!.compareTo(b.dayOffset!));
    final undated = HxData.items.length - dated.length;

    // Group items that fall on the same day.
    final groups = <int, List<HxItem>>{};
    for (final i in dated) {
      groups.putIfAbsent(i.dayOffset!, () => []).add(i);
    }
    final days = groups.keys.toList();

    return Scaffold(
      backgroundColor: _C.cream,
      body: SafeArea(
        child: Column(
          children: [
            const _ScreenHeader(
              title: 'Timeline',
              subtitle: "What's coming, in order.",
            ),
            Expanded(
              child: dated.isEmpty
                  ? const _EmptyState(
                      Icons.timeline_rounded,
                      'Nothing dated yet.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        for (var k = 0; k < days.length; k++)
                          _DayGroup(
                            label: _dayLabel(groups[days[k]]!.first),
                            isToday: days[k] <= 0,
                            isLast: k == days.length - 1,
                            items: groups[days[k]]!,
                          ),
                        if (undated > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '$undated more ${undated == 1 ? 'item has' : 'items have'} no date and live in your Nest.',
                              textAlign: TextAlign.center,
                              style: _t(12.5, color: _C.muted),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.label,
    required this.isToday,
    required this.isLast,
    required this.items,
  });

  final String label;
  final bool isToday;
  final bool isLast;
  final List<HxItem> items;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: isToday ? _C.peachAccent : _C.forest,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : _C.border,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: _t(
                      12,
                      w: FontWeight.w700,
                      color: _C.muted,
                      spacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final i in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ItemRow(
                        item: i,
                        showDate: false,
                        onTap: () => _openItemScreen(context, i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Collections
// ---------------------------------------------------------------------------

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  static const _tones = [
    HxTone.blue,
    HxTone.mint,
    HxTone.lavender,
    HxTone.peach,
    HxTone.slate,
  ];

  final List<HxCollection> _collections = [...HxData.collections];

  Future<void> _create() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('New collection', style: _t(18, w: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;
    setState(() {
      _collections.add(
        HxCollection(
          id: 'c${DateTime.now().microsecondsSinceEpoch}',
          title: trimmed,
          icon: Icons.folder_open_rounded,
          tone: _tones[_collections.length % _tones.length],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: SafeArea(
        child: Column(
          children: [
            _ScreenHeader(
              title: 'Collections',
              subtitle: 'Things that belong together.',
              trailing: Material(
                color: _C.forest,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _create,
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _collections.length,
                itemBuilder: (context, index) =>
                    _CollectionTile(collection: _collections[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.collection});

  final HxCollection collection;

  @override
  Widget build(BuildContext context) {
    final items = HxData.itemsIn(collection.id);
    final count = items.length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectionDetailScreen(collection: collection),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconBox(collection.icon, collection.tone, size: 44),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(15, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'}',
                    style: _t(12, color: _C.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({super.key, required this.collection});

  final HxCollection collection;

  @override
  Widget build(BuildContext context) {
    // Dated items first (soonest first), undated after.
    final items = HxData.itemsIn(collection.id)
      ..sort((a, b) {
        final x = a.dayOffset;
        final y = b.dayOffset;
        if (x == null && y == null) return 0;
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });

    return Scaffold(
      backgroundColor: _C.cream,
      body: SafeArea(
        child: Column(
          children: [
            _ScreenHeader(
              title: collection.title,
              subtitle: '${items.length} ${items.length == 1 ? 'item' : 'items'}',
              trailing: _IconBox(collection.icon, collection.tone, size: 44),
            ),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyState(
                      Icons.folder_open_rounded,
                      'Nothing in here yet.\nAdd something to start this nest.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _ItemRow(
                        item: items[index],
                        onTap: () => _openItemScreen(context, items[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item detail (for items tapped on Home)
// ---------------------------------------------------------------------------

class HomeItemDetailScreen extends StatefulWidget {
  const HomeItemDetailScreen({super.key, required this.item});

  final HxItem item;

  @override
  State<HomeItemDetailScreen> createState() => _HomeItemDetailScreenState();
}

class _HomeItemDetailScreenState extends State<HomeItemDetailScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final collection = item.collectionId == null
        ? null
        : HxData.collectionById(item.collectionId!);

    return Scaffold(
      backgroundColor: _C.cream,
      body: SafeArea(
        child: Column(
          children: [
            const _ScreenHeader(title: 'Details'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _IconBox(item.icon, item.tone, size: 56),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _StatusPill(
                                    _done ? HxStatus.later : item.status,
                                  ),
                                  Text(
                                    item.category,
                                    style: _t(12.5, color: _C.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.title,
                          style: _t(
                            24,
                            w: FontWeight.w800,
                            spacing: -0.6,
                            height: 1.15,
                          ).copyWith(
                            decoration: _done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        if (item.subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.subtitle!,
                            style: _t(14, color: _C.muted, height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.event_outlined,
                          label: 'Date',
                          value: item.dateText ?? 'No date',
                        ),
                        _InfoRow(
                          icon: Icons.folder_open_rounded,
                          label: 'Collection',
                          value: collection?.title ?? 'Not in a collection',
                          onTap: collection == null
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CollectionDetailScreen(
                                      collection: collection,
                                    ),
                                  ),
                                ),
                        ),
                        _InfoRow(
                          icon: Icons.attach_file_rounded,
                          label: 'Attachments',
                          value: item.attachments == 0
                              ? 'None'
                              : '${item.attachments} attached',
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _done = !_done),
                      icon: Icon(
                        _done
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _done ? 'Marked done · Undo' : 'Mark as done',
                        style: _t(15, w: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _done ? _C.leaf : _C.forest,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: _C.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _C.leaf),
            const SizedBox(width: 12),
            Text(label, style: _t(13.5, color: _C.muted)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: _t(13.5, w: FontWeight.w700),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _C.muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
