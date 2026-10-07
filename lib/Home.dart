// ignore_for_file: file_names, deprecated_member_use
// LifeNest Home Dashboard
// Save as lib/home_screen.dart. Requires only google_fonts.
//
// Usage: const HomeScreen(userName: 'Alex')

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main.dart';

class _C {
  static const forest = Color(0xFF16402B);
  static const cream = Color(0xFFFAF8F3);
  static const navBg = Color(0xFFFEFDFB);
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

  static const nowBg = Color(0xFFFDE8E1);
  static const nowText = Color(0xFFD9532F);
}

BoxDecoration _cardDecoration([Color color = Colors.white]) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: _C.border),
  boxShadow: const [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ],
);

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

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.userName = 'Alex'});

  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; // 0 Home, 1 Inbox, 2 Browse, 3 Settings

  // --- Hooks: connect these to your real screens -------------------------
  void _openNotifications() {
    /* TODO */
  }
  void _openProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.cream,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: _C.forest,
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : '?',
                  style: _t(28, w: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.userName, style: _t(20, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Signed in with LifeNest', style: _t(13, color: _C.muted)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                  ),
                  label: Text(
                    'Log Out',
                    style: _t(15, w: FontWeight.w700, color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  void _openTimeline() {
    /* TODO */
  }
  void _openBrowse() => setState(() => _tab = 2);
  void _openAllCollections() {
    /* TODO */
  }
  void _openItem(String title) {
    /* TODO: open detail screen for [title] */
  }
  // ------------------------------------------------------------------------

  void _openAddAnything() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.cream,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddAnythingSheet(),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'GOOD MORNING';
    if (h < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            _buildHome(),
            const _TabPlaceholder('Inbox'),
            const _TabPlaceholder('Browse'),
            const _TabPlaceholder('Settings'),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onTab: (i) => setState(() => _tab = i),
        onAdd: _openAddAnything,
      ),
    );
  }

  Widget _buildHome() {
    const pad = EdgeInsets.symmetric(horizontal: 20);
    final initial = widget.userName.isEmpty
        ? '?'
        : widget.userName[0].toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CustomPaint(painter: _NestLogoPainter()),
                ),
                const SizedBox(width: 8),
                Text(
                  'LifeNest',
                  style: _t(17, w: FontWeight.w800, spacing: -0.3),
                ),
                const Spacer(),
                _CircleButton(
                  onTap: _openNotifications,
                  background: Colors.white,
                  borderColor: _C.border,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: _C.forest,
                  ),
                ),
                const SizedBox(width: 10),
                _CircleButton(
                  onTap: _openProfile,
                  background: _C.forest,
                  child: Text(
                    initial,
                    style: _t(14, w: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Greeting
          Padding(
            padding: pad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: _t(
                    11,
                    w: FontWeight.w600,
                    color: _C.muted,
                    spacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.userName,
                  style: _t(36, w: FontWeight.w800, spacing: -1, height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  'A calmer mind for a brighter day.',
                  style: GoogleFonts.caveat(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: _C.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status cards
          Padding(
            padding: pad,
            child: Column(
              children: const [
                Row(
                  children: [
                    Expanded(child: _StatusCard('4', 'Need action', _C.leaf)),
                    SizedBox(width: 12),
                    Expanded(child: _StatusCard('5', 'Coming up', _C.blueIcon)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatusCard('6', 'Saved for later', _C.leaf),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatusCard(
                        '0',
                        'Waiting on you',
                        _C.lavenderIcon,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Today
          Padding(
            padding: pad,
            child: _SectionHeader('TODAY', 'Timeline', _openTimeline),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: pad,
            child: Column(
              children: [
                _TodayCard(
                  icon: Icons.flight_takeoff_rounded,
                  bg: _C.blue,
                  fg: _C.blueIcon,
                  title: 'Check important bill',
                  subtitle: 'London Heathrow → Singapore',
                  meta: 'Wed Sep 3 · Today',
                  onTap: () => _openItem('Check important bill'),
                ),
                const SizedBox(height: 10),
                _TodayCard(
                  icon: Icons.event_available_outlined,
                  bg: _C.lavender,
                  fg: _C.lavenderIcon,
                  title: 'Dentist appointment',
                  subtitle: 'Appointments',
                  meta: 'Sep 3 · 10:00',
                  onTap: () => _openItem('Dentist appointment'),
                ),
                const SizedBox(height: 10),
                _TodayCard(
                  icon: Icons.shopping_bag_outlined,
                  bg: _C.peach,
                  fg: _C.peachIcon,
                  title: 'Nike Air Max',
                  subtitle: 'Return window closes soon',
                  meta: 'Shopping · Sep 25 → Sep 29',
                  onTap: () => _openItem('Nike Air Max'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Coming up
          Padding(padding: pad, child: const _SectionHeader('COMING UP')),
          const SizedBox(height: 8),
          _HorizontalList(
            height: 112,
            children: [
              _MiniCard(
                icon: Icons.autorenew_rounded,
                bg: _C.blue,
                fg: _C.blueIcon,
                title: 'Adobe trial renews',
                category: 'Finance',
                onTap: () => _openItem('Adobe trial renews'),
              ),
              _MiniCard(
                icon: Icons.description_outlined,
                bg: _C.slate,
                fg: _C.slateIcon,
                title: 'School notice — Insert day',
                category: 'Family',
                onTap: () => _openItem('School notice'),
              ),
              // Sample card so the carousel shows a partial third card.
              _MiniCard(
                icon: Icons.shield_outlined,
                bg: _C.blue,
                fg: _C.blueIcon,
                title: 'Car insurance due',
                category: 'Finance',
                onTap: () => _openItem('Car insurance due'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Saved for later
          Padding(
            padding: pad,
            child: _SectionHeader('SAVED FOR LATER', 'Browse', _openBrowse),
          ),
          const SizedBox(height: 8),
          _HorizontalList(
            height: 112,
            children: [
              _MiniCard(
                icon: Icons.restaurant_outlined,
                bg: _C.blue,
                fg: _C.blueIcon,
                title: 'Dishoom',
                category: 'Travel',
                width: 140,
                onTap: () => _openItem('Dishoom'),
              ),
              _MiniCard(
                icon: Icons.headphones_outlined,
                bg: _C.peach,
                fg: _C.peachIcon,
                title: 'Sony WH-1000XM5',
                category: 'Shopping',
                width: 140,
                onTap: () => _openItem('Sony WH-1000XM5'),
              ),
              _MiniCard(
                icon: Icons.place_outlined,
                bg: _C.blue,
                fg: _C.blueIcon,
                title: 'Kyoto, Japan',
                category: 'Travel',
                width: 140,
                onTap: () => _openItem('Kyoto, Japan'),
              ),
              _MiniCard(
                icon: Icons.menu_book_outlined,
                bg: _C.slate,
                fg: _C.slateIcon,
                title: 'Thinking, Fast and Slow',
                category: 'Read & Watch',
                width: 140,
                onTap: () => _openItem('Thinking, Fast and Slow'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Collections
          Padding(
            padding: pad,
            child: _SectionHeader('COLLECTIONS', 'All', _openAllCollections),
          ),
          const SizedBox(height: 8),
          _HorizontalList(
            height: 132,
            children: [
              _CollectionCard(
                icon: Icons.temple_buddhist_outlined,
                bg: _C.blue,
                fg: _C.blueIcon,
                title: 'Japan Trip',
                items: '3 items',
                next: 'Next: Passport...',
                onTap: () => _openItem('Japan Trip'),
              ),
              _CollectionCard(
                icon: Icons.home_outlined,
                bg: _C.mint,
                fg: _C.mintIcon,
                title: 'New House',
                items: '2 items',
                next: 'Next: Home insurance...',
                onTap: () => _openItem('New House'),
              ),
              // Sample card so the carousel shows a partial third card.
              _CollectionCard(
                icon: Icons.card_giftcard_outlined,
                bg: _C.lavender,
                fg: _C.lavenderIcon,
                title: 'Birthday Gifts',
                items: '4 items',
                next: 'Next: Order flowers...',
                onTap: () => _openItem('Birthday Gifts'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Add anything
          Padding(
            padding: pad,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openAddAnything,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(
                  'Add anything',
                  style: _t(15, w: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.forest,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Capture it. Forget it.\nWell, almost.',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: _C.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.onTap,
    required this.background,
    required this.child,
    this.borderColor,
  });

  final VoidCallback onTap;
  final Color background;
  final Color? borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: CircleBorder(
        side: borderColor != null
            ? BorderSide(color: borderColor!)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Center(child: child)),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard(this.number, this.label, this.accent);

  final String number;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                number,
                style: _t(28, w: FontWeight.w800, height: 1, spacing: -0.5),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: _t(12.5, color: _C.muted)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, [this.action, this.onAction]);

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: _t(12, w: FontWeight.w700, color: _C.muted, spacing: 1.2),
          ),
          if (action != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(action!, style: _t(13, w: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, this.bg, this.fg, {this.size = 40});

  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: fg),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: _cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _IconBox(icon, bg, fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(14.5, w: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(12.5, color: _C.muted),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(11.5, color: _C.muted.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.nowBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'NOW',
                    style: _t(
                      10.5,
                      w: FontWeight.w800,
                      color: _C.nowText,
                      spacing: 0.6,
                    ),
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

class _HorizontalList extends StatelessWidget {
  const _HorizontalList({required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: children.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.category,
    required this.onTap,
    this.width = 150,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String category;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: _cardDecoration(),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBox(icon, bg, fg, size: 32),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(13, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(11.5, color: _C.muted),
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

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.items,
    required this.next,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String items;
  final String next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: fg),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(15, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(items, style: _t(11.5, color: _C.muted)),
                  const SizedBox(height: 4),
                  Text(
                    next,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(11.5, w: FontWeight.w600),
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

// ---------------------------------------------------------------------------
// Bottom navigation
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onTab,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;

  Widget _item(int i, IconData icon, IconData activeIcon, String label) {
    final active = index == i;
    final color = active ? _C.forest : _C.muted;
    return Expanded(
      child: InkWell(
        onTap: () => onTab(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: _t(
                11,
                w: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.navBg,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _item(1, Icons.inbox_outlined, Icons.inbox_rounded, 'Inbox'),
              Expanded(
                child: Center(
                  child: Material(
                    color: _C.forest,
                    shape: const CircleBorder(),
                    elevation: 3,
                    shadowColor: const Color(0x4016402B),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onAdd,
                      child: const SizedBox(
                        width: 54,
                        height: 54,
                        child: Icon(
                          Icons.add_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _item(2, Icons.explore_outlined, Icons.explore_rounded, 'Browse'),
              _item(
                3,
                Icons.settings_outlined,
                Icons.settings_rounded,
                'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: _t(22, w: FontWeight.w800)),
    );
  }
}

// ---------------------------------------------------------------------------
// Add anything sheet
// ---------------------------------------------------------------------------

class _AddAnythingSheet extends StatelessWidget {
  const _AddAnythingSheet();

  static const _items = <List<Object>>[
    [Icons.photo_camera_outlined, 'Photos'],
    [Icons.description_outlined, 'Documents'],
    [Icons.link_rounded, 'Links'],
    [Icons.menu_book_outlined, 'Notes'],
    [Icons.location_on_outlined, 'Places'],
    [Icons.lightbulb_outline_rounded, 'Ideas'],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Add anything',
              style: _t(24, w: FontWeight.w800, spacing: -0.5),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                for (final it in _items)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: open the capture flow for it[1]
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _IconBox(
                          it[0] as IconData,
                          _C.mint,
                          _C.forest,
                          size: 56,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          it[1] as String,
                          style: _t(12.5, w: FontWeight.w600),
                        ),
                      ],
                    ),
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

// ---------------------------------------------------------------------------
// Logo
// ---------------------------------------------------------------------------

class _NestLogoPainter extends CustomPainter {
  const _NestLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.5, s * 0.52), radius: s * 0.34),
      0.25,
      2.65,
      false,
      Paint()
        ..color = _C.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.13
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.22),
      s * 0.11,
      Paint()..color = _C.peachAccent,
    );
    canvas.drawCircle(
      Offset(s * 0.2, s * 0.4),
      s * 0.05,
      Paint()..color = _C.leaf,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
