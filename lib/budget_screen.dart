// LifeNest Family Budget screen (Overview / Expenses / Income / Trends / Plan)
// Save as lib/budget_screen.dart. Requires only google_fonts.
//
// Usage:
//   BudgetScreen(
//     onHome: () => ..., onFocus: () => ..., onNest: () => ...,
//     onAdd: () => ..., // optional: your global "Add Anything"; defaults to
//                       // the add-transaction form
//   )
//
// All totals, percentages and bars are calculated from the data in
// _BudgetStore. Replace the sample data in _seed() with your real storage.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

class _C {
  static const bg = Color(0xFFFBF7EF);
  static const forest = Color(0xFF195A3B);
  static const card = Color(0xFFFFFEFC);
  static const text = Color(0xFF12301F);
  static const muted = Color(0xFF6B7F73);
  static const sage = Color(0xFFECEFE1);
  static const divider = Color(0xFFEDE9DD);
  static const peach = Color(0xFFFFDFCF);
  static const mint = Color(0xFFDCEEDF);
  static const coral = Color(0xFFE8825F);
  static const coralText = Color(0xFFD9532F);
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

TextStyle _script(double size, {Color color = _C.muted}) => GoogleFonts.caveat(
  fontSize: size,
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.w500,
  color: color,
);

const _softShadow = [
  BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 4)),
];

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _monthTitle(DateTime m) => '${_monthNames[m.month - 1]} ${m.year}';
String _monthShort(DateTime m) => _monthNames[m.month - 1].substring(0, 3);
String _dayMonth(DateTime d) => '${d.day} ${_monthShort(d)}';

// ---------------------------------------------------------------------------
// Currency
// ---------------------------------------------------------------------------

class _Currency {
  const _Currency(this.code, this.symbol, this.name, {this.decimals = 2});
  final String code;
  final String symbol;
  final String name;
  final int decimals;
}

const _currencies = [
  _Currency('USD', r'$', 'US Dollar'),
  _Currency('EUR', '€', 'Euro'),
  _Currency('GBP', '£', 'British Pound'),
  _Currency('INR', '₹', 'Indian Rupee'),
  _Currency('LKR', 'Rs', 'Sri Lankan Rupee'),
  _Currency('AUD', r'A$', 'Australian Dollar'),
  _Currency('CAD', r'C$', 'Canadian Dollar'),
  _Currency('JPY', '¥', 'Japanese Yen', decimals: 0),
];

String _group(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Symbol-only formatting (no FX conversion).
String _money(_Currency c, double v, {int decimals = 0}) {
  final d = c.decimals == 0 ? 0 : decimals;
  final fixed = v.abs().toStringAsFixed(d).split('.');
  final whole = _group(int.parse(fixed[0]));
  final frac = d > 0 ? '.${fixed[1]}' : '';
  return '${v < 0 ? '-' : ''}${c.symbol}$whole$frac';
}

String _short(_Currency c, double v) =>
    v >= 1000 ? '${c.symbol}${(v / 1000).toStringAsFixed(1)}k' : _money(c, v);

// ---------------------------------------------------------------------------
// Model + store
// ---------------------------------------------------------------------------

enum TxnType { expense, income }

class Txn {
  Txn({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.categoryId,
    this.source = 'Added by you',
    this.notes = '',
  });

  final String id;
  String title;
  double amount;
  DateTime date;
  TxnType type;
  String? categoryId;
  String source;
  String notes;
}

class _Cat {
  _Cat(this.id, this.name, this.emoji, this.color, this.budget);
  final String id;
  final String name;
  final String emoji;
  final Color color;
  double budget;
}

class _Payment {
  _Payment(
    this.id,
    this.name,
    this.due,
    this.amount, {
    this.monthly = true,
    this.reminder = false,
  });
  final String id;
  final String name;
  final DateTime due; // for monthly payments only the day is used
  final double amount;
  final bool monthly;
  bool reminder;
}

class _Due {
  const _Due(this.payment, this.date);
  final _Payment payment;
  final DateTime date;
}

class _BudgetStore extends ChangeNotifier {
  _BudgetStore() {
    _seed();
  }

  _Currency currency = _currencies.first;
  late DateTime month;
  double expectedIncome = 3400;
  int _id = 0;

  final List<_Cat> cats = [
    _Cat('groc', 'Groceries', '🥕', const Color(0xFF86A58B), 650),
    _Cat('home', 'Home & Bills', '🏠', const Color(0xFF8FB0A0), 900),
    _Cat('kids', 'Kids & School', '🎒', const Color(0xFF6C9AC4), 250),
    _Cat('trans', 'Transport', '🚙', const Color(0xFF7DA7C0), 220),
    _Cat('health', 'Health', '🩺', const Color(0xFF9BC0A4), 80),
    _Cat('eat', 'Eating out', '🍜', const Color(0xFFC9A27A), 180),
    _Cat('shop', 'Shopping', '🛍️', const Color(0xFFD69AA8), 200),
    _Cat('fun', 'Fun & Subscriptions', '🎬', const Color(0xFFA58FCF), 70),
    _Cat('other', 'Other', '✨', const Color(0xFFB5B8A5), 50),
  ];

  final List<Txn> txns = [];
  final List<_Payment> payments = [];

  String nextId() => 't${_id++}';

  // Sample data (relative to the current month so the reference always shows).
  void _seed() {
    final now = DateTime.now();
    month = DateTime(now.year, now.month);

    void expense(String title, double amt, int day, String cat, String src) =>
        txns.add(
          Txn(
            id: nextId(),
            title: title,
            amount: amt,
            date: DateTime(now.year, now.month, day),
            type: TxnType.expense,
            categoryId: cat,
            source: src,
          ),
        );

    expense('Netflix · Netflix', 10.99, 13, 'fun', 'From receipt');
    expense('School trip', 35, 9, 'kids', 'Added by you');
    expense('Electricity & gas', 118, 8, 'home', 'Added by partner');
    expense('Council tax', 145, 7, 'home', 'Added by family');
    expense('Rent / mortgage', 650, 6, 'home', 'Added by you');
    expense('Tesco weekly shop', 104, 5, 'groc', 'Added by partner');
    expense('Farmers market', 24, 4, 'groc', 'Added by family');
    expense("Sainsbury's top-up", 38, 3, 'groc', 'Added by you');
    expense('Tesco weekly shop', 92, 2, 'groc', 'Added by partner');
    txns.add(
      Txn(
        id: nextId(),
        title: 'Salary',
        amount: 3400,
        date: DateTime(now.year, now.month, 1),
        type: TxnType.income,
      ),
    );

    // Three previous months so Trends has something to compare.
    const base = [
      (1, 'Rent / mortgage', 'home', 650.0),
      (3, 'Council tax', 'home', 145.0),
      (6, 'Electricity & gas', 'home', 112.0),
      (4, 'Tesco weekly shop', 'groc', 98.0),
      (11, 'Tesco weekly shop', 'groc', 104.0),
      (18, "Sainsbury's top-up", 'groc', 41.0),
      (9, 'Bus pass', 'trans', 45.0),
      (15, 'Takeaway', 'eat', 32.0),
    ];
    const factors = [0.94, 1.06, 0.98];
    for (var k = 1; k <= 3; k++) {
      final m = DateTime(now.year, now.month - k);
      for (final e in base) {
        txns.add(
          Txn(
            id: nextId(),
            title: e.$2,
            amount: (e.$4 * factors[k - 1]).roundToDouble(),
            date: DateTime(m.year, m.month, e.$1),
            type: TxnType.expense,
            categoryId: e.$3,
          ),
        );
      }
      txns.add(
        Txn(
          id: nextId(),
          title: 'Salary',
          amount: 3400,
          date: DateTime(m.year, m.month, 1),
          type: TxnType.income,
        ),
      );
    }

    payments.add(
      _Payment('p1', 'Netflix', DateTime(now.year, now.month, 13), 10.99),
    );
  }

  // --- Queries --------------------------------------------------------------

  bool _sameMonth(DateTime d, DateTime m) =>
      d.year == m.year && d.month == m.month;

  _Cat? catById(String? id) {
    for (final c in cats) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Txn> txnsOf(DateTime m, TxnType type) {
    final list =
        txns.where((t) => t.type == type && _sameMonth(t.date, m)).toList()
          ..sort(_byNewest);
    return list;
  }

  static int _byNewest(Txn a, Txn b) {
    final c = b.date.compareTo(a.date);
    return c != 0 ? c : b.id.compareTo(a.id);
  }

  List<Txn> get allSorted => [...txns]..sort(_byNewest);

  double spentIn(DateTime m) =>
      txnsOf(m, TxnType.expense).fold(0.0, (s, t) => s + t.amount);

  double catSpent(String catId, [DateTime? m]) => txnsOf(
    m ?? month,
    TxnType.expense,
  ).where((t) => t.categoryId == catId).fold(0.0, (s, t) => s + t.amount);

  double get spent => spentIn(month);
  double get incomeReceived =>
      txnsOf(month, TxnType.income).fold(0.0, (s, t) => s + t.amount);
  double get planned => cats.fold(0.0, (s, c) => s + c.budget);
  double get used => planned == 0 ? 0 : spent / planned;
  double get remaining => planned - spent;
  double get leftAfterSpending => incomeReceived - spent;

  String get daysText {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final dim = DateUtils.getDaysInMonth(month.year, month.month);
    if (month == current) {
      final left = dim - now.day;
      return left == 1 ? '1 day to go' : '$left days to go';
    }
    return month.isBefore(current) ? 'month ended' : 'not started yet';
  }

  List<_Due> get upcoming {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final isCurrent = month == DateTime(now.year, now.month);
    final dim = DateUtils.getDaysInMonth(month.year, month.month);
    final list = <_Due>[];
    for (final p in payments) {
      final due = p.monthly
          ? DateTime(month.year, month.month, math.min(p.due.day, dim))
          : p.due;
      if (!_sameMonth(due, month)) continue;
      if (isCurrent && due.isBefore(today)) continue;
      list.add(_Due(p, due));
    }
    return list..sort((a, b) => a.date.compareTo(b.date));
  }

  DateTime defaultDateForMonth() {
    final now = DateTime.now();
    final dim = DateUtils.getDaysInMonth(month.year, month.month);
    return DateTime(month.year, month.month, math.min(now.day, dim));
  }

  // --- Mutations ------------------------------------------------------------

  void setCurrency(_Currency c) {
    currency = c;
    notifyListeners();
  }

  void shiftMonth(int delta) {
    month = DateTime(month.year, month.month + delta);
    notifyListeners();
  }

  void addTxn(Txn t) {
    txns.add(t);
    notifyListeners();
  }

  void updateTxn(Txn t) {
    final i = txns.indexWhere((x) => x.id == t.id);
    if (i >= 0) txns[i] = t;
    notifyListeners();
  }

  void deleteTxn(Txn t) {
    txns.remove(t);
    notifyListeners();
  }

  void restoreTxn(Txn t) {
    txns.add(t);
    notifyListeners();
  }

  void setBudget(_Cat c, double v) {
    c.budget = v;
    notifyListeners();
  }

  void setExpectedIncome(double v) {
    expectedIncome = v;
    notifyListeners();
  }

  void toggleReminder(_Payment p, bool on) {
    p.reminder = on;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Actions (forms, details, deletion)
// ---------------------------------------------------------------------------

Future<void> _openTxnForm(
  BuildContext context,
  _BudgetStore store, {
  Txn? edit,
  TxnType type = TxnType.expense,
}) async {
  final result = await showModalBottomSheet<Txn>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: _C.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _TxnForm(store: store, edit: edit, initialType: type),
  );
  if (result == null) return;
  edit == null ? store.addTxn(result) : store.updateTxn(result);
}

Future<void> _confirmDelete(
  BuildContext context,
  _BudgetStore store,
  Txn txn,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _C.card,
      title: Text('Delete this record?', style: _t(18, w: FontWeight.w800)),
      content: Text(
        '"${txn.title}" (${_money(store.currency, txn.amount, decimals: 2)}) '
        'will be removed.',
        style: _t(14, color: _C.muted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: _C.coralText)),
        ),
      ],
    ),
  );
  if (ok != true) return;
  store.deleteTxn(txn);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Record deleted'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => store.restoreTxn(txn),
        ),
      ),
    );
}

Future<void> _openTxnDetail(
  BuildContext context,
  _BudgetStore store,
  Txn txn,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: _C.bg,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      final cat = store.catById(txn.categoryId);
      final income = txn.type == TxnType.income;
      Widget row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(k, style: _t(13.5, color: _C.muted)),
            ),
            Expanded(
              child: Text(v, style: _t(14.5, w: FontWeight.w600)),
            ),
          ],
        ),
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _EmojiCircle(income ? '💰' : (cat?.emoji ?? '✨'), size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      txn.title,
                      style: _t(20, w: FontWeight.w800, height: 1.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${income ? '+' : ''}${_money(store.currency, txn.amount, decimals: 2)}',
                style: _t(30, w: FontWeight.w800, color: _C.forest),
              ),
              const SizedBox(height: 8),
              row('Type', income ? 'Income' : 'Expense'),
              if (cat != null) row('Category', '${cat.emoji} ${cat.name}'),
              row('Date', '${_dayMonth(txn.date)} ${txn.date.year}'),
              row('Source', txn.source),
              if (txn.notes.isNotEmpty) row('Notes', txn.notes),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'delete'),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.coralText,
                        side: const BorderSide(color: _C.divider),
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'edit'),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.forest,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (!context.mounted) return;
  if (action == 'edit') {
    await _openTxnForm(context, store, edit: txn);
  } else if (action == 'delete') {
    await _confirmDelete(context, store, txn);
  }
}

Future<void> _openPaymentDetail(
  BuildContext context,
  _BudgetStore store,
  _Due due,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _C.bg,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => ListenableBuilder(
      listenable: store,
      builder: (ctx, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(due.payment.name, style: _t(22, w: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Due ${_dayMonth(due.date)} · '
                '${_money(store.currency, due.payment.amount, decimals: 2)}'
                '${due.payment.monthly ? ' · repeats monthly' : ''}',
                style: _t(14, color: _C.muted),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 4, 10, 4),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: _C.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Remind me before it is due',
                        style: _t(14.5),
                      ),
                    ),
                    Switch(
                      value: due.payment.reminder,
                      activeColor: Colors.white,
                      activeTrackColor: _C.forest,
                      // TODO: schedule a real notification (flutter_local_notifications).
                      onChanged: (v) => store.toggleReminder(due.payment, v),
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

Future<void> _openCurrencySheet(BuildContext context, _BudgetStore store) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _C.bg,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Currency', style: _t(20, w: FontWeight.w800)),
            ),
            for (final c in _currencies)
              ListTile(
                title: Text(
                  '${c.symbol}  ${c.code}',
                  style: _t(15, w: FontWeight.w700),
                ),
                subtitle: Text(c.name, style: _t(12.5, color: _C.muted)),
                trailing: c.code == store.currency.code
                    ? const Icon(Icons.check_rounded, color: _C.forest)
                    : null,
                onTap: () {
                  store.setCurrency(c);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Future<double?> _askAmount(
  BuildContext context,
  String title,
  double initial,
  String symbol,
) {
  final ctrl = TextEditingController(
    text: initial == initial.roundToDouble()
        ? initial.toStringAsFixed(0)
        : initial.toStringAsFixed(2),
  );
  String? error;
  return showDialog<double>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: _C.card,
        title: Text(title, style: _t(18, w: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(prefixText: '$symbol ', errorText: error),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '').trim());
              if (v == null || v < 0) {
                setState(() => error = 'Enter a valid amount');
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({
    super.key,
    this.onHome,
    this.onFocus,
    this.onNest,
    this.onAdd,
  });

  final VoidCallback? onHome;
  final VoidCallback? onFocus;
  final VoidCallback? onNest;
  final VoidCallback? onAdd;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _store = _BudgetStore();
  int _tab = 0;

  static const _tabs = ['Overview', 'Expenses', 'Income', 'Trends', 'Plan'];

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _addTxn([TxnType type = TxnType.expense]) =>
      _openTxnForm(context, _store, type: type);

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) => Stack(
          children: [
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, c) {
                  final pad = c.maxWidth < 360 ? 16.0 : 20.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      pad,
                      12,
                      pad,
                      120 + bottomSafe,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _Tabs(
                          labels: _tabs,
                          index: _tab,
                          onChanged: (i) => setState(() => _tab = i),
                        ),
                        const SizedBox(height: 14),
                        _MonthSelector(store: _store),
                        const SizedBox(height: 14),
                        switch (_tab) {
                          0 => _buildOverview(),
                          1 => _buildExpenses(),
                          2 => _buildIncome(),
                          3 => _buildTrends(),
                          _ => _buildPlan(),
                        },
                      ],
                    ),
                  );
                },
              ),
            ),
            if (!keyboardOpen)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomSafe + 10,
                child: _BottomNav(
                  onHome: widget.onHome,
                  onFocus: widget.onFocus,
                  onNest: widget.onNest,
                  onAdd: widget.onAdd ?? _addTxn,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Header ---------------------------------------------------------------

  Widget _buildHeader() {
    final c = _store.currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Family budget',
                  style: _t(34, w: FontWeight.w800, spacing: -1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _C.card,
              shape: const StadiumBorder(),
              elevation: 1.5,
              shadowColor: const Color(0x22000000),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => _openCurrencySheet(context, _store),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        '${c.symbol} ${c.code}',
                        style: _t(14.5, w: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: 'Add transaction',
              child: Material(
                color: _C.forest,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _addTxn,
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      Icons.add_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('Where our money went, without the stress.', style: _script(20)),
      ],
    );
  }

  // --- Overview -------------------------------------------------------------

  String get _message {
    final u = _store.used;
    if (u > 1) return "You've gone over your plan.";
    if (u >= 0.9) return 'Nearly at your plan.';
    if (u >= 0.6) return 'Keep an eye on spending.';
    return "You're doing fine this month.";
  }

  Widget _buildOverview() {
    final s = _store;
    final cur = s.currency;
    final over = s.used > 1;
    final upcoming = s.upcoming;
    final recent = s.txnsOf(s.month, TxnType.expense).take(9).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spending summary
        _Card(
          padding: const EdgeInsets.all(22),
          radius: 34,
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: s.used.clamp(0.0, 1.0),
                    color: over ? _C.coral : _C.forest,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(s.used * 100).round()}%',
                          style: _t(26, w: FontWeight.w800, spacing: -0.5),
                        ),
                        Text('used', style: _t(12.5, color: _C.muted)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spent', style: _t(15, color: _C.muted)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _money(cur, s.spent),
                        style: _t(32, w: FontWeight.w800, spacing: -0.8),
                      ),
                    ),
                    Text(
                      'of ${_money(cur, s.planned)} planned',
                      style: _t(14, color: _C.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.remaining >= 0
                          ? '${_money(cur, s.remaining)} left · ${s.daysText}'
                          : '${_money(cur, -s.remaining)} over · ${s.daysText}',
                      style: _t(
                        13.5,
                        w: FontWeight.w700,
                        color: s.remaining >= 0 ? _C.forest : _C.coralText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_message, style: _script(18)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Income + left after spending
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Income received',
                  amount: _money(cur, s.incomeReceived),
                  note: 'of ${_money(cur, s.expectedIncome)} expected',
                  amountColor: _C.text,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Left after spending',
                  amount: _money(cur, s.leftAfterSpending),
                  note: 'income − expenses',
                  amountColor: s.leftAfterSpending >= 0
                      ? _C.forest
                      : _C.coralText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Coming up
        _Card(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
          radius: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('COMING UP'),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Nothing coming up this month.',
                    style: _t(14, color: _C.muted),
                  ),
                ),
              for (final d in upcoming)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openPaymentDetail(context, s, d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.payment.name,
                                style: _t(17, w: FontWeight.w700),
                              ),
                              Text(
                                'Due ${_dayMonth(d.date)}',
                                style: _t(13.5, color: _C.muted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _C.peach,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _money(cur, d.payment.amount, decimals: 2),
                            style: _t(15, w: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Where it went
        _Card(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          radius: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('WHERE IT WENT'),
              const SizedBox(height: 8),
              for (final c in s.cats)
                _CategoryRow(
                  store: s,
                  cat: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _CategoryDetailScreen(store: s, catId: c.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Recent
        _Card(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
          radius: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionLabel('RECENT'),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _AllTransactionsScreen(store: s),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        'See all',
                        style: _t(15, w: FontWeight.w700, color: _C.forest),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No expenses recorded this month.',
                    style: _t(14, color: _C.muted),
                  ),
                ),
              _TxnList(store: s, items: recent),
            ],
          ),
        ),
      ],
    );
  }

  // --- Expenses -------------------------------------------------------------

  Widget _buildExpenses() {
    final s = _store;
    final items = s.txnsOf(s.month, TxnType.expense);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          radius: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel('EXPENSES'),
                    Text(
                      _money(s.currency, s.spent, decimals: 2),
                      style: _t(17, w: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No expenses recorded this month.',
                    style: _t(14, color: _C.muted),
                  ),
                ),
              _TxnList(store: s, items: items),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: 'Add expense',
          icon: Icons.add_rounded,
          onTap: () => _addTxn(TxnType.expense),
        ),
      ],
    );
  }

  // --- Income ---------------------------------------------------------------

  Widget _buildIncome() {
    final s = _store;
    final items = s.txnsOf(s.month, TxnType.income);
    final frac = s.expectedIncome == 0
        ? 0.0
        : (s.incomeReceived / s.expectedIncome).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          padding: const EdgeInsets.all(22),
          radius: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('INCOME RECEIVED'),
              const SizedBox(height: 8),
              Text(
                _money(s.currency, s.incomeReceived),
                style: _t(32, w: FontWeight.w800, spacing: -0.8),
              ),
              Text(
                'of ${_money(s.currency, s.expectedIncome)} expected',
                style: _t(14, color: _C.muted),
              ),
              const SizedBox(height: 14),
              _Bar(fraction: frac, color: _C.forest),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          radius: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: _SectionLabel('INCOME RECORDS'),
              ),
              const SizedBox(height: 6),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No income recorded this month.',
                    style: _t(14, color: _C.muted),
                  ),
                ),
              _TxnList(store: s, items: items),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: 'Add income',
          icon: Icons.add_rounded,
          onTap: () => _addTxn(TxnType.income),
        ),
      ],
    );
  }

  // --- Trends ---------------------------------------------------------------

  Widget _buildTrends() {
    final s = _store;
    final cur = s.currency;
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(s.month.year, s.month.month - i),
    ];
    final values = [for (final m in months) s.spentIn(m)];
    final maxV = values.fold<double>(0, math.max);
    final prev = DateTime(s.month.year, s.month.month - 1);
    final cur0 = s.spent;
    final prev0 = s.spentIn(prev);
    final diff = cur0 - prev0;

    String summary;
    if (cur0 == 0 && prev0 == 0) {
      summary = 'No spending recorded for these months yet.';
    } else if (diff > 0.5) {
      summary =
          "You've spent ${_money(cur, diff)} more than in ${_monthNames[prev.month - 1]}.";
    } else if (diff < -0.5) {
      summary =
          "You've spent ${_money(cur, -diff)} less than in ${_monthNames[prev.month - 1]}.";
    } else {
      summary = 'Spending is about the same as ${_monthNames[prev.month - 1]}.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          radius: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('SPENDING · LAST 6 MONTHS'),
              const SizedBox(height: 16),
              SizedBox(
                height: 170,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < months.length; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _short(cur, values[i]),
                              style: _t(11, color: _C.muted),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: maxV == 0
                                  ? 4
                                  : math.max(4.0, 110 * values[i] / maxV),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: i == months.length - 1
                                    ? _C.forest
                                    : const Color(0xFFC9D3C0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _monthShort(months[i]),
                              style: _t(
                                12,
                                w: i == months.length - 1
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == months.length - 1
                                    ? _C.forest
                                    : _C.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          radius: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('VS LAST MONTH'),
              const SizedBox(height: 10),
              Text(summary, style: _t(15, w: FontWeight.w600, height: 1.35)),
              const SizedBox(height: 8),
              for (final c in s.cats)
                Builder(
                  builder: (_) {
                    final now = s.catSpent(c.id);
                    final before = s.catSpent(c.id, prev);
                    if (now == 0 && before == 0) return const SizedBox.shrink();
                    final d = now - before;
                    final up = d > 0.5;
                    final down = d < -0.5;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${c.emoji}  ',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Expanded(child: Text(c.name, style: _t(14.5))),
                          Text(
                            _money(cur, now),
                            style: _t(14.5, w: FontWeight.w700),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 74,
                            child: Text(
                              up
                                  ? '↑ ${_money(cur, d)}'
                                  : down
                                  ? '↓ ${_money(cur, -d)}'
                                  : '–',
                              textAlign: TextAlign.right,
                              style: _t(
                                12.5,
                                w: FontWeight.w600,
                                color: up
                                    ? _C.coralText
                                    : down
                                    ? _C.forest
                                    : _C.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Plan -----------------------------------------------------------------

  Widget _buildPlan() {
    final s = _store;
    final cur = s.currency;
    Future<void> edit(
      String title,
      double initial,
      void Function(double) apply,
    ) async {
      final v = await _askAmount(context, title, initial, cur.symbol);
      if (v != null) apply(v);
    }

    final share = s.expectedIncome == 0
        ? 0
        : (s.planned / s.expectedIncome * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
          radius: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('MONTHLY PLAN'),
              const SizedBox(height: 4),
              Text(
                'Tap a category to change its monthly limit.',
                style: _t(13, color: _C.muted),
              ),
              const SizedBox(height: 6),
              for (final c in s.cats)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => edit(
                    '${c.name} budget',
                    c.budget,
                    (v) => s.setBudget(c, v),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          '${c.emoji}  ',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Expanded(child: Text(c.name, style: _t(15.5))),
                        Text(
                          _money(cur, c.budget),
                          style: _t(15.5, w: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.edit_outlined,
                          size: 17,
                          color: _C.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(color: _C.divider, height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total planned',
                        style: _t(15.5, w: FontWeight.w700),
                      ),
                    ),
                    Text(
                      _money(cur, s.planned),
                      style: _t(17, w: FontWeight.w800, color: _C.forest),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          padding: const EdgeInsets.all(22),
          radius: 30,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => edit(
              'Expected monthly income',
              s.expectedIncome,
              s.setExpectedIncome,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('EXPECTED INCOME'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _money(cur, s.expectedIncome),
                        style: _t(26, w: FontWeight.w800, spacing: -0.5),
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 18, color: _C.muted),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your plan uses $share% of expected income.',
                  style: _t(13.5, color: _C.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-screens
// ---------------------------------------------------------------------------

class _CategoryDetailScreen extends StatelessWidget {
  const _CategoryDetailScreen({required this.store, required this.catId});

  final _BudgetStore store;
  final String catId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cat = store.catById(catId)!;
        final cur = store.currency;
        final spent = store.catSpent(cat.id);
        final over = spent > cat.budget;
        final items = store
            .txnsOf(store.month, TxnType.expense)
            .where((t) => t.categoryId == cat.id)
            .toList();

        return _SubScaffold(
          title: '${cat.emoji}  ${cat.name}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Card(
                padding: const EdgeInsets.all(22),
                radius: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthTitle(store.month),
                      style: _t(13, color: _C.muted),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _money(cur, spent),
                            style: _t(
                              30,
                              w: FontWeight.w800,
                              color: over ? _C.coralText : _C.text,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${_money(cur, cat.budget)}',
                            style: _t(18, color: _C.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Bar(
                      fraction: cat.budget == 0
                          ? (spent > 0 ? 1 : 0)
                          : (spent / cat.budget).clamp(0.0, 1.0),
                      color: over ? _C.coral : cat.color,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      over
                          ? 'Over by ${_money(cur, spent - cat.budget)}'
                          : '${_money(cur, cat.budget - spent)} left',
                      style: _t(
                        14,
                        w: FontWeight.w700,
                        color: over ? _C.coralText : _C.forest,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () async {
                        final v = await _askAmount(
                          context,
                          '${cat.name} budget',
                          cat.budget,
                          cur.symbol,
                        );
                        if (v != null) store.setBudget(cat, v);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit monthly limit'),
                      style: TextButton.styleFrom(foregroundColor: _C.forest),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Card(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                radius: 34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('THIS MONTH'),
                    const SizedBox(height: 6),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Nothing spent here yet.',
                          style: _t(14, color: _C.muted),
                        ),
                      ),
                    _TxnList(store: store, items: items),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AllTransactionsScreen extends StatelessWidget {
  const _AllTransactionsScreen({required this.store});

  final _BudgetStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.allSorted;
        final groups = <Widget>[];
        DateTime? current;
        var chunk = <Txn>[];

        void flush() {
          if (chunk.isEmpty) return;
          groups.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _Card(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                radius: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(_monthTitle(current!).toUpperCase()),
                    const SizedBox(height: 6),
                    _TxnList(store: store, items: chunk),
                  ],
                ),
              ),
            ),
          );
          chunk = [];
        }

        for (final t in all) {
          final m = DateTime(t.date.year, t.date.month);
          if (current != m) {
            flush();
            current = m;
          }
          chunk.add(t);
        }
        flush();

        return _SubScaffold(
          title: 'All transactions',
          child: groups.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'No transactions yet.',
                      style: _t(14, color: _C.muted),
                    ),
                  ),
                )
              : Column(children: groups),
        );
      },
    );
  }
}

class _SubScaffold extends StatelessWidget {
  const _SubScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: _C.card,
                    shape: const CircleBorder(
                      side: BorderSide(color: _C.divider),
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
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(22, w: FontWeight.w800, spacing: -0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction form
// ---------------------------------------------------------------------------

class _TxnForm extends StatefulWidget {
  const _TxnForm({
    required this.store,
    required this.edit,
    required this.initialType,
  });

  final _BudgetStore store;
  final Txn? edit;
  final TxnType initialType;

  @override
  State<_TxnForm> createState() => _TxnFormState();
}

class _TxnFormState extends State<_TxnForm> {
  late TxnType _type = widget.edit?.type ?? widget.initialType;
  late final _amount = TextEditingController(
    text: widget.edit == null ? '' : widget.edit!.amount.toStringAsFixed(2),
  );
  late final _title = TextEditingController(text: widget.edit?.title ?? '');
  late final _notes = TextEditingController(text: widget.edit?.notes ?? '');
  late String _catId = widget.edit?.categoryId ?? 'other';
  late DateTime _date = widget.edit?.date ?? widget.store.defaultDateForMonth();
  String? _amountError;
  String? _titleError;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2036),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    final title = _title.text.trim();
    setState(() {
      _amountError = (amount == null || amount <= 0)
          ? 'Enter an amount above 0'
          : null;
      _titleError = title.isEmpty ? 'Add a short description' : null;
    });
    if (_amountError != null || _titleError != null) return;

    final e = widget.edit;
    Navigator.pop(
      context,
      Txn(
        id: e?.id ?? widget.store.nextId(),
        title: title,
        amount: amount!,
        date: _date,
        type: _type,
        categoryId: _type == TxnType.expense ? _catId : null,
        source: e?.source ?? 'Added by you',
        notes: _notes.text.trim(),
      ),
    );
  }

  InputDecoration _dec(String hint, {String? error, String? prefix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: _t(14.5, color: _C.muted),
        errorText: error,
        prefixText: prefix,
        filled: true,
        fillColor: _C.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: _outline(_C.divider),
        enabledBorder: _outline(_C.divider),
        focusedBorder: _outline(_C.forest, 1.4),
        errorBorder: _outline(_C.coralText),
        focusedErrorBorder: _outline(_C.coralText, 1.4),
      );

  OutlineInputBorder _outline(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide(color: c, width: w),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 18),
    child: Text(
      text,
      style: _t(12, w: FontWeight.w700, color: _C.muted, spacing: 1.2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final editing = widget.edit != null;
    final isExpense = _type == TxnType.expense;
    final symbol = widget.store.currency.symbol;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editing ? 'Edit transaction' : 'Add transaction',
              style: _t(22, w: FontWeight.w800, spacing: -0.4),
            ),
            const SizedBox(height: 16),
            _Tabs(
              labels: const ['Expense', 'Income'],
              index: isExpense ? 0 : 1,
              onChanged: (i) => setState(
                () => _type = i == 0 ? TxnType.expense : TxnType.income,
              ),
            ),
            _label('AMOUNT'),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                if (_amountError != null) setState(() => _amountError = null);
              },
              decoration: _dec('0.00', error: _amountError, prefix: '$symbol '),
            ),
            if (isExpense) ...[
              _label('CATEGORY'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in widget.store.cats)
                    _ChoicePill(
                      label: '${c.emoji} ${c.name}',
                      active: _catId == c.id,
                      onTap: () => setState(() => _catId = c.id),
                    ),
                ],
              ),
            ],
            _label('DATE'),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _pickDate,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 19,
                      color: _C.muted,
                    ),
                    const SizedBox(width: 12),
                    Text('${_dayMonth(_date)} ${_date.year}', style: _t(14.5)),
                  ],
                ),
              ),
            ),
            _label('DESCRIPTION'),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
              decoration: _dec(
                isExpense ? 'e.g. Tesco weekly shop' : 'e.g. Salary',
                error: _titleError,
              ),
            ),
            _label('NOTES (OPTIONAL)'),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: _dec('Anything worth remembering'),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: editing
                  ? 'Save changes'
                  : (isExpense ? 'Add expense' : 'Add income'),
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 30,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: _softShadow,
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: _t(12.5, w: FontWeight.w800, color: _C.muted, spacing: 1.4),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.note,
    required this.amountColor,
  });

  final String label;
  final String amount;
  final String note;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: _t(13.5, color: _C.muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: _t(
                24,
                w: FontWeight.w800,
                color: amountColor,
                spacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(note, style: _t(13, color: _C.muted)),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.sage,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: i == index
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[i],
                      style: _t(
                        13.5,
                        w: i == index ? FontWeight.w700 : FontWeight.w500,
                        color: i == index ? _C.forest : _C.muted,
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
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.store});
  final _BudgetStore store;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, String label, int delta) => Semantics(
      button: true,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => store.shiftMonth(delta),
        child: SizedBox(
          width: 56,
          height: 64,
          child: Icon(icon, size: 24, color: _C.text),
        ),
      ),
    );

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: _softShadow,
      ),
      child: Row(
        children: [
          arrow(Icons.chevron_left_rounded, 'Previous month', -1),
          Expanded(
            child: Center(
              child: Text(
                _monthTitle(store.month),
                style: _t(18, w: FontWeight.w700, spacing: -0.2),
              ),
            ),
          ),
          arrow(Icons.chevron_right_rounded, 'Next month', 1),
        ],
      ),
    );
  }
}

class _EmojiCircle extends StatelessWidget {
  const _EmojiCircle(this.emoji, {this.size = 46});
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: _C.sage, shape: BoxShape.circle),
    child: Text(emoji, style: TextStyle(fontSize: size * 0.44)),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color, this.height = 8});

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _C.sage,
        borderRadius: BorderRadius.circular(height),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.store,
    required this.cat,
    required this.onTap,
  });

  final _BudgetStore store;
  final _Cat cat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cur = store.currency;
    final spent = store.catSpent(cat.id);
    final over = spent > cat.budget;
    final frac = cat.budget == 0 ? (spent > 0 ? 1.0 : 0.0) : spent / cat.budget;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${cat.emoji} ', style: const TextStyle(fontSize: 15)),
                Expanded(
                  child: Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(15.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _money(cur, spent),
                        style: _t(
                          15.5,
                          w: FontWeight.w800,
                          color: over ? _C.coralText : _C.text,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${_money(cur, cat.budget)}',
                        style: _t(15, color: _C.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Bar(fraction: frac, color: over ? _C.coral : cat.color),
            if (over)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: _C.coralText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Over by ${_money(cur, spent - cat.budget)}',
                      style: _t(11.5, w: FontWeight.w600, color: _C.coralText),
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

class _TxnList extends StatelessWidget {
  const _TxnList({required this.store, required this.items});

  final _BudgetStore store;
  final List<Txn> items;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final t = items[i];
      children.add(
        _TxnRow(
          store: store,
          txn: t,
          onTap: () => _openTxnDetail(context, store, t),
          onDelete: t.source == 'From receipt'
              ? null
              : () => _confirmDelete(context, store, t),
        ),
      );
      if (i < items.length - 1) {
        children.add(const Divider(height: 1, thickness: 1, color: _C.divider));
      }
    }
    return Column(children: children);
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({
    required this.store,
    required this.txn,
    required this.onTap,
    this.onDelete,
  });

  final _BudgetStore store;
  final Txn txn;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final income = txn.type == TxnType.income;
    final cat = store.catById(txn.categoryId);
    final receipt = txn.source == 'From receipt';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _EmojiCircle(income ? '💰' : (cat?.emoji ?? '✨')),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(16, w: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      style: _t(12.5, color: _C.muted),
                      children: [
                        TextSpan(text: '${_dayMonth(txn.date)} · '),
                        if (receipt)
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 13,
                              color: _C.muted,
                            ),
                          ),
                        TextSpan(text: receipt ? ' From receipt' : txn.source),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${income ? '+' : ''}${_money(store.currency, txn.amount, decimals: 2)}',
              style: _t(
                15.5,
                w: FontWeight.w800,
                color: income ? _C.forest : _C.text,
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 21,
                  color: _C.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? _C.forest : _C.card,
      shape: StadiumBorder(
        side: BorderSide(color: active ? _C.forest : _C.divider),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: _t(
              13.5,
              w: FontWeight.w600,
              color: active ? Colors.white : const Color(0xFF3E5A4A),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.forest,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: _t(15.5, w: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = _C.sage
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);
    if (progress <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ---------------------------------------------------------------------------
// Bottom navigation
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.onAdd,
    this.onHome,
    this.onFocus,
    this.onNest,
  });

  final VoidCallback onAdd;
  final VoidCallback? onHome;
  final VoidCallback? onFocus;
  final VoidCallback? onNest;

  Widget _item(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool selected = false,
  }) {
    final color = selected ? _C.forest : _C.muted;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: _t(
                12,
                w: selected ? FontWeight.w700 : FontWeight.w500,
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
      height: 80,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _item(Icons.home_outlined, 'Home', onHome),
          _item(Icons.auto_awesome_outlined, 'Focus', onFocus),
          Expanded(
            child: Center(
              child: Semantics(
                button: true,
                label: 'Add',
                child: Material(
                  color: _C.forest,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: const Color(0x66195A3B),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onAdd,
                    child: const SizedBox(
                      width: 70,
                      height: 70,
                      child: Icon(
                        Icons.add_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _item(Icons.eco_outlined, 'Nest', onNest),
          _item(
            Icons.account_balance_wallet_outlined,
            'Budget',
            null,
            selected: true,
          ),
        ],
      ),
    );
  }
}
