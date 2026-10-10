// LifeNest "Add Anything" capture screen + item details form.
// ignore_for_file: deprecated_member_use, unused_element

import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

class _C {
  static const bg = Color(0xFFFBF7EF);
  static const forest = Color(0xFF195A3B);
  static const card = Color(0xFFFFFEFC);
  static const text = Color(0xFF12301F);
  static const muted = Color(0xFF6B7F73);
  static const border = Color(0xFFE9E3D6);
  static const dash = Color(0xFFD9D0BC);
  static const danger = Color(0xFFC0392B);
}

class _Tile {
  const _Tile(this.bg, this.fg);
  final Color bg;
  final Color fg;

  static const mint = _Tile(Color(0xFFDCEEDF), Color(0xFF2F6B4A));
  static const sky = _Tile(Color(0xFFDDEFFC), Color(0xFF3D78B5));
  static const lavender = _Tile(Color(0xFFF0E5FC), Color(0xFF8A7BC0));
  static const peach = _Tile(Color(0xFFFFDFCF), Color(0xFFE9774F));
  static const beige = _Tile(Color(0xFFFBF0DE), Color(0xFF6B5B45));
}

TextStyle _t(
  double size, {
  FontWeight w = FontWeight.w500,
  Color color = _C.text,
  double? height,
  double? spacing,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: w,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

List<BoxShadow> get _softShadow => const [
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ];

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

enum CaptureKind { photo, file, link, voice, note, list }

extension on CaptureKind {
  IconData get icon => switch (this) {
        CaptureKind.photo => Icons.image_outlined,
        CaptureKind.file => Icons.description_outlined,
        CaptureKind.link => Icons.link_rounded,
        CaptureKind.voice => Icons.mic_none_rounded,
        CaptureKind.note => Icons.edit_outlined,
        CaptureKind.list => Icons.checklist_rounded,
      };
  _Tile get tile => switch (this) {
        CaptureKind.photo => _Tile.sky,
        CaptureKind.file => _Tile.beige,
        CaptureKind.link => _Tile.lavender,
        CaptureKind.voice => _Tile.peach,
        CaptureKind.note => _Tile.mint,
        CaptureKind.list => _Tile.beige,
      };
}

class ListEntry {
  ListEntry(this.text, {this.done = false});
  String text;
  bool done;
}

class CaptureData {
  CaptureData({
    required this.kind,
    this.name,
    this.bytes,
    this.size,
    this.url,
    this.voiceSeconds = 0,
  });

  final CaptureKind kind;
  final String? name;
  final Uint8List? bytes;
  final int? size;
  final String? url;
  final int voiceSeconds;
}

class AddedItem {
  AddedItem({
    required this.kind,
    required this.title,
    this.notes = '',
    this.category,
    this.collection,
    this.tags = const [],
    this.date,
    this.reminderAt,
    this.url,
    this.fileName,
    this.bytes,
    this.voiceSeconds,
    this.listItems = const [],
  });

  final CaptureKind kind;
  final String title;
  final String notes;
  final String? category; // null = Uncategorized
  final String? collection;
  final List<String> tags;
  final DateTime? date;
  final DateTime? reminderAt;
  final String? url;
  final String? fileName;
  final Uint8List? bytes;
  final int? voiceSeconds;
  final List<ListEntry> listItems;
}

class _Category {
  const _Category(this.name, this.icon, this.tile, this.description);
  final String name;
  final IconData icon;
  final _Tile tile;
  final String description;
}

const _categories = <_Category>[
  _Category(
    'Travel',
    Icons.flight_rounded,
    _Tile.sky,
    'Tickets, hotel bookings, itineraries, IDs',
  ),
  _Category(
    'Purchases',
    Icons.shopping_bag_outlined,
    _Tile.peach,
    'Receipts, invoices, warranty cards, products',
  ),
  _Category(
    'Documents',
    Icons.description_outlined,
    _Tile(Color(0xFFFBF0DE), Color(0xFF195A3B)),
    'IDs, insurance, certificates, policies',
  ),
  _Category(
    'Bills',
    Icons.account_balance_wallet_outlined,
    _Tile.mint,
    'Bills, subscriptions, payment reminders',
  ),
  _Category(
    'Family',
    Icons.people_outline_rounded,
    _Tile.peach,
    'School info, family documents, medical',
  ),
  _Category(
    'Screenshots',
    Icons.smartphone_rounded,
    _Tile.lavender,
    'Products, places, information, social posts',
  ),
  _Category(
    'Appointments',
    Icons.calendar_month_outlined,
    _Tile.lavender,
    'Doctor, service, meetings, events',
  ),
  _Category(
    'Ideas',
    Icons.lightbulb_outline_rounded,
    _Tile(Color(0xFFFBF0DE), Color(0xFFE9774F)),
    'WhatsApp links, Instagram finds, websites, notes',
  ),
  _Category(
    'Vehicle/Home',
    Icons.directions_car_outlined,
    _Tile.sky,
    'Insurance, service records, warranties, bills',
  ),
  _Category(
    'Lists',
    Icons.checklist_rounded,
    _Tile.mint,
    'Shopping list, action list, to-do',
  ),
];

const _collectionNames = ['Japan Trip', 'New House', 'Birthday Gifts'];

const _imageExt = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'gif'};
const _allowedExt = [
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
  'gif',
  'pdf',
  'doc',
  'docx',
  'txt',
  'xls',
  'xlsx',
];
const _maxBytes = 25 * 1024 * 1024; // 25 MB

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatDuration(int s) =>
    '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

const _monthNames = [
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

String _formatDate(DateTime d) =>
    '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

String? _normalizeUrl(String input) {
  var s = input.trim();
  if (s.isEmpty || s.contains(' ')) return null;
  if (!s.contains('://')) s = 'https://$s';
  final u = Uri.tryParse(s);
  if (u == null ||
      !(u.scheme == 'http' || u.scheme == 'https') ||
      !u.host.contains('.')) {
    return null;
  }
  return s;
}

// ---------------------------------------------------------------------------
// Add Anything screen
// ---------------------------------------------------------------------------

class AddAnythingScreen extends StatefulWidget {
  const AddAnythingScreen({super.key, this.onSave});

  /// Persist the item (API / database). Throw to show a "couldn't save" error.
  final Future<void> Function(AddedItem item)? onSave;

  static Future<AddedItem?> open(
    BuildContext context, {
    Future<void> Function(AddedItem item)? onSave,
  }) {
    return Navigator.of(context).push<AddedItem>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddAnythingScreen(onSave: onSave),
      ),
    );
  }

  @override
  State<AddAnythingScreen> createState() => _AddAnythingScreenState();
}

class _AddAnythingScreenState extends State<AddAnythingScreen> {
  CaptureData? _data;
  String? _category;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  // --- Capture methods ------------------------------------------------------

  bool _accept(CaptureData d) {
    if ((d.size ?? 0) > _maxBytes) {
      _snack('That file is too large. The limit is 25 MB.');
      return false;
    }
    setState(() => _data = d);
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: source, maxWidth: 2400, imageQuality: 85);
      if (x == null) return; // cancelled
      final bytes = await x.readAsBytes();
      _accept(CaptureData(
        kind: CaptureKind.photo,
        name: x.name,
        bytes: bytes,
        size: bytes.length,
      ));
    } catch (_) {
      _snack(source == ImageSource.camera
          ? "Couldn't open the camera. Check that camera access is allowed."
          : "Couldn't open your photos. Check that photo access is allowed.");
    }
  }

  Future<void> _pickFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExt,
      );
      if (files.isEmpty) return; // cancelled
      final f = files.first;
      final ext = (f.extension ?? '').toLowerCase();
      if (!_allowedExt.contains(ext)) {
        _snack('That file type is not supported.');
        return;
      }
      final bytes = await f.readAsBytes();
      final size = await f.length() ?? bytes.length;
      _accept(CaptureData(
        kind: _imageExt.contains(ext) ? CaptureKind.photo : CaptureKind.file,
        name: f.name,
        bytes: bytes,
        size: size,
      ));
    } catch (_) {
      _snack("Couldn't open the file picker. Please try again.");
    }
  }

  Future<void> _addLink() async {
    final url = await showDialog<String>(
      context: context,
      builder: (_) => const _LinkDialog(),
    );
    if (url == null) return;
    _accept(CaptureData(kind: CaptureKind.link, url: url));
  }

  Future<void> _recordVoice() async {
    final seconds = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _C.bg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _VoiceSheet(),
    );
    if (seconds == null || seconds <= 0) return;
    _accept(CaptureData(kind: CaptureKind.voice, voiceSeconds: seconds));
  }

  void _startNote(CaptureKind kind) {
    setState(() => _data = CaptureData(kind: kind));
    _openDetails(_category);
  }

  void _replace() {
    switch (_data?.kind) {
      case CaptureKind.photo:
        _pickImage(ImageSource.gallery);
      case CaptureKind.file:
        _pickFile();
      case CaptureKind.link:
        _addLink();
      case CaptureKind.voice:
        _recordVoice();
      default:
        _openDetails(_category);
    }
  }

  // --- Navigation -----------------------------------------------------------

  Future<void> _openDetails(String? category) async {
    final data = _data ?? CaptureData(kind: CaptureKind.note);
    final saved = await Navigator.of(context).push<AddedItem>(
      MaterialPageRoute(
        builder: (_) => _DetailsScreen(
          data: data,
          initialCategory: category,
          onSave: widget.onSave,
        ),
      ),
    );
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  void _selectCategory(String name) {
    setState(() => _category = name);
    _openDetails(name);
  }

  Future<void> _close() async {
    if (_data == null) {
      Navigator.of(context).maybePop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        title: Text('Discard this capture?', style: _t(18, w: FontWeight.w800)),
        content: Text("What you've added won't be saved.",
            style: _t(14, color: _C.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: _C.danger)),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final hPad = c.maxWidth < 360 ? 16.0 : 20.0;
            final inner = c.maxWidth - hPad * 2;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Text(
                    'Capture today.\nA calmer tomorrow.',
                    style: GoogleFonts.caveat(
                      fontSize: 36,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: _C.forest,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Send a photo, screenshot, document, link, note or voice. "
                    "We'll keep it safe and remind you when it matters.",
                    style: _t(16, color: _C.muted, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  _UploadZone(onTap: _pickFile),
                  if (_data != null) ...[
                    const SizedBox(height: 16),
                    _buildSelection(),
                  ],
                  const SizedBox(height: 20),
                  _buildQuickGrid(inner),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'WHAT ARE YOU SAVING?',
                      style: _t(
                        13,
                        w: FontWeight.w700,
                        color: _C.muted,
                        spacing: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildCategoryGrid(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'Close',
              child: Material(
                color: _C.card,
                shape: const CircleBorder(),
                elevation: 1.5,
                shadowColor: const Color(0x22000000),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _close,
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child:
                        Icon(Icons.close_rounded, size: 24, color: _C.forest),
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Add Anything',
            style: _t(18, w: FontWeight.w800, spacing: -0.3),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _Tile.mint.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: _C.forest,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Private',
                    style: _t(13, w: FontWeight.w600, color: _C.forest),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelection() {
    final d = _data!;
    final String primary;
    final String secondary;
    switch (d.kind) {
      case CaptureKind.photo:
      case CaptureKind.file:
        primary = d.name ?? 'Selected file';
        secondary = d.size != null ? _formatSize(d.size!) : 'Ready to save';
      case CaptureKind.link:
        primary = d.url ?? 'Link';
        secondary = 'Link';
      case CaptureKind.voice:
        primary = 'Voice note';
        secondary = _formatDuration(d.voiceSeconds);
      case CaptureKind.note:
        primary = 'Note';
        secondary = 'Ready to save';
      case CaptureKind.list:
        primary = 'List';
        secondary = 'Ready to save';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: _softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (d.kind == CaptureKind.photo && d.bytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(
                    d.bytes!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else
                _Blob(d.kind.icon, d.kind.tile, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(15, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(secondary, style: _t(12.5, color: _C.muted)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Replace',
                onPressed: _replace,
                icon: const Icon(Icons.swap_horiz_rounded, color: _C.muted),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: () => setState(() => _data = null),
                icon: const Icon(Icons.close_rounded, color: _C.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => _openDetails(_category),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.forest,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Add details →',
                style: _t(14.5, w: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGrid(double inner) {
    final methods = <(String, IconData, _Tile, VoidCallback)>[
      (
        'Camera',
        Icons.photo_camera_outlined,
        _Tile.mint,
        () => _pickImage(ImageSource.camera),
      ),
      (
        'Gallery',
        Icons.image_outlined,
        _Tile.sky,
        () => _pickImage(ImageSource.gallery),
      ),
      ('File', Icons.description_outlined, _Tile.beige, _pickFile),
      ('Link', Icons.link_rounded, _Tile.lavender, _addLink),
      ('Voice', Icons.mic_none_rounded, _Tile.peach, _recordVoice),
      (
        'Note',
        Icons.edit_outlined,
        _Tile.mint,
        () => _startNote(CaptureKind.note),
      ),
      (
        'List',
        Icons.checklist_rounded,
        _Tile.beige,
        () => _startNote(CaptureKind.list),
      ),
    ];

    const gap = 10.0;
    final cols = inner >= 320 ? 4 : 3;
    final cardW = (inner - gap * (cols - 1)) / cols;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final m in methods)
          SizedBox(
            width: cardW,
            child: _QuickCard(
              label: m.$1,
              icon: m.$2,
              tile: m.$3,
              onTap: m.$4,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final rows = <Widget>[];
    for (var i = 0; i < _categories.length; i += 2) {
      final a = _categories[i];
      final b = i + 1 < _categories.length ? _categories[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CategoryCard(
                  category: a,
                  selected: _category == a.name,
                  onTap: () => _selectCategory(a.name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: b == null
                    ? const SizedBox.shrink()
                    : _CategoryCard(
                        category: b,
                        selected: _category == b.name,
                        onTap: () => _selectCategory(b.name),
                      ),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < _categories.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

// ---------------------------------------------------------------------------
// Reusable pieces
// ---------------------------------------------------------------------------

class _Blob extends StatelessWidget {
  const _Blob(this.icon, this.tile, {this.size = 52});

  final IconData icon;
  final _Tile tile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tile.bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.40),
          topRight: Radius.circular(size * 0.46),
          bottomRight: Radius.circular(size * 0.36),
          bottomLeft: Radius.circular(size * 0.46),
        ),
      ),
      child: Icon(icon, size: size * 0.42, color: tile.fg),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tap to add or drop here',
      child: CustomPaint(
        foregroundPainter:
            const _DashedRRectPainter(color: _C.dash, radius: 36),
        child: Material(
          color: _C.card,
          borderRadius: BorderRadius.circular(36),
          child: InkWell(
            borderRadius: BorderRadius.circular(36),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const _Blob(
                      Icons.cloud_upload_outlined,
                      _Tile.mint,
                      size: 80,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Tap to add or drop here',
                      textAlign: TextAlign.center,
                      style: _t(18, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Photos, screenshots, documents, links,\nnotes, voice...',
                      textAlign: TextAlign.center,
                      style: _t(13.5, color: _C.muted, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.label,
    required this.icon,
    required this.tile,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final _Tile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(32),
          boxShadow: _softShadow,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tile.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: tile.fg),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(13, w: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? _C.forest : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: _softShadow,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Blob(category.icon, category.tile, size: 48),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(15.5, w: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: _t(12, color: _C.muted, height: 1.3),
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

// ---------------------------------------------------------------------------
// Link dialog
// ---------------------------------------------------------------------------

class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _normalizeUrl(_ctrl.text);
    if (url == null) {
      setState(() => _error = 'Enter a valid link, like example.com');
      return;
    }
    Navigator.pop(context, url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _C.card,
      title: Text('Add a link', style: _t(18, w: FontWeight.w800)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          hintText: 'https://',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Voice sheet
// ---------------------------------------------------------------------------

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet();

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  Timer? _timer;
  int _seconds = 0;
  bool _recording = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_recording) {
      _timer?.cancel();
      setState(() => _recording = false);
      return;
    }
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds >= 600) {
        t.cancel();
        setState(() => _recording = false);
        return;
      }
      setState(() => _seconds++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canUse = !_recording && _seconds > 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voice note', style: _t(20, w: FontWeight.w800)),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: _recording ? 'Stop recording' : 'Start recording',
              child: GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _recording ? _C.forest : _Tile.peach.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _recording ? Icons.stop_rounded : Icons.mic_none_rounded,
                    size: 38,
                    color: _recording ? Colors.white : _Tile.peach.fg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _formatDuration(_seconds),
              style: _t(28, w: FontWeight.w800, color: _C.forest),
            ),
            const SizedBox(height: 4),
            Text(
              _recording
                  ? 'Recording…'
                  : (_seconds > 0 ? 'Tap to re-record' : 'Tap to record'),
              style: _t(13.5, color: _C.muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                    canUse ? () => Navigator.pop(context, _seconds) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.forest,
                  disabledBackgroundColor: _C.border,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Use recording',
                  style: _t(15, w: FontWeight.w700, color: Colors.white),
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
// Details form
// ---------------------------------------------------------------------------

class _DetailsScreen extends StatefulWidget {
  const _DetailsScreen({
    required this.data,
    required this.initialCategory,
    required this.onSave,
  });

  final CaptureData data;
  final String? initialCategory;
  final Future<void> Function(AddedItem item)? onSave;

  @override
  State<_DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<_DetailsScreen> {
  late final TextEditingController _title;
  final _notes = TextEditingController();
  final _tags = TextEditingController();
  final _newEntry = TextEditingController();
  late final TextEditingController _url;

  String? _category;
  String? _collection;
  DateTime? _date;
  bool _remind = false;
  DateTime? _reminderAt;
  final List<ListEntry> _entries = [];

  String? _titleError;
  String? _urlError;
  bool _saving = false;

  Timer? _playTimer;
  bool _playing = false;
  int _pos = 0;

  CaptureKind get _kind => widget.data.kind;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _title = TextEditingController(text: _defaultTitle());
    _url = TextEditingController(text: widget.data.url ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _tags.dispose();
    _newEntry.dispose();
    _url.dispose();
    _playTimer?.cancel();
    super.dispose();
  }

  String _defaultTitle() {
    final d = widget.data;
    switch (d.kind) {
      case CaptureKind.photo:
      case CaptureKind.file:
        final n = d.name ?? '';
        final dot = n.lastIndexOf('.');
        return dot > 0 ? n.substring(0, dot) : n;
      case CaptureKind.link:
        return Uri.tryParse(d.url ?? '')?.host ?? '';
      case CaptureKind.voice:
        return 'Voice note';
      case CaptureKind.note:
        return '';
      case CaptureKind.list:
        return 'New list';
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _togglePlay() {
    if (_playing) {
      _playTimer?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_pos >= widget.data.voiceSeconds) _pos = 0;
    setState(() => _playing = true);
    _playTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_pos + 1 >= widget.data.voiceSeconds) {
        t.cancel();
        setState(() {
          _pos = widget.data.voiceSeconds;
          _playing = false;
        });
        return;
      }
      setState(() => _pos++);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final base = _reminderAt ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (time == null) return;
    setState(() => _reminderAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _addEntry() {
    final text = _newEntry.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _entries.add(ListEntry(text));
      _newEntry.clear();
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    String? url;
    setState(() {
      _titleError = title.isEmpty ? 'Please add a title' : null;
      _urlError = null;
    });

    if (_kind == CaptureKind.link) {
      url = _normalizeUrl(_url.text);
      if (url == null) {
        setState(
          () => _urlError = 'Enter a valid link, like https://example.com',
        );
        return;
      }
    }
    if (title.isEmpty) return;

    if (_remind && _reminderAt == null) {
      _snack('Choose a reminder date and time.');
      return;
    }
    if (_remind && _reminderAt!.isBefore(DateTime.now())) {
      _snack('Pick a reminder time in the future.');
      return;
    }

    final item = AddedItem(
      kind: _kind,
      title: title,
      notes: _notes.text.trim(),
      category: _category,
      collection: _collection,
      tags: _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      date: _date,
      reminderAt: _remind ? _reminderAt : null,
      url: url,
      fileName: widget.data.name,
      bytes: widget.data.bytes,
      voiceSeconds:
          _kind == CaptureKind.voice ? widget.data.voiceSeconds : null,
      listItems: List.of(_entries),
    );

    setState(() => _saving = true);
    try {
      if (widget.onSave != null) {
        await widget.onSave!(item);
      } else {
        await Future.delayed(const Duration(milliseconds: 600)); // preview
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _snack("Couldn't save. Please try again.");
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SuccessDialog(),
    );
    if (mounted) Navigator.of(context).pop(item);
  }

  InputDecoration _decoration(String hint, {String? error}) => InputDecoration(
        hintText: hint,
        hintStyle: _t(14.5, color: _C.muted),
        errorText: error,
        filled: true,
        fillColor: _C.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: _outline(_C.border),
        enabledBorder: _outline(_C.border),
        focusedBorder: _outline(_C.forest, 1.4),
        errorBorder: _outline(_C.danger),
        focusedErrorBorder: _outline(_C.danger, 1.4),
      );

  OutlineInputBorder _outline(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: c, width: w),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 22),
        child: Text(
          text,
          style: _t(12, w: FontWeight.w700, color: _C.muted, spacing: 1.2),
        ),
      );

  Widget _buildPlayer() {
    final total = widget.data.voiceSeconds;
    final progress = total > 0 ? (_pos / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Tile.peach.bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: _C.forest,
              foregroundColor: Colors.white,
            ),
            icon: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            onPressed: _togglePlay,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.6),
                    valueColor: const AlwaysStoppedAnimation<Color>(_C.forest),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_pos),
                      style: _t(12, color: _C.forest, w: FontWeight.w700),
                    ),
                    Text(
                      _formatDuration(total),
                      style: _t(12, color: _C.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListEditor() {
    return Column(
      children: [
        for (var i = 0; i < _entries.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _entries[i].done,
                  activeColor: _C.forest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (v) {
                    setState(() => _entries[i].done = v ?? false);
                  },
                ),
                Expanded(
                  child: Text(
                    _entries[i].text,
                    style: _t(
                      14,
                      color: _entries[i].done ? _C.muted : _C.text,
                      w: FontWeight.w600,
                    ).copyWith(
                      decoration:
                          _entries[i].done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close_rounded, size: 18, color: _C.muted),
                  onPressed: () {
                    setState(() => _entries.removeAt(i));
                  },
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newEntry,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _addEntry(),
                decoration: _decoration('Add a list item…'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: _C.forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              onPressed: _addEntry,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final dateText = _date == null ? null : _formatDate(_date!);

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: _C.card,
                    shape: const CircleBorder(
                      side: BorderSide(color: _C.border),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 26,
                          color: _C.forest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Item details',
                    style: _t(22, w: FontWeight.w800, spacing: -0.4),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_kind == CaptureKind.photo && d.bytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.memory(
                    d.bytes!,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_kind == CaptureKind.file)
                _InfoTile(
                  icon: Icons.description_outlined,
                  tile: _Tile.beige,
                  title: d.name ?? 'File',
                  subtitle: d.size != null ? _formatSize(d.size!) : '',
                ),
              if (_kind == CaptureKind.voice) _buildPlayer(),

              if (_kind == CaptureKind.link) ...[
                _label('LINK'),
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: _decoration('https://', error: _urlError),
                ),
              ],

              _label('TITLE'),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
                decoration: _decoration('Give it a name', error: _titleError),
              ),

              _label(_kind == CaptureKind.note ? 'NOTE' : 'NOTES'),
              TextField(
                controller: _notes,
                minLines: _kind == CaptureKind.note ? 6 : 3,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  _kind == CaptureKind.note
                      ? 'Write your note…'
                      : 'Add a description or notes',
                ),
              ),

              if (_kind == CaptureKind.list) ...[
                _label('LIST ITEMS'),
                _buildListEditor(),
              ],

              _label('CATEGORY'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CategoryChip(
                    'Uncategorized',
                    _category == null,
                    () => setState(() => _category = null),
                  ),
                  for (final c in _categories)
                    _CategoryChip(
                      c.name,
                      _category == c.name,
                      () => setState(() => _category = c.name),
                    ),
                ],
              ),

              _label('COLLECTION (OPTIONAL)'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _collection,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: _C.card,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _C.muted,
                    ),
                    hint: Text('None', style: _t(14.5, color: _C.muted)),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None', style: _t(14.5)),
                      ),
                      for (final n in _collectionNames)
                        DropdownMenuItem<String?>(
                          value: n,
                          child: Text(n, style: _t(14.5)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _collection = v),
                  ),
                ),
              ),

              _label('TAGS (OPTIONAL)'),
              TextField(
                controller: _tags,
                decoration: _decoration('e.g. flights, october'),
              ),

              _label('DATE OR DEADLINE (OPTIONAL)'),
              _PickerRow(
                icon: Icons.calendar_today_outlined,
                text: dateText ?? 'No date',
                active: dateText != null,
                onTap: _pickDate,
                onClear: dateText == null
                    ? null
                    : () => setState(() => _date = null),
              ),

              _label('REMINDER (OPTIONAL)'),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 4, 10, 4),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: _C.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Remind me', style: _t(14.5))),
                    Switch(
                      value: _remind,
                      activeColor: Colors.white,
                      activeTrackColor: _C.forest,
                      onChanged: (v) {
                        setState(() => _remind = v);
                        if (v && _reminderAt == null) _pickReminder();
                      },
                    ),
                  ],
                ),
              ),
              if (_remind) ...[
                const SizedBox(height: 8),
                _PickerRow(
                  icon: Icons.schedule_rounded,
                  text: _reminderAt == null
                      ? 'Choose date and time'
                      : '${_formatDate(_reminderAt!)} · '
                          '${TimeOfDay.fromDateTime(_reminderAt!).format(context)}',
                  active: _reminderAt != null,
                  onTap: _pickReminder,
                  onClear: _reminderAt == null
                      ? null
                      : () => setState(() => _reminderAt = null),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.forest,
                    disabledBackgroundColor: _C.border,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save item →',
                          style: _t(16, w: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers for details screen
// ---------------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.label, this.selected, this.onTap);

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: _C.card,
      selectedColor: _Tile.mint.bg,
      checkmarkColor: _C.forest,
      labelStyle: _t(
        13.5,
        w: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? _C.forest : _C.text,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? _C.forest : _C.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.text,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String text;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: active ? _C.forest : _C.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: _t(
                    14.5,
                    w: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _C.text : _C.muted,
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _C.muted,
                  ),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: _C.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.tile,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final _Tile tile;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          _Blob(icon, tile, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(15, w: FontWeight.w700),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: _t(12.5, color: _C.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFDCEEDF),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_rounded, color: _C.forest, size: 36),
            ),
            const SizedBox(height: 18),
            Text('Saved to LifeNest', style: _t(20, w: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Your item is safely stored and organized.',
              textAlign: TextAlign.center,
              style: _t(14, color: _C.muted, height: 1.4),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.forest,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: _t(15, w: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
