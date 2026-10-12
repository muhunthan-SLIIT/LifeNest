// LifeNest Settings screen + settings logic (persistence, theme, PIN, biometrics)
// Save as lib/settings_screen.dart
//
// pubspec.yaml (dependencies):
//   google_fonts: ^6.2.1
//   shared_preferences: ^2.3.2
//   local_auth: ^2.3.0
//   flutter_secure_storage: ^9.2.2
//   crypto: ^3.0.5
//   file_picker: ^8.1.2
//
// Wire it up in main.dart (see the notes in the chat reply):
//   final settings = SettingsController();
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     await settings.load();
//     runApp(MyApp());
//   }
//   MaterialApp(
//     theme: lifeNestTheme(Brightness.light),
//     darkTheme: lifeNestTheme(Brightness.dark),
//     themeMode: settings.themeMode,            // rebuild with ListenableBuilder
//     builder: (context, child) => AppLockGate(controller: settings, child: child!),
//   )

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kAppVersion = '0.1';

// ===========================================================================
// Palette
// ===========================================================================

class _P {
  const _P({
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.neutral,
    required this.track,
    required this.primary,
    required this.icon,
    required this.separator,
    required this.destructive,
  });

  final Color bg;
  final Color card;
  final Color text;
  final Color muted;
  final Color neutral;
  final Color track;
  final Color primary;
  final Color icon;
  final Color separator;
  final Color destructive;

  static const light = _P(
    bg: Color(0xFFFAF7F0),
    card: Color(0xFFFFFFFF),
    text: Color(0xFF17281F),
    muted: Color(0xFF8B8A80),
    neutral: Color(0xFFEEECE3),
    track: Color(0xFFE7E4DB),
    primary: Color(0xFF194B35),
    icon: Color(0xFF194B35),
    separator: Color(0xFFF0EDE5),
    destructive: Color(0xFFE34D4D),
  );

  static const dark = _P(
    bg: Color(0xFF111915),
    card: Color(0xFF1A241F),
    text: Color(0xFFE9F0EB),
    muted: Color(0xFF94A098),
    neutral: Color(0xFF26322B),
    track: Color(0xFF34413A),
    primary: Color(0xFF2E7D57),
    icon: Color(0xFF8FD0AC),
    separator: Color(0xFF26322B),
    destructive: Color(0xFFFF7A7A),
  );

  static _P of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  TextStyle t(
    double size, {
    FontWeight w = FontWeight.w500,
    Color? color,
    double? height,
    double? spacing,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: w,
    color: color ?? text,
    height: height,
    letterSpacing: spacing,
  );

  TextStyle script(double size, {Color? color}) => GoogleFonts.caveat(
    fontSize: size,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    color: color ?? muted,
  );
}

/// Use for MaterialApp.theme / darkTheme.
ThemeData lifeNestTheme(Brightness b) {
  final p = b == Brightness.dark ? _P.dark : _P.light;
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _P.light.primary,
      brightness: b,
    ),
  );
}

// ===========================================================================
// Settings logic + persistence
// ===========================================================================

enum BiometricResult { success, unavailable, failed }

/// Asks the device for fingerprint / Face ID. Never throws.
Future<BiometricResult> authenticateBiometric(String reason) async {
  try {
    final auth = LocalAuthentication();
    final supported =
        await auth.isDeviceSupported() && await auth.canCheckBiometrics;
    if (!supported) return BiometricResult.unavailable;
    final ok = await auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    return ok ? BiometricResult.success : BiometricResult.failed;
  } catch (_) {
    // Not enrolled, no plugin on this platform (e.g. web), etc.
    return BiometricResult.unavailable;
  }
}

class StoredFile {
  const StoredFile({
    required this.id,
    required this.name,
    required this.bytes,
    required this.added,
    this.isSample = false,
  });

  final String id;
  final String name;
  final int bytes;
  final DateTime added;
  final bool isSample;
}

const _reminderOptions = <(int, String, String)>[
  (0, 'On the', 'day'),
  (1, '1 day', 'before'),
  (3, '3 days', 'before'),
  (7, '1 week', 'before'),
  (14, '2 weeks', 'before'),
];

class SettingsController extends ChangeNotifier {
  SettingsController({FlutterSecureStorage? secureStorage})
    : _secure = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;

  // Profile
  String name = 'Alex';
  String email = 'alex@example.com';

  // Storage
  String storageProvider = 'lifenest'; // 'lifenest' | 'device'

  // Notifications
  bool pushEnabled = true;
  bool emailEnabled = false;
  int reminderDays = 3;

  // Privacy & security
  bool biometricEnabled = false;
  bool pinEnabled = false;
  bool hideFromSearch = true;
  bool hideNotificationPreviews = true;

  // Appearance + data
  ThemeMode themeMode = ThemeMode.system;
  bool autoCleanExpired = false;

  // Data (replace with your real repositories)
  List<StoredFile> attachments = _sampleFiles();
  List<String> archived = [];

  static List<StoredFile> _sampleFiles() {
    final now = DateTime.now();
    StoredFile f(int i, String n, int kb, int daysAgo) => StoredFile(
      id: 'sample$i',
      name: n,
      bytes: kb * 1024,
      added: now.subtract(Duration(days: daysAgo)),
      isSample: true,
    );
    return [
      f(1, 'Boarding pass.pdf', 182, 2),
      f(2, 'Passport scan.jpg', 1240, 5),
      f(3, 'Home insurance.pdf', 860, 9),
      f(4, 'Sony WH-1000XM5 receipt.pdf', 96, 12),
      f(5, 'Parking screenshot.png', 540, 14),
      f(6, 'School trip form.pdf', 210, 18),
      f(7, 'Kyoto itinerary.docx', 74, 21),
      f(8, 'Rattan lamp.jpg', 920, 25),
    ];
  }

  // --- Labels ---------------------------------------------------------------

  String get storageLabel =>
      storageProvider == 'device' ? 'This device' : 'LifeNest (default)';

  String get attachmentsLabel =>
      attachments.length == 1 ? '1 file' : '${attachments.length} files';

  String get reminderLabel {
    final o = _reminderOptions.firstWhere(
      (e) => e.$1 == reminderDays,
      orElse: () => _reminderOptions[2],
    );
    return '${o.$2}\n${o.$3}';
  }

  String get sensitiveLabel =>
      hideFromSearch ? 'Hidden from search' : 'Shown in search';

  // --- Load / save ----------------------------------------------------------

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    name = p.getString('name') ?? name;
    email = p.getString('email') ?? email;
    storageProvider = p.getString('storageProvider') ?? storageProvider;
    pushEnabled = p.getBool('pushEnabled') ?? pushEnabled;
    emailEnabled = p.getBool('emailEnabled') ?? emailEnabled;
    reminderDays = p.getInt('reminderDays') ?? reminderDays;
    biometricEnabled = p.getBool('biometricEnabled') ?? false;
    pinEnabled = p.getBool('pinEnabled') ?? false;
    hideFromSearch = p.getBool('hideFromSearch') ?? hideFromSearch;
    hideNotificationPreviews =
        p.getBool('hideNotificationPreviews') ?? hideNotificationPreviews;
    autoCleanExpired = p.getBool('autoCleanExpired') ?? false;
    themeMode = switch (p.getString('themeMode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  void _set(
    void Function() change,
    Future<bool> Function(SharedPreferences) save,
  ) {
    change();
    notifyListeners();
    final p = _prefs;
    if (p != null) save(p);
  }

  void updateProfile(String newName, String newEmail) => _set(
    () {
      name = newName;
      email = newEmail;
    },
    (p) async {
      await p.setString('name', newName);
      return p.setString('email', newEmail);
    },
  );

  void setStorageProvider(String v) =>
      _set(() => storageProvider = v, (p) => p.setString('storageProvider', v));

  // TODO: when turning push on, request notification permission and register
  // the device (e.g. flutter_local_notifications / Firebase Messaging).
  void setPush(bool v) =>
      _set(() => pushEnabled = v, (p) => p.setBool('pushEnabled', v));

  // TODO: sync this preference to your backend so email reminders are sent.
  void setEmail(bool v) =>
      _set(() => emailEnabled = v, (p) => p.setBool('emailEnabled', v));

  // TODO: reschedule existing reminders using the new lead time.
  void setReminderDays(int v) =>
      _set(() => reminderDays = v, (p) => p.setInt('reminderDays', v));

  void setBiometric(bool v) =>
      _set(() => biometricEnabled = v, (p) => p.setBool('biometricEnabled', v));

  void setHideFromSearch(bool v) =>
      _set(() => hideFromSearch = v, (p) => p.setBool('hideFromSearch', v));

  void setHideNotificationPreviews(bool v) => _set(
    () => hideNotificationPreviews = v,
    (p) => p.setBool('hideNotificationPreviews', v),
  );

  void setThemeMode(ThemeMode m) => _set(
    () => themeMode = m,
    (p) => p.setString('themeMode', switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    }),
  );

  // TODO: run your real cleanup job (and on app start) when this is on.
  void setAutoCleanExpired(bool v) =>
      _set(() => autoCleanExpired = v, (p) => p.setBool('autoCleanExpired', v));

  // --- PIN (salted SHA-256 hash in secure storage; the PIN itself is never stored)

  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<void> setPin(String pin) async {
    final rnd = math.Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(16, (_) => rnd.nextInt(256)),
    );
    await _secure.write(key: 'pin_salt', value: salt);
    await _secure.write(key: 'pin_hash', value: _hash(salt, pin));
    _set(() => pinEnabled = true, (p) => p.setBool('pinEnabled', true));
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _secure.read(key: 'pin_salt');
    final hash = await _secure.read(key: 'pin_hash');
    if (salt == null || hash == null) return false;
    return _hash(salt, pin) == hash;
  }

  Future<void> clearPin() async {
    await _secure.delete(key: 'pin_salt');
    await _secure.delete(key: 'pin_hash');
    _set(() => pinEnabled = false, (p) => p.setBool('pinEnabled', false));
  }

  // --- Data -----------------------------------------------------------------

  void removeAttachment(String id) {
    attachments = attachments.where((f) => f.id != id).toList();
    notifyListeners();
  }

  void restoreArchived(int index) {
    archived = [...archived]..removeAt(index);
    notifyListeners();
  }

  /// Only touches demonstration data. Files the user added are kept.
  void resetSampleData() {
    final real = attachments.where((f) => !f.isSample).toList();
    attachments = [...real, ..._sampleFiles()];
    notifyListeners();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'app': 'LifeNest',
    'version': kAppVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'profile': {'name': name, 'email': email},
    'preferences': {
      'storageProvider': storageProvider,
      'pushNotifications': pushEnabled,
      'emailNotifications': emailEnabled,
      'reminderDaysBefore': reminderDays,
      'biometricLock': biometricEnabled,
      'appPin': pinEnabled,
      'sensitiveHiddenFromSearch': hideFromSearch,
      'hideNotificationPreviews': hideNotificationPreviews,
      'theme': themeMode.name,
      'deleteExpiredTemporaryItems': autoCleanExpired,
    },
    'attachments': [
      for (final f in attachments)
        {
          'name': f.name,
          'sizeBytes': f.bytes,
          'added': f.added.toIso8601String(),
        },
    ],
    'archivedItems': archived,
  });
}

// ===========================================================================
// Themed wrapper (so Settings + its sub-pages follow the chosen theme even
// if MaterialApp is not wired yet)
// ===========================================================================

class _Themed extends StatelessWidget {
  const _Themed({required this.controller, required this.child});

  final SettingsController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final platform = MediaQuery.platformBrightnessOf(context);
        final dark = switch (controller.themeMode) {
          ThemeMode.dark => true,
          ThemeMode.light => false,
          ThemeMode.system => platform == Brightness.dark,
        };
        return Theme(
          data: lifeNestTheme(dark ? Brightness.dark : Brightness.light),
          child: child,
        );
      },
    );
  }
}

Future<T?> _push<T>(BuildContext context, SettingsController c, Widget page) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => _Themed(controller: c, child: page),
    ),
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  bool destructive = true,
}) async {
  final p = _P.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.card,
      title: Text(title, style: p.t(18, w: FontWeight.w800)),
      content: Text(message, style: p.t(14, color: p.muted, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: p.t(14, w: FontWeight.w600, color: p.muted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirm,
            style: p.t(
              14,
              w: FontWeight.w700,
              color: destructive ? p.destructive : p.icon,
            ),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}

String _formatBytes(int b) {
  if (b < 1024) return '$b B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
}

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
String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

// ===========================================================================
// Settings screen
// ===========================================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    this.onHome,
    this.onInbox,
    this.onBrowse,
    this.onAdd,
    this.onSignOut,
  });

  final SettingsController controller;
  final VoidCallback? onHome;
  final VoidCallback? onInbox;
  final VoidCallback? onBrowse;
  final VoidCallback? onAdd;

  /// End the session and navigate to your auth screen.
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return _Themed(
      controller: controller,
      child: _SettingsBody(
        controller: controller,
        onHome: onHome,
        onInbox: onInbox,
        onBrowse: onBrowse,
        onAdd: onAdd,
        onSignOut: onSignOut,
      ),
    );
  }
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody({
    required this.controller,
    this.onHome,
    this.onInbox,
    this.onBrowse,
    this.onAdd,
    this.onSignOut,
  });

  final SettingsController controller;
  final VoidCallback? onHome;
  final VoidCallback? onInbox;
  final VoidCallback? onBrowse;
  final VoidCallback? onAdd;
  final Future<void> Function()? onSignOut;

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  bool _exporting = false;

  SettingsController get c => widget.controller;

  // --- Handlers -------------------------------------------------------------

  Future<void> _toggleBiometric(bool on) async {
    if (!on) {
      c.setBiometric(false);
      return;
    }
    final r = await authenticateBiometric('Confirm to turn on biometric lock');
    if (!mounted) return;
    switch (r) {
      case BiometricResult.success:
        c.setBiometric(true);
      case BiometricResult.unavailable:
        _snack(
          context,
          "Biometrics aren't available here. Set up a fingerprint or Face ID in your device settings first.",
        );
      case BiometricResult.failed:
        _snack(
          context,
          "Couldn't verify it's you, so biometric lock stays off.",
        );
    }
  }

  Future<void> _togglePin(bool on) async {
    if (on) {
      final ok = await _push<bool>(context, c, _PinSetupScreen(controller: c));
      if (ok == true && mounted) _snack(context, 'App PIN turned on.');
    } else {
      final ok = await _push<bool>(
        context,
        c,
        _PinVerifyScreen(controller: c, title: 'Enter your PIN to turn it off'),
      );
      if (ok == true) {
        await c.clearPin();
        if (mounted) _snack(context, 'App PIN turned off.');
      }
    }
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final json = c.exportJson();
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export LifeNest data',
        fileName: 'lifenest-export.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (!mounted) return;
      _snack(
        context,
        path == null && !kIsWeb
            ? 'Export cancelled.'
            : 'Your data export is ready.',
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        _snack(
          context,
          "Couldn't save a file, so your export was copied to the clipboard.",
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _resetSample() async {
    final ok = await _confirm(
      context,
      title: 'Reset sample data?',
      message: 'This restores the demo content only. Anything you added yourself stays untouched.',
      confirm: 'Reset',
    );
    if (ok) {
      c.resetSampleData();
      if (mounted) _snack(context, 'Sample data has been reset.');
    }
  }

  Future<void> _signOut() async {
    final ok = await _confirm(
      context,
      title: 'Sign out?',
      message: "You'll need to sign in again to open your LifeNest.",
      confirm: 'Sign out',
    );
    if (!ok) return;
    if (widget.onSignOut != null) {
      await widget.onSignOut!();
    } else if (mounted) {
      _snack(context, 'Signed out. (Connect onSignOut to your auth screen.)');
    }
  }

  Future<void> _pickReminder() async {
    final p = _P.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: p.bg,
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text('Remind me', style: p.t(20, w: FontWeight.w800)),
            ),
            for (final o in _reminderOptions)
              ListTile(
                title: Text(
                  '${o.$2} ${o.$3}',
                  style: p.t(15, w: FontWeight.w600),
                ),
                trailing: o.$1 == c.reminderDays
                    ? Icon(Icons.check_rounded, color: p.icon)
                    : null,
                onTap: () => Navigator.pop(ctx, o.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) c.setReminderDays(picked);
  }

  Future<void> _pickStorage() async {
    final p = _P.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: p.bg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        Widget option(
          String id,
          String title,
          String sub, {
          bool enabled = true,
        }) => ListTile(
          enabled: enabled,
          title: Text(title, style: p.t(15, w: FontWeight.w600)),
          subtitle: Text(sub, style: p.t(12.5, color: p.muted)),
          trailing: id == c.storageProvider
              ? Icon(Icons.check_rounded, color: p.icon)
              : null,
          onTap: enabled ? () => Navigator.pop(ctx, id) : null,
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Text(
                  'Storage provider',
                  style: p.t(20, w: FontWeight.w800),
                ),
              ),
              option(
                'lifenest',
                'LifeNest (default)',
                'Private, encrypted cloud storage',
              ),
              option('device', 'This device', 'Keep files only on this phone'),
              option('gdrive', 'Google Drive', 'Coming soon', enabled: false),
              option('icloud', 'iCloud', 'Coming soon', enabled: false),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) c.setStorageProvider(picked);
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: p.bg,
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) => Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 120 + bottomSafe),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: p.t(
                              32,
                              w: FontWeight.w800,
                              color: p.icon,
                              spacing: -0.9,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Yours, and only yours.',
                            style: p.t(14, color: p.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    _Section('PROFILE', [
                      _Row(
                        icon: Icons.person_outline_rounded,
                        title: c.name,
                        value: c.email,
                        valueMaxWidth: 170,
                        onTap: () =>
                            _push(context, c, _ProfileScreen(controller: c)),
                      ),
                    ]),

                    _Section('STORAGE', [
                      _Row(
                        icon: Icons.cloud_outlined,
                        title: 'Storage provider',
                        value: c.storageLabel,
                        onTap: _pickStorage,
                      ),
                      _Row(
                        icon: Icons.attach_file_rounded,
                        title: 'Manage attachments',
                        value: c.attachmentsLabel,
                        onTap: () => _push(
                          context,
                          c,
                          _AttachmentsScreen(controller: c),
                        ),
                      ),
                    ]),

                    _Section('NOTIFICATIONS', [
                      _Row(
                        icon: Icons.notifications_none_rounded,
                        title: 'Push notifications',
                        trailing: _LNSwitch(
                          label: 'Push notifications',
                          value: c.pushEnabled,
                          onChanged: c.setPush,
                        ),
                        onTap: () => c.setPush(!c.pushEnabled),
                      ),
                      _Row(
                        icon: Icons.notifications_none_rounded,
                        title: 'Email notifications',
                        trailing: _LNSwitch(
                          label: 'Email notifications',
                          value: c.emailEnabled,
                          onChanged: c.setEmail,
                        ),
                        onTap: () => c.setEmail(!c.emailEnabled),
                      ),
                      _Row(
                        icon: Icons.notifications_none_rounded,
                        title: 'Reminder preferences',
                        value: c.reminderLabel,
                        valueMaxWidth: 90,
                        onTap: _pickReminder,
                      ),
                    ]),

                    _Section('PRIVACY & SECURITY', [
                      _Row(
                        icon: Icons.fingerprint_rounded,
                        title: 'Biometric lock',
                        trailing: _LNSwitch(
                          label: 'Biometric lock',
                          value: c.biometricEnabled,
                          onChanged: _toggleBiometric,
                        ),
                        onTap: () => _toggleBiometric(!c.biometricEnabled),
                      ),
                      _Row(
                        icon: Icons.verified_user_outlined,
                        title: 'App PIN',
                        trailing: _LNSwitch(
                          label: 'App PIN',
                          value: c.pinEnabled,
                          onChanged: _togglePin,
                        ),
                        onTap: () => _togglePin(!c.pinEnabled),
                      ),
                      _Row(
                        icon: Icons.verified_user_outlined,
                        title: 'Sensitive items',
                        value: c.sensitiveLabel,
                        valueMaxWidth: 120,
                        onTap: () =>
                            _push(context, c, _SensitiveScreen(controller: c)),
                      ),
                    ]),

                    _ThemeSelector(
                      mode: c.themeMode,
                      onChanged: c.setThemeMode,
                    ),
                    const SizedBox(height: 22),

                    _Section('DATA', [
                      _Row(
                        icon: Icons.file_download_outlined,
                        title: 'Export data',
                        loading: _exporting,
                        onTap: _export,
                      ),
                      _Row(
                        icon: Icons.inventory_2_outlined,
                        title: 'Archived items',
                        value: '${c.archived.length}',
                        onTap: () =>
                            _push(context, c, _ArchivedScreen(controller: c)),
                      ),
                      _Row(
                        icon: Icons.auto_delete_outlined,
                        title: 'Delete expired temporary items',
                        trailing: _LNSwitch(
                          label: 'Delete expired temporary items',
                          value: c.autoCleanExpired,
                          onChanged: (v) {
                            c.setAutoCleanExpired(v);
                            _snack(
                              context,
                              v
                                  ? 'Expired temporary items will be removed automatically.'
                                  : 'Automatic cleanup is off.',
                            );
                          },
                        ),
                        onTap: () => c.setAutoCleanExpired(!c.autoCleanExpired),
                      ),
                      _Row(
                        icon: Icons.delete_outline_rounded,
                        title: 'Reset sample data',
                        onTap: _resetSample,
                      ),
                    ]),

                    _Section('ABOUT', [
                      _Row(
                        icon: Icons.history_rounded,
                        title: 'About LifeNest',
                        value: 'v$kAppVersion',
                        onTap: () => _push(context, c, const _AboutScreen()),
                      ),
                      _Row(
                        icon: Icons.verified_user_outlined,
                        title: 'Privacy',
                        onTap: () => _push(context, c, const _PrivacyScreen()),
                      ),
                      _Row(
                        icon: Icons.description_outlined,
                        title: 'Terms',
                        onTap: () => _push(context, c, const _TermsScreen()),
                      ),
                      _Row(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & FAQ',
                        onTap: () => _push(context, c, const _HelpScreen()),
                      ),
                    ]),

                    const SizedBox(height: 6),
                    Center(
                      child: TextButton.icon(
                        onPressed: _signOut,
                        icon: Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: p.destructive,
                        ),
                        label: Text(
                          'Sign out',
                          style: p.t(
                            15,
                            w: FontWeight.w600,
                            color: p.destructive,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(140, 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _BrandFooter(),
                  ],
                ),
              ),
            ),
            if (!keyboardOpen)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomSafe + 10,
                child: _BottomNav(
                  onHome: widget.onHome,
                  onInbox: widget.onInbox,
                  onBrowse: widget.onBrowse,
                  onAdd: widget.onAdd,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Reusable widgets
// ===========================================================================

class _Section extends StatelessWidget {
  const _Section(this.title, this.rows);

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: p.separator,
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title,
              style: p.t(
                11.5,
                w: FontWeight.w600,
                color: p.muted,
                spacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Material(
                color: Colors.transparent,
                child: Column(children: children),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.value,
    this.valueMaxWidth = 130,
    this.trailing,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final double valueMaxWidth;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: p.icon),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: p.t(15, height: 1.25))),
              if (value != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: valueMaxWidth),
                  child: Text(
                    value!,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: p.t(13, color: p.muted, height: 1.25),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: p.icon,
                  ),
                )
              else if (trailing != null)
                trailing!
              else
                Icon(Icons.chevron_right_rounded, size: 20, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LNSwitch extends StatelessWidget {
  const _LNSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return Semantics(
      label: label,
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 50,
            height: 30,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? p.primary : p.track,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
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

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    const options = <(ThemeMode, String, IconData)>[
      (ThemeMode.system, 'System', Icons.auto_awesome_outlined),
      (ThemeMode.light, 'Light', Icons.wb_sunny_outlined),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Semantics(
                button: true,
                selected: mode == options[i].$1,
                label: '${options[i].$2} theme',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(options[i].$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 46,
                    decoration: BoxDecoration(
                      color: mode == options[i].$1 ? p.primary : p.neutral,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          options[i].$3,
                          size: 17,
                          color: mode == options[i].$1 ? Colors.white : p.icon,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          options[i].$2,
                          style: p.t(
                            13.5,
                            w: FontWeight.w600,
                            color: mode == options[i].$1
                                ? Colors.white
                                : p.icon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: _NestLogoPainter(p.icon)),
            ),
            const SizedBox(width: 8),
            Text(
              'LifeNest',
              style: p.t(19, w: FontWeight.w800, color: p.icon, spacing: -0.3),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Capture today. A calmer tomorrow.', style: p.script(19)),
      ],
    );
  }
}

class _NestLogoPainter extends CustomPainter {
  const _NestLogoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.5, s * 0.52), radius: s * 0.34),
      0.25,
      2.65,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.13
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.22),
      s * 0.11,
      Paint()..color = const Color(0xFFE9795A),
    );
    canvas.drawCircle(
      Offset(s * 0.2, s * 0.4),
      s * 0.05,
      Paint()..color = const Color(0xFF5E9B6F),
    );
  }

  @override
  bool shouldRepaint(covariant _NestLogoPainter old) => old.color != color;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({this.onHome, this.onInbox, this.onBrowse, this.onAdd});

  final VoidCallback? onHome;
  final VoidCallback? onInbox;
  final VoidCallback? onBrowse;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);

    Widget item(
      IconData icon,
      String label,
      VoidCallback? onTap, {
      bool selected = false,
    }) {
      final color = selected ? p.icon : p.muted;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: p.t(
                  11.5,
                  w: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: p.card,
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
          item(Icons.home_outlined, 'Home', onHome),
          item(Icons.inbox_outlined, 'Inbox', onInbox),
          Expanded(
            child: Center(
              child: Semantics(
                button: true,
                label: 'Add',
                child: Material(
                  color: p.primary,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onAdd,
                    child: const SizedBox(
                      width: 66,
                      height: 66,
                      child: Icon(
                        Icons.add_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          item(Icons.explore_outlined, 'Browse', onBrowse),
          item(Icons.settings_rounded, 'Settings', null, selected: true),
        ],
      ),
    );
  }
}

// ===========================================================================
// Sub-pages
// ===========================================================================

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.title,
    required this.child,
    this.scroll = true,
  });

  final String title;
  final Widget child;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Material(
            color: p.card,
            shape: CircleBorder(side: BorderSide(color: p.separator)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 26,
                  color: p.icon,
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
              style: p.t(22, w: FontWeight.w800, color: p.icon, spacing: -0.4),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: scroll
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      child: child,
                    )
                  : child,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Profile ---------------------------------------------------------------

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen({required this.controller});
  final SettingsController controller;

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  late final _name = TextEditingController(text: widget.controller.name);
  late final _email = TextEditingController(text: widget.controller.email);
  String? _nameError;
  String? _emailError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(() {
      _nameError = name.isEmpty ? 'Please enter your name' : null;
      _emailError = validEmail ? null : 'Enter a valid email address';
    });
    if (_nameError != null || _emailError != null) return;
    widget.controller.updateProfile(name, email);
    _snack(context, 'Profile updated.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    InputDecoration dec(String label, String? error) => InputDecoration(
      labelText: label,
      errorText: error,
      filled: true,
      fillColor: p.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );

    return _PageScaffold(
      title: 'Profile',
      child: Column(
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 36,
            backgroundColor: p.primary,
            child: Text(
              _name.text.trim().isEmpty
                  ? 'A'
                  : _name.text.trim()[0].toUpperCase(),
              style: p.t(28, w: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: dec('Name', _nameError),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: dec('Email', _emailError),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'Save changes',
                style: p.t(15.5, w: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Attachments -----------------------------------------------------------

IconData _fileIcon(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' => Icons.image_outlined,
    _ => Icons.description_outlined,
  };
}

class _AttachmentsScreen extends StatelessWidget {
  const _AttachmentsScreen({required this.controller});
  final SettingsController controller;

  Future<void> _remove(BuildContext context, StoredFile f) async {
    final ok = await _confirm(
      context,
      title: 'Remove this file?',
      message: '"${f.name}" will be removed from your attachments.',
      confirm: 'Remove',
    );
    if (ok) controller.removeAttachment(f.id);
  }

  Future<void> _inspect(BuildContext context, StoredFile f) async {
    final p = _P.of(context);
    final remove = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: p.bg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(k, style: p.t(13.5, color: p.muted)),
              ),
              Expanded(
                child: Text(v, style: p.t(14.5, w: FontWeight.w600)),
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
                    Icon(_fileIcon(f.name), size: 30, color: p.icon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f.name,
                        style: p.t(18, w: FontWeight.w800, height: 1.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                row('Size', _formatBytes(f.bytes)),
                row('Added', _formatDate(f.added)),
                if (f.isSample) row('Type', 'Sample file'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('Remove file'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.destructive,
                      side: BorderSide(color: p.separator),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (remove == true && context.mounted) await _remove(context, f);
  }

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final files = controller.attachments;
        final total = files.fold<int>(0, (s, f) => s + f.bytes);
        return _PageScaffold(
          title: 'Attachments',
          child: files.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'No attachments stored.',
                      style: p.t(14, color: p.muted),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 10),
                      child: Text(
                        '${controller.attachmentsLabel} · ${_formatBytes(total)}',
                        style: p.t(13, color: p.muted),
                      ),
                    ),
                    _Section('FILES', [
                      for (final f in files)
                        InkWell(
                          onTap: () => _inspect(context, f),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _fileIcon(f.name),
                                  size: 22,
                                  color: p.icon,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: p.t(14.5, w: FontWeight.w600),
                                      ),
                                      Text(
                                        '${_formatBytes(f.bytes)} · ${_formatDate(f.added)}',
                                        style: p.t(12, color: p.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: () => _remove(context, f),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 21,
                                    color: p.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ]),
                  ],
                ),
        );
      },
    );
  }
}

// --- Sensitive items -------------------------------------------------------

class _SensitiveScreen extends StatelessWidget {
  const _SensitiveScreen({required this.controller});
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _PageScaffold(
        title: 'Sensitive items',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 16),
              child: Text(
                'Control how items you mark as sensitive appear around LifeNest.',
                style: p.t(14, color: p.muted, height: 1.4),
              ),
            ),
            _Section('VISIBILITY', [
              _Row(
                icon: Icons.search_off_rounded,
                title: 'Hide from search',
                trailing: _LNSwitch(
                  label: 'Hide sensitive items from search',
                  value: controller.hideFromSearch,
                  onChanged: controller.setHideFromSearch,
                ),
                onTap: () =>
                    controller.setHideFromSearch(!controller.hideFromSearch),
              ),
              _Row(
                icon: Icons.visibility_off_outlined,
                title: 'Hide in notification previews',
                trailing: _LNSwitch(
                  label: 'Hide sensitive items in notification previews',
                  value: controller.hideNotificationPreviews,
                  onChanged: controller.setHideNotificationPreviews,
                ),
                onTap: () => controller.setHideNotificationPreviews(
                  !controller.hideNotificationPreviews,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// --- Archived ----------------------------------------------------------------

class _ArchivedScreen extends StatelessWidget {
  const _ArchivedScreen({required this.controller});
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.archived;
        return _PageScaffold(
          title: 'Archived items',
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color: p.muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nothing archived yet.',
                        style: p.t(14, color: p.muted),
                      ),
                    ],
                  ),
                )
              : _Section('ARCHIVED', [
                  for (var i = 0; i < items.length; i++)
                    _Row(
                      icon: Icons.inventory_2_outlined,
                      title: items[i],
                      trailing: TextButton(
                        onPressed: () => controller.restoreArchived(i),
                        child: Text(
                          'Restore',
                          style: p.t(13.5, w: FontWeight.w700, color: p.icon),
                        ),
                      ),
                    ),
                ]),
        );
      },
    );
  }
}

// --- Info pages --------------------------------------------------------------

class _InfoScreen extends StatelessWidget {
  const _InfoScreen({required this.title, required this.sections});

  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return _PageScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in sections) ...[
            Text(
              s.$1,
              style: p.t(16, w: FontWeight.w800, color: p.icon),
            ),
            const SizedBox(height: 6),
            Text(s.$2, style: p.t(14, color: p.muted, height: 1.5)),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  // TODO: replace with your real privacy policy text or link.
  @override
  Widget build(BuildContext context) => const _InfoScreen(
    title: 'Privacy',
    sections: [
      (
        'You choose what we see',
        'LifeNest only accesses the files you choose to add. Nothing is read from your device in the background.',
      ),
      (
        'Your data stays private',
        'Your items are stored securely and are never sold. You can export or remove your data at any time from Settings.',
      ),
      (
        'Locks and sensitive items',
        'Protect the app with a biometric lock or PIN, and keep sensitive items out of search and notification previews.',
      ),
    ],
  );
}

class _TermsScreen extends StatelessWidget {
  const _TermsScreen();

  // TODO: replace with your real terms and conditions.
  @override
  Widget build(BuildContext context) => const _InfoScreen(
    title: 'Terms',
    sections: [
      (
        'Terms of use',
        'Add your terms and conditions here, or link to the hosted version on your website.',
      ),
    ],
  );
}

class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  static const _faqs = <(String, String)>[
    (
      'How do I add something?',
      'Tap the + button, choose a photo, document, link, note, voice note or list, then pick a category.',
    ),
    (
      'How do reminders work?',
      'Add a date to an item and turn on a reminder. Change how early you are reminded in Settings > Reminder preferences.',
    ),
    (
      'Can I keep sensitive items private?',
      'Yes. Turn on a biometric lock or PIN, and use Sensitive items to hide them from search and notification previews.',
    ),
    (
      'How do I export my data?',
      'Go to Settings > Export data to save a copy of your information as a file.',
    ),
    ('How do I contact support?', 'Add your support email or link here.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return _PageScaffold(
      title: 'Help & FAQ',
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              for (final f in _faqs)
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    iconColor: p.icon,
                    collapsedIconColor: p.muted,
                    title: Text(f.$1, style: p.t(14.5, w: FontWeight.w600)),
                    children: [
                      Text(f.$2, style: p.t(13.5, color: p.muted, height: 1.5)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return _PageScaffold(
      title: 'About LifeNest',
      child: Column(
        children: [
          const SizedBox(height: 16),
          const _BrandFooter(),
          const SizedBox(height: 20),
          Text('Version $kAppVersion', style: p.t(14, color: p.muted)),
          const SizedBox(height: 16),
          Text(
            'A calm place to capture, organise and remember the parts of life that matter.',
            textAlign: TextAlign.center,
            style: p.t(14, color: p.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'LifeNest',
              applicationVersion: kAppVersion,
            ),
            child: Text(
              'Open-source licences',
              style: p.t(14, w: FontWeight.w700, color: p.icon),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// PIN pad, PIN flows, and the app lock gate
// ===========================================================================

class _PinPad extends StatefulWidget {
  const _PinPad({
    super.key,
    required this.title,
    required this.onComplete,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  /// Return an error message to show, or null if the PIN was accepted.
  final Future<String?> Function(String pin) onComplete;

  @override
  State<_PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<_PinPad> {
  String _pin = '';
  String? _error;
  bool _busy = false;

  Future<void> _tap(String d) async {
    if (_busy || _pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) {
      _busy = true;
      final err = await widget.onComplete(_pin);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = err;
        _pin = '';
      });
    }
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);

    Widget key(String label) => Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: p.neutral,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _tap(label),
          child: SizedBox(
            width: 68,
            height: 68,
            child: Center(
              child: Text(label, style: p.t(24, w: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: p.t(20, w: FontWeight.w800, color: p.icon),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: p.t(13.5, color: p.muted),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? p.primary : p.track,
                ),
              ),
          ],
        ),
        SizedBox(
          height: 30,
          child: Center(
            child: Text(
              _error ?? '',
              style: p.t(13, color: p.destructive, w: FontWeight.w600),
            ),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) key(d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 80),
            key('0'),
            Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                width: 68,
                height: 68,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _back,
                  child: Icon(Icons.backspace_outlined, color: p.muted),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinSetupScreen extends StatefulWidget {
  const _PinSetupScreen({required this.controller});
  final SettingsController controller;

  @override
  State<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<_PinSetupScreen> {
  String? _first;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'App PIN',
      scroll: false,
      child: Center(
        child: SingleChildScrollView(
          child: _PinPad(
            key: ValueKey(_first == null ? 'create' : 'confirm'),
            title: _first == null ? 'Create a 4-digit PIN' : 'Confirm your PIN',
            subtitle: _first == null
                ? "You'll use it to unlock LifeNest."
                : 'Enter the same PIN again.',
            onComplete: (pin) async {
              if (_first == null) {
                setState(() => _first = pin);
                return null;
              }
              if (pin != _first) {
                setState(() => _first = null);
                return "PINs didn't match. Try again.";
              }
              await widget.controller.setPin(pin);
              if (mounted) Navigator.pop(context, true);
              return null;
            },
          ),
        ),
      ),
    );
  }
}

class _PinVerifyScreen extends StatelessWidget {
  const _PinVerifyScreen({required this.controller, required this.title});

  final SettingsController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'App PIN',
      scroll: false,
      child: Center(
        child: SingleChildScrollView(
          child: _PinPad(
            title: title,
            onComplete: (pin) async {
              if (await controller.verifyPin(pin)) {
                if (context.mounted) Navigator.pop(context, true);
                return null;
              }
              return 'Incorrect PIN';
            },
          ),
        ),
      ),
    );
  }
}

/// Wrap your app with this (MaterialApp.builder) so the biometric lock and PIN
/// are actually enforced when the app opens and after it has been in the
/// background for a short while.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.controller, required this.child});

  final SettingsController controller;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  static const _relockAfter = Duration(seconds: 15);

  bool _locked = false;
  DateTime? _pausedAt;

  bool get _enabled =>
      widget.controller.biometricEnabled || widget.controller.pinEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = _enabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null
          ? Duration.zero
          : DateTime.now().difference(_pausedAt!);
      if (_enabled && away >= _relockAfter && !_locked) {
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: _LockScreen(
              controller: widget.controller,
              onUnlocked: () => setState(() => _locked = false),
            ),
          ),
      ],
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen({required this.controller, required this.onUnlocked});

  final SettingsController controller;
  final VoidCallback onUnlocked;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.controller.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
    }
  }

  Future<void> _biometric() async {
    final r = await authenticateBiometric('Unlock LifeNest');
    if (!mounted) return;
    if (r == BiometricResult.success) {
      widget.onUnlocked();
    } else {
      setState(
        () => _message = r == BiometricResult.unavailable
            ? "Biometrics aren't available right now."
            : 'Not recognised. Try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final c = widget.controller;
    return Material(
      color: p.bg,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BrandFooter(),
                const SizedBox(height: 32),
                if (c.pinEnabled)
                  _PinPad(
                    title: 'Enter your PIN',
                    onComplete: (pin) async {
                      if (await c.verifyPin(pin)) {
                        widget.onUnlocked();
                        return null;
                      }
                      return 'Incorrect PIN';
                    },
                  )
                else
                  Text(
                    'LifeNest is locked',
                    style: p.t(20, w: FontWeight.w800, color: p.icon),
                  ),
                if (c.biometricEnabled) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _biometric,
                    icon: Icon(Icons.fingerprint_rounded, color: p.icon),
                    label: Text(
                      'Use biometrics',
                      style: p.t(14.5, w: FontWeight.w700, color: p.icon),
                    ),
                  ),
                  if (_message != null)
                    Text(_message!, style: p.t(13, color: p.muted)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
