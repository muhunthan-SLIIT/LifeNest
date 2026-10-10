// ignore_for_file: file_names, unnecessary_underscores, deprecated_member_use
// LifeNest Focus page (+ item detail screen)
// Save as lib/focus_screen.dart. Requires only google_fonts.
//
// Usage:
//   FocusScreen(
//     userInitial: 'A',
//     onHome: () => ...,
//     onNest: () => ...,
//     onBudget: () => ...,
//     onProfile: () => ...,
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bottom_nav_bar.dart';

class _C {
  static const bg = Color(0xFFFBF7EF);
  static const forest = Color(0xFF195A3B);
  static const card = Color(0xFFFFFEFC);
  static const text = Color(0xFF12301F);
  static const muted = Color(0xFF6B7F73);
  static const border = Color(0xFFE9E3D6);
  static const coral = Color(0xFFE8795A);

  static const mint = Color(0xFFDCEBDD);
  static const mintIcon = Color(0xFF2F6B4A);
  static const lavender = Color(0xFFEBE3FA);
  static const lavenderIcon = Color(0xFF8A7BC0);
  static const sky = Color(0xFFD8EAFB);
  static const skyIcon = Color(0xFF3D78B5);
  static const peach = Color(0xFFF8E7D3);
  static const peachIcon = Color(0xFFE9774F);
}

TextStyle _t(
  double size, {
  FontWeight w = FontWeight.w500,
  Color color = _C.text,
  double? height,
  double? spacing,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: w,
  color: color,
  height: height,
  letterSpacing: spacing,
);

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

enum ItemKind { list, device, travel, idea }

extension on ItemKind {
  IconData get icon => switch (this) {
    ItemKind.list => Icons.checklist_rounded,
    ItemKind.device => Icons.smartphone_rounded,
    ItemKind.travel => Icons.flight_rounded,
    ItemKind.idea => Icons.lightbulb_outline_rounded,
  };
  Color get bg => switch (this) {
    ItemKind.list => _C.mint,
    ItemKind.device => _C.lavender,
    ItemKind.travel => _C.sky,
    ItemKind.idea => _C.peach,
  };
  Color get fg => switch (this) {
    ItemKind.list => _C.mintIcon,
    ItemKind.device => _C.lavenderIcon,
    ItemKind.travel => _C.skyIcon,
    ItemKind.idea => _C.peachIcon,
  };
}

enum FocusStatus { now, soon, someday, expired }

extension on FocusStatus {
  String get label => switch (this) {
    FocusStatus.now => 'NOW',
    FocusStatus.soon => 'SOON',
    FocusStatus.someday => 'SOMEDAY',
    FocusStatus.expired => 'EXPIRED',
  };
  Color get bg => switch (this) {
    FocusStatus.now => const Color(0xFFFFE2D2),
    FocusStatus.soon => const Color(0xFFFBEBDD),
    FocusStatus.someday => const Color(0xFFEDE5FA),
    FocusStatus.expired => const Color(0xFFECEBE3),
  };
  Color get fg => switch (this) {
    FocusStatus.now => const Color(0xFF5E2F1B),
    FocusStatus.soon => const Color(0xFF3A2C20),
    FocusStatus.someday => const Color(0xFF3B2F63),
    FocusStatus.expired => const Color(0xFF3E4A41),
  };
}

const _keep = Object();
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class FocusItem {
  const FocusItem({
    required this.id,
    required this.title,
    required this.kind,
    this.category,
    this.collection,
    this.date,
    this.attachments = 0,
    this.expired = false,
    this.urgent = false,
    this.tags = const [],
  });

  final String id;
  final String title;
  final ItemKind kind;
  final String? category;
  final String? collection;
  final DateTime? date;
  final int attachments;
  final bool expired;
  final bool urgent;
  final List<String> tags;

  FocusItem copyWith({
    String? title,
    Object? category = _keep,
    Object? collection = _keep,
    Object? date = _keep,
    bool? expired,
  }) => FocusItem(
    id: id,
    title: title ?? this.title,
    kind: kind,
    category: identical(category, _keep) ? this.category : category as String?,
    collection: identical(collection, _keep)
        ? this.collection
        : collection as String?,
    date: identical(date, _keep) ? this.date : date as DateTime?,
    attachments: attachments,
    expired: expired ?? this.expired,
    urgent: urgent,
    tags: tags,
  );

  int? get daysFromToday => date == null
      ? null
      : DateUtils.dateOnly(date!)
            .difference(DateUtils.dateOnly(DateTime.now()))
            .inDays;

  /// Always derived from the item's real state (never stored separately).
  FocusStatus get status {
    if (expired) return FocusStatus.expired;
    final d = daysFromToday;
    if (d != null) {
      if (d <= 0) return FocusStatus.now;
      if (d <= 14) return FocusStatus.soon;
    }
    return FocusStatus.someday;
  }

  String? get dateText {
    final d = daysFromToday;
    if (date == null || d == null) return null;
    final String rel;
    if (d == 0) {
      rel = 'Today';
    } else if (d == 1) {
      rel = 'Tomorrow';
    } else if (d == -1) {
      rel = 'Yesterday';
    } else if (d < -1) {
      rel = '${-d} days ago';
    } else if (d <= 7) {
      rel = 'In $d days';
    } else if (d <= 14) {
      rel = 'Next week';
    } else {
      rel = 'In ${(d / 7).round()} weeks';
    }
    return '${_months[date!.month - 1]} ${date!.day} · $rel';
  }

  bool get isUnsorted => category == null || category!.trim().isEmpty;

  bool get isToday => status == FocusStatus.now;

  bool get needsAttention =>
      urgent || status == FocusStatus.now || status == FocusStatus.expired;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      title,
      category ?? '',
      collection ?? '',
      dateText ?? '',
      status.label,
      ...tags,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }
}

enum _Filter { all, today, attention, unsorted }

const _filterLabels = {
  _Filter.all: 'All',
  _Filter.today: 'Today',
  _Filter.attention: 'Needs attention',
  _Filter.unsorted: 'Unsorted',
};

const _collectionNames = ['Japan Trip', 'New House', 'Birthday Gifts'];

// ---------------------------------------------------------------------------
// Focus screen
// ---------------------------------------------------------------------------

class FocusScreen extends StatefulWidget {
  const FocusScreen({
    super.key,
    this.userInitial = 'A',
    this.onHome,
    this.onNest,
    this.onBudget,
    this.onProfile,
    this.onAdd,
  });

  final String userInitial;
  final VoidCallback? onHome;
  final VoidCallback? onNest;
  final VoidCallback? onBudget;
  final VoidCallback? onProfile;
  final VoidCallback? onAdd;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.all;
  String _query = '';
  bool _loading = true;
  List<FocusItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // TODO: replace with your real data source (API / local DB).
    await Future.delayed(const Duration(milliseconds: 450));
    final now = DateTime.now();
    if (!mounted) return;
    setState(() {
      _items = [
        FocusItem(
          id: '1',
          title: 'Weekly shopping',
          kind: ItemKind.list,
          category: 'Lists',
          date: now.subtract(const Duration(days: 1)),
        ),
        const FocusItem(
          id: '2',
          title: 'Parking — Level 3, bay 214',
          kind: ItemKind.device,
          category: 'Screenshots',
          expired: true,
        ),
        FocusItem(
          id: '3',
          title: 'Train — London to Edinburgh',
          kind: ItemKind.travel,
          category: 'Travel',
          date: now.add(const Duration(days: 8)),
          attachments: 1,
        ),
        const FocusItem(
          id: '4',
          title: 'Article — How to rest properly',
          kind: ItemKind.idea,
          category: 'Ideas',
          attachments: 1,
        ),
        const FocusItem(
          id: '5',
          title: 'Rattan lamp from Instagram',
          kind: ItemKind.idea,
          category: 'Ideas',
          collection: 'New House',
          attachments: 1,
        ),
      ];
      _loading = false;
    });
  }

  List<FocusItem> get _visible => _items.where((i) {
    final byFilter = switch (_filter) {
      _Filter.all => true,
      _Filter.today => i.isToday,
      _Filter.attention => i.needsAttention,
      _Filter.unsorted => i.isUnsorted,
    };
    return byFilter && i.matches(_query);
  }).toList();

  void _replace(FocusItem updated) {
    setState(() {
      _items = [for (final i in _items) i.id == updated.id ? updated : i];
    });
  }

  void _delete(String id) {
    setState(() => _items = _items.where((i) => i.id != id).toList());
  }

  void _openItem(FocusItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusItemDetailScreen(
          item: item,
          onChanged: _replace,
          onDelete: () => _delete(item.id),
        ),
      ),
    );
  }

  void _openAdd() {
    if (widget.onAdd != null) {
      widget.onAdd!();
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.bg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearch(),
            const SizedBox(height: 14),
            _buildChips(),
            const SizedBox(height: 14),
            Expanded(child: _buildList(bottomSafe)),
          ],
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : LifeNestNavBar(
              currentTab: 1,
              onAdd: _openAdd,
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus',
                  style: _t(
                    32,
                    w: FontWeight.w800,
                    color: _C.forest,
                    spacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "What needs you, and everything you've added.",
                  style: _t(15, color: _C.muted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: 'Open profile',
            child: Material(
              color: _C.forest,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onProfile,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: Text(
                      widget.userInitial,
                      style: _t(18, w: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 14,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          cursorColor: _C.forest,
          style: _t(16),
          decoration: InputDecoration(
            hintText: 'Search what needs you',
            hintStyle: _t(16, color: _C.muted),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 24,
              color: _C.muted,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: _C.muted,
                    ),
                    onPressed: _clearSearch,
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  Widget _buildChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _Filter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final f = _Filter.values[i];
          final active = f == _filter;
          return Material(
            color: active ? _C.forest : _C.card,
            shape: StadiumBorder(
              side: BorderSide(color: active ? _C.forest : _C.border),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => setState(() => _filter = f),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: Text(
                    _filterLabels[f]!,
                    style: _t(
                      15,
                      w: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF3E5A4A),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(double bottomSafe) {
    final bottomPad = 110 + bottomSafe;

    if (_loading) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => Container(
          height: 92,
          decoration: BoxDecoration(
            color: _C.card.withOpacity(0.7),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: _C.border),
          ),
        ),
      );
    }

    final items = _visible;
    if (items.isEmpty) return _buildEmpty();

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) =>
          _FocusCard(item: items[i], onTap: () => _openItem(items[i])),
    );
  }

  Widget _buildEmpty() {
    final searching = _query.trim().isNotEmpty;
    final message = searching
        ? 'No matching items found.'
        : switch (_filter) {
            _Filter.all => 'Nothing here yet. Add anything to begin.',
            _Filter.today => 'Nothing is due today.',
            _Filter.attention => 'Nothing needs your attention right now.',
            _Filter.unsorted => 'Everything is neatly organised.',
          };

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off_rounded : Icons.spa_outlined,
              size: 40,
              color: _C.muted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _t(15, color: _C.muted),
            ),
            if (searching) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearSearch,
                child: Text(
                  'Clear search',
                  style: _t(14, w: FontWeight.w700, color: _C.forest),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

/// Soft, slightly irregular rounded square used for item icons.
class _BlobIcon extends StatelessWidget {
  const _BlobIcon(this.kind, {this.size = 56});

  final ItemKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kind.bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.40),
          topRight: Radius.circular(size * 0.46),
          bottomRight: Radius.circular(size * 0.36),
          bottomLeft: Radius.circular(size * 0.46),
        ),
      ),
      child: Icon(kind.icon, size: size * 0.42, color: kind.fg),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final FocusStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: _t(11.5, w: FontWeight.w800, color: status.fg, spacing: 0.7),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.item, required this.onTap});

  final FocusItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    final dateText = item.dateText;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(34),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BlobIcon(item.kind),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _t(
                                  16.5,
                                  w: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (!item.isUnsorted)
                            Text(
                              item.category!,
                              style: _t(13.5, color: _C.muted),
                            ),
                          if (dateText != null)
                            Text(
                              dateText,
                              style: _t(
                                13.5,
                                w: FontWeight.w600,
                                color: status == FocusStatus.now
                                    ? _C.coral
                                    : const Color(0xFF3E5A4A),
                              ),
                            ),
                          if (item.collection != null)
                            _MetaChip(Icons.folder_outlined, item.collection!),
                          if (item.attachments > 0)
                            _MetaChip(
                              Icons.attach_file_rounded,
                              '${item.attachments}',
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
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _C.muted),
        const SizedBox(width: 3),
        Text(text, style: _t(13.5, color: _C.muted)),
      ],
    );
  }
}



class _AddSheet extends StatelessWidget {
  const _AddSheet();

  static const _options = <(IconData, String)>[
    (Icons.photo_camera_outlined, 'Photos'),
    (Icons.description_outlined, 'Documents'),
    (Icons.link_rounded, 'Links'),
    (Icons.menu_book_outlined, 'Notes'),
    (Icons.location_on_outlined, 'Places'),
    (Icons.lightbulb_outline_rounded, 'Ideas'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add anything',
              style: _t(24, w: FontWeight.w800, color: _C.forest),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                for (final o in _options)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: open the capture flow for o.$2
                    },
                    child: SizedBox(
                      width: 92,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _C.mint,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(o.$1, color: _C.forest),
                          ),
                          const SizedBox(height: 8),
                          Text(o.$2, style: _t(12.5, w: FontWeight.w600)),
                        ],
                      ),
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

// ---------------------------------------------------------------------------
// Item detail
// ---------------------------------------------------------------------------

class FocusItemDetailScreen extends StatefulWidget {
  const FocusItemDetailScreen({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final FocusItem item;
  final ValueChanged<FocusItem> onChanged;
  final VoidCallback onDelete;

  @override
  State<FocusItemDetailScreen> createState() => _FocusItemDetailScreenState();
}

class _FocusItemDetailScreenState extends State<FocusItemDetailScreen> {
  late FocusItem _item = widget.item;

  void _update(FocusItem next) {
    setState(() => _item = next);
    widget.onChanged(next);
  }

  Future<void> _edit() async {
    final title = TextEditingController(text: _item.title);
    final category = TextEditingController(text: _item.category ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        title: Text('Edit item', style: _t(18, w: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: category,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      final cat = category.text.trim();
      _update(
        _item.copyWith(
          title: title.text.trim(),
          category: cat.isEmpty ? null : cat,
        ),
      );
    }
    title.dispose();
    category.dispose();
  }

  Future<void> _changeStatus() async {
    final choice = await _pickFromSheet<FocusStatus>(
      title: 'Change status',
      options: FocusStatus.values,
      label: (s) => s.label,
      selected: _item.status,
    );
    if (choice == null) return;
    final today = DateUtils.dateOnly(DateTime.now());
    _update(switch (choice) {
      FocusStatus.now => _item.copyWith(date: today, expired: false),
      FocusStatus.soon => _item.copyWith(
        date: today.add(const Duration(days: 7)),
        expired: false,
      ),
      FocusStatus.someday => _item.copyWith(date: null, expired: false),
      FocusStatus.expired => _item.copyWith(expired: true),
    });
  }

  Future<void> _move() async {
    const none = 'No collection';
    final choice = await _pickFromSheet<String>(
      title: 'Move to collection',
      options: const [none, ..._collectionNames],
      label: (s) => s,
      selected: _item.collection ?? none,
    );
    if (choice == null) return;
    _update(_item.copyWith(collection: choice == none ? null : choice));
  }

  Future<T?> _pickFromSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) label,
    required T selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: _C.bg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title, style: _t(20, w: FontWeight.w800)),
            ),
            for (final o in options)
              ListTile(
                title: Text(label(o), style: _t(15, w: FontWeight.w600)),
                trailing: o == selected
                    ? const Icon(Icons.check_rounded, color: _C.forest)
                    : null,
                onTap: () => Navigator.pop(ctx, o),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        title: Text('Delete this item?', style: _t(18, w: FontWeight.w800)),
        content: Text(
          '"${_item.title}" will be removed.',
          style: _t(14, color: _C.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      widget.onDelete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final dateText = item.dateText;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: _C.card,
                shape: const CircleBorder(side: BorderSide(color: _C.border)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.maybePop(context),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 26,
                      color: _C.forest,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _BlobIcon(item.kind, size: 72),
              const SizedBox(height: 20),
              Text(
                item.title,
                style: _t(
                  26,
                  w: FontWeight.w800,
                  color: _C.forest,
                  height: 1.15,
                  spacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              _StatusPill(item.status),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _C.border),
                ),
                child: Column(
                  children: [
                    if (!item.isUnsorted) _InfoRow('Category', item.category!),
                    if (item.collection != null)
                      _InfoRow('Collection', item.collection!),
                    if (dateText != null) _InfoRow('Date', dateText),
                    if (item.attachments > 0)
                      _InfoRow(
                        'Attachments',
                        '${item.attachments} attachment'
                            '${item.attachments == 1 ? '' : 's'}',
                      ),
                    if (item.isUnsorted &&
                        item.collection == null &&
                        dateText == null &&
                        item.attachments == 0)
                      _InfoRow('Details', 'No details yet'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ActionButton(Icons.edit_outlined, 'Edit', _edit),
              _ActionButton(
                Icons.flag_outlined,
                'Change status',
                _changeStatus,
              ),
              _ActionButton(Icons.folder_outlined, 'Move to collection', _move),
              _ActionButton(
                Icons.delete_outline_rounded,
                'Delete',
                _confirmDelete,
                color: const Color(0xFFC0392B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: _t(13.5, color: _C.muted)),
          ),
          Expanded(
            child: Text(value, style: _t(14.5, w: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
    this.icon,
    this.label,
    this.onTap, {
    this.color = _C.forest,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _C.card,
        shape: StadiumBorder(side: BorderSide(color: _C.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 18),
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: _t(15, w: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
