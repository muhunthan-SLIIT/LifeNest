// ignore_for_file: file_names, deprecated_member_use
// lib/screens/nest_screen.dart
//
// LifeNest – "Nest" (Browse) screen
// Matches the screenshot: header + avatar, search pill, categories (4-col blob icons),
// two-row horizontally scrolling filters, collections grid, floating bottom nav.
//
// pubspec.yaml -> dependencies:
//   google_fonts: ^6.2.1
//
// Usage: home: const NestScreen()

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bottom_nav_bar.dart';

// ───────────────────────── Design tokens ─────────────────────────
class LN {
  static const cream = Color(0xFFFBF6EE); // page background
  static const card = Color(0xFFFFFDF9); // pills / cards
  static const forest = Color(0xFF1B5A38); // primary
  static const forestDark = Color(0xFF14382A); // headings
  static const muted = Color(0xFF6E7F73); // gray-green
  static const border = Color(0xFFE7E0D3);

  static const blue = Color(0xFFD7E9FA);
  static const blueIcon = Color(0xFF5E94C8);
  static const peach = Color(0xFFFDDCC8);
  static const peachIcon = Color(0xFFE8845A);
  static const beige = Color(0xFFF8EBD8);
  static const green = Color(0xFFD5E9D8);
  static const greenIcon = Color(0xFF2E6B45);
  static const lavender = Color(0xFFEBE0F9);
  static const lavenderIcon = Color(0xFF8C73B8);
  static const yellow = Color(0xFFFBEFC9);
  static const softOrange = Color(0xFFFBE6D3);

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = forestDark,
    double? spacing,
    double? height,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

// ───────────────────────── Data ─────────────────────────
class _Category {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  const _Category(this.label, this.icon, this.bg, this.fg);
}

const _categories = <_Category>[
  _Category('Travel', Icons.flight_rounded, LN.blue, LN.blueIcon),
  _Category('Purchases', Icons.shopping_bag_outlined, LN.peach, LN.peachIcon),
  _Category('Documents', Icons.description_outlined, LN.beige, LN.forestDark),
  _Category(
    'Bills',
    Icons.account_balance_wallet_outlined,
    LN.green,
    LN.greenIcon,
  ),
  _Category('Family', Icons.people_outline_rounded, LN.peach, LN.peachIcon),
  _Category(
    'Screenshots',
    Icons.smartphone_rounded,
    LN.lavender,
    LN.lavenderIcon,
  ),
  _Category(
    'Appointments',
    Icons.calendar_month_outlined,
    LN.lavender,
    LN.lavenderIcon,
  ),
  _Category(
    'Ideas',
    Icons.lightbulb_outline_rounded,
    LN.softOrange,
    LN.peachIcon,
  ),
  _Category(
    'Vehicle/Home',
    Icons.directions_car_outlined,
    LN.blue,
    LN.blueIcon,
  ),
  _Category('Lists', Icons.checklist_rounded, LN.green, LN.greenIcon),
];

// Slightly different "blob" corner radii so icons feel organic, like the design.
const _blobRadii = <BorderRadius>[
  BorderRadius.only(
    topLeft: Radius.circular(26),
    topRight: Radius.circular(20),
    bottomRight: Radius.circular(28),
    bottomLeft: Radius.circular(22),
  ),
  BorderRadius.only(
    topLeft: Radius.circular(22),
    topRight: Radius.circular(28),
    bottomRight: Radius.circular(20),
    bottomLeft: Radius.circular(26),
  ),
  BorderRadius.only(
    topLeft: Radius.circular(28),
    topRight: Radius.circular(22),
    bottomRight: Radius.circular(26),
    bottomLeft: Radius.circular(20),
  ),
  BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(26),
    bottomRight: Radius.circular(22),
    bottomLeft: Radius.circular(28),
  ),
];

const _filtersRow1 = ['Remember', 'Do', 'Be There', 'Buy', 'Go', 'Contact'];
const _filtersRow2 = ['Now', 'Soon', 'Later', 'Someday', 'Done', 'Expired'];

class _Collection {
  final String title;
  final String count;
  final String? next;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _Collection(
    this.title,
    this.count,
    this.next,
    this.bg,
    this.fg,
    this.icon,
  );
}

const _collections = <_Collection>[
  _Collection(
    'Japan Trip',
    '3 items',
    'Next: Passport renewal...',
    LN.blue,
    LN.blueIcon,
    Icons.flight_takeoff_rounded,
  ),
  _Collection(
    'New House',
    '2 items',
    'Next: Home insurance...',
    LN.green,
    LN.greenIcon,
    Icons.home_outlined,
  ),
  _Collection(
    'Reading',
    '1 item',
    null,
    LN.peach,
    LN.peachIcon,
    Icons.menu_book_outlined,
  ),
  _Collection(
    'Emma\'s Birthday',
    '2 items',
    null,
    LN.lavender,
    LN.lavenderIcon,
    Icons.card_giftcard_rounded,
  ),
];

// ───────────────────────── Screen ─────────────────────────
class NestScreen extends StatelessWidget {
  const NestScreen({super.key});

  static const double _hPad = 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LN.cream,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _hPad),
                child: _Header(),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _hPad),
                child: _SearchBar(),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad + 4),
                child: GestureDetector(
                  onTap: () => debugPrint('Open full search'),
                  child: Text(
                    'Open full search →',
                    style: LN.text(13.5, color: LN.forest),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('CATEGORIES'),
              const SizedBox(height: 14),
              const _CategoryGrid(),
              const SizedBox(height: 28),
              const _SectionLabel('FILTERS'),
              const SizedBox(height: 14),
              const _FilterRows(),
              const SizedBox(height: 30),
              _SectionLabel(
                'COLLECTIONS',
                trailing: 'All',
                onTrailingTap: () => debugPrint('All collections'),
              ),
              const SizedBox(height: 14),
              const _CollectionsGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const LifeNestNavBar(
        currentTab: 2,
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nest',
                style: LN.text(34, weight: FontWeight.w800, spacing: -0.8),
              ),
              const SizedBox(height: 4),
              Text(
                'Everything you\'ve kept, gently sorted.',
                style: LN.text(14.5, weight: FontWeight.w400, color: LN.muted),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => debugPrint('Profile'),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: LN.forest,
              shape: BoxShape.circle,
            ),
            child: Text(
              'A',
              style: LN.text(18, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Search ─────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => debugPrint('Open search'),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: LN.card,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14382A).withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 24, color: LN.muted),
            const SizedBox(width: 14),
            Text(
              'Search your LifeNest',
              style: LN.text(
                16.5,
                weight: FontWeight.w400,
                color: const Color(0xFF8A968D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Section label ─────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  const _SectionLabel(this.title, {this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: LN.text(
              12.5,
              weight: FontWeight.w700,
              color: LN.muted,
              spacing: 1.6,
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing!,
                style: LN.text(13, weight: FontWeight.w600, color: LN.forest),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Categories ─────────────────────────
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, c) {
          final itemW = c.maxWidth / 4;
          return Wrap(
            runSpacing: 16,
            children: [
              for (int i = 0; i < _categories.length; i++)
                SizedBox(
                  width: itemW,
                  child: _CategoryItem(cat: _categories[i], index: i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final _Category cat;
  final int index;
  const _CategoryItem({required this.cat, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => debugPrint('Category: ${cat.label}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cat.bg,
              borderRadius: _blobRadii[index % _blobRadii.length],
            ),
            child: Icon(cat.icon, size: 24, color: cat.fg),
          ),
          const SizedBox(height: 8),
          Text(
            cat.label,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            textAlign: TextAlign.center,
            style: LN.text(13, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Filters ─────────────────────────
class _FilterRows extends StatelessWidget {
  const _FilterRows();

  @override
  Widget build(BuildContext context) {
    // One scroll view for both rows so they scroll together (like the screenshot).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chipRow(_filtersRow1),
          const SizedBox(height: 12),
          _chipRow(_filtersRow2),
        ],
      ),
    );
  }

  Widget _chipRow(List<String> labels) => Row(
    children: [
      for (final l in labels)
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _FilterChip(label: l),
        ),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LN.card,
      shape: const StadiumBorder(side: BorderSide(color: LN.border, width: 1)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => debugPrint('Filter: $label'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(
            label,
            style: LN.text(
              15,
              weight: FontWeight.w500,
              color: const Color(0xFF5E6E63),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Collections ─────────────────────────
class _CollectionsGrid extends StatelessWidget {
  const _CollectionsGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 14.0;
          final w = (c.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final col in _collections)
                SizedBox(
                  width: w,
                  child: _CollectionCard(data: col),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final _Collection data;
  const _CollectionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => debugPrint('Collection: ${data.title}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: LN.border.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14382A).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 84,
              width: double.infinity,
              color: data.bg,
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(14),
              child: Icon(data.icon, size: 30, color: data.fg),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LN.text(15.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.count,
                    style: LN.text(
                      12.5,
                      weight: FontWeight.w400,
                      color: LN.muted,
                    ),
                  ),
                  if (data.next != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      data.next!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LN.text(12, color: LN.forest),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


