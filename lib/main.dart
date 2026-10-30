import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ToatApp());
}

// ============================================================================
// RANGLAR PALITRASI
// ============================================================================
class AppColors {
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);
  static const Color emerald950 = Color(0xFF022C22);
  static const Color teal800 = Color(0xFF115E59);

  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);

  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green400 = Color(0xFF4ADE80);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);

  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
}

// ============================================================================
// MA'LUMOT MODELLARI
// ============================================================================
class CityData {
  final String key;
  final String name;
  final Map<String, String> fallbackTimes;

  const CityData({
    required this.key,
    required this.name,
    required this.fallbackTimes,
  });
}

class PrayerItem {
  final String id;
  final String name;
  final IconData icon;

  const PrayerItem({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class QazoItem {
  final String id;
  final String name;
  final String rakatInfo;

  const QazoItem({
    required this.id,
    required this.name,
    required this.rakatInfo,
  });
}

class ZikrModel {
  final String id;
  final String title;
  final String arabic;
  final String meaning;
  int count;
  int target; // 0 = Cheksiz (∞), 33, 99, 100
  final bool isCustom;

  ZikrModel({
    required this.id,
    required this.title,
    required this.arabic,
    required this.meaning,
    required this.count,
    required this.target,
    required this.isCustom,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'arabic': arabic,
        'meaning': meaning,
        'count': count,
        'target': target,
        'isCustom': isCustom,
      };

  factory ZikrModel.fromJson(Map<String, dynamic> json) => ZikrModel(
        id: json['id'] as String,
        title: json['title'] as String,
        arabic: (json['arabic'] ?? '') as String,
        meaning: (json['meaning'] ?? '') as String,
        count: (json['count'] ?? 0) as int,
        target: (json['target'] ?? 33) as int,
        isCustom: (json['isCustom'] ?? false) as bool,
      );
}

// ============================================================================
// ASOSIY ILOVA QOBIG'I
// ============================================================================
class ToatApp extends StatelessWidget {
  const ToatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme();
    return MaterialApp(
      title: 'Toat — Namoz, Qazo va Zikr Kundaligi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.slate50,
        textTheme: baseTextTheme,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),(
          seedColor: AppColors.emerald700,
          surface: AppColors.slate50,
        ),
      ),
      home: const ToatHomeScreen(),
    );
  }
}

// ============================================================================
// ISLOMIY NAQSH PAINTER (CustomPainter)
// ============================================================================
class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald700.withOpacity(0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    const double step = 36.0;
    for (double y = 0; y <= size.height + step; y += step) {
      for (double x = 0; x <= size.width + step; x += step) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: step * 0.45),
          0,
          math.pi,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(x + step / 2, y + step / 2),
            radius: step * 0.45,
          ),
          math.pi,
          math.pi,
          false,
          paint,
        );
        canvas.drawCircle(
          Offset(x + step / 2, y),
          2.2,
          Paint()
            ..color = AppColors.emerald700.withOpacity(0.35)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// HILOL VA YULDUZCHA IKONKASI CHIZUVCHI (CustomPainter)
// ============================================================================
class CrescentStarIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CrescentStarIcon({
    super.key,
    this.size = 22,
    this.color = AppColors.amber300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrescentStarPainter(color: color),
      ),
    );
  }
}

class _CrescentStarPainter extends CustomPainter {
  final Color color;
  _CrescentStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    final Path outerCircle = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.46, h * 0.52), radius: w * 0.36));
    final Path innerCircle = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.58, h * 0.43), radius: w * 0.30));

    final Path crescent = Path.combine(PathOperation.difference, outerCircle, innerCircle);
    canvas.drawPath(crescent, paint);

    // Yulduzcha
    final Offset starCenter = Offset(w * 0.72, h * 0.28);
    final double outerR = w * 0.13;
    final double innerR = w * 0.055;
    final Path star = Path();
    for (int i = 0; i < 10; i++) {
      final double angle = -math.pi / 2 + i * math.pi / 5;
      final double r = i.isEven ? outerR : innerR;
      final double px = starCenter.dx + r * math.cos(angle);
      final double py = starCenter.dy + r * math.sin(angle);
      if (i == 0) {
        star.moveTo(px, py);
      } else {
        star.lineTo(px, py);
      }
    }
    star.close();
    canvas.drawPath(star, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// BOSH EKRAN VA BARCHA MANTIQLAR
// ============================================================================
class ToatHomeScreen extends StatefulWidget {
  const ToatHomeScreen({super.key});

  @override
  State<ToatHomeScreen> createState() => _ToatHomeScreenState();
}

class _ToatHomeScreenState extends State<ToatHomeScreen>
    with TickerProviderStateMixin {
  // 14 ta shahar va zaxira namoz vaqtlari
  static const List<CityData> cities = [
    CityData(
      key: 'Fergana',
      name: "Farg'ona",
      fallbackTimes: {
        'bomdod': '04:55',
        'peshin': '12:48',
        'asr': '16:35',
        'shom': '18:22',
        'xufton': '19:40',
      },
    ),
    CityData(
      key: 'Margilan',
      name: "Marg'ilon",
      fallbackTimes: {
        'bomdod': '04:55',
        'peshin': '12:48',
        'asr': '16:35',
        'shom': '18:22',
        'xufton': '19:40',
      },
    ),
    CityData(
      key: 'Tashkent',
      name: 'Toshkent',
      fallbackTimes: {
        'bomdod': '05:05',
        'peshin': '12:58',
        'asr': '16:44',
        'shom': '18:31',
        'xufton': '19:50',
      },
    ),
    CityData(
      key: 'Andijan',
      name: 'Andijon',
      fallbackTimes: {
        'bomdod': '04:52',
        'peshin': '12:45',
        'asr': '16:32',
        'shom': '18:19',
        'xufton': '19:37',
      },
    ),
    CityData(
      key: 'Namangan',
      name: 'Namangan',
      fallbackTimes: {
        'bomdod': '04:56',
        'peshin': '12:49',
        'asr': '16:36',
        'shom': '18:23',
        'xufton': '19:41',
      },
    ),
    CityData(
      key: 'Samarkand',
      name: 'Samarqand',
      fallbackTimes: {
        'bomdod': '05:15',
        'peshin': '13:07',
        'asr': '16:54',
        'shom': '18:41',
        'xufton': '19:59',
      },
    ),
    CityData(
      key: 'Bukhara',
      name: 'Buxoro',
      fallbackTimes: {
        'bomdod': '05:25',
        'peshin': '13:17',
        'asr': '17:04',
        'shom': '18:51',
        'xufton': '20:09',
      },
    ),
    CityData(
      key: 'Khiva',
      name: 'Xiva',
      fallbackTimes: {
        'bomdod': '05:40',
        'peshin': '13:33',
        'asr': '17:19',
        'shom': '19:06',
        'xufton': '20:25',
      },
    ),
    CityData(
      key: 'Karshi',
      name: 'Qarshi',
      fallbackTimes: {
        'bomdod': '05:20',
        'peshin': '13:11',
        'asr': '16:59',
        'shom': '18:46',
        'xufton': '20:03',
      },
    ),
    CityData(
      key: 'Termez',
      name: 'Termiz',
      fallbackTimes: {
        'bomdod': '05:16',
        'peshin': '13:05',
        'asr': '16:55',
        'shom': '18:42',
        'xufton': '19:58',
      },
    ),
    CityData(
      key: 'Jizzakh',
      name: 'Jizzax',
      fallbackTimes: {
        'bomdod': '05:11',
        'peshin': '13:03',
        'asr': '16:50',
        'shom': '18:37',
        'xufton': '19:55',
      },
    ),
    CityData(
      key: 'Navoi',
      name: 'Navoiy',
      fallbackTimes: {
        'bomdod': '05:21',
        'peshin': '13:13',
        'asr': '17:00',
        'shom': '18:47',
        'xufton': '20:05',
      },
    ),
    CityData(
      key: 'Gulistan',
      name: 'Guliston',
      fallbackTimes: {
        'bomdod': '05:07',
        'peshin': '13:00',
        'asr': '16:46',
        'shom': '18:33',
        'xufton': '19:51',
      },
    ),
    CityData(
      key: 'Nukus',
      name: 'Nukus',
      fallbackTimes: {
        'bomdod': '05:44',
        'peshin': '13:37',
        'asr': '17:22',
        'shom': '19:10',
        'xufton': '20:29',
      },
    ),
  ];

  static const List<PrayerItem> dailyPrayers = [
    PrayerItem(id: 'bomdod', name: 'Bomdod', icon: Icons.wb_twilight_rounded),
    PrayerItem(id: 'peshin', name: 'Peshin', icon: Icons.wb_sunny_rounded),
    PrayerItem(id: 'asr', name: 'Asr', icon: Icons.light_mode_outlined),
    PrayerItem(id: 'shom', name: 'Shom', icon: Icons.nights_stay_outlined),
    PrayerItem(id: 'xufton', name: 'Xufton', icon: Icons.dark_mode_rounded),
  ];

  static const List<QazoItem> qazoItems = [
    QazoItem(id: 'bomdod', name: 'Bomdod namozi', rakatInfo: '2 rakat farz'),
    QazoItem(id: 'peshin', name: 'Peshin namozi', rakatInfo: '4 rakat farz'),
    QazoItem(id: 'asr', name: 'Asr namozi', rakatInfo: '4 rakat farz'),
    QazoItem(id: 'shom', name: 'Shom namozi', rakatInfo: '3 rakat farz'),
    QazoItem(id: 'xufton', name: 'Xufton namozi', rakatInfo: '4 rakat farz'),
    QazoItem(id: 'vitr', name: 'Vitr vojib', rakatInfo: '3 rakat vojib'),
  ];

  static List<ZikrModel> defaultZikrs() => [
        ZikrModel(
          id: 'zikr_1',
          title: "Alhamdulillahir robbil 'alamin",
          arabic: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
          meaning: "Barcha hamdu sanolar olamlarning Robbi Allohga xosdir",
          count: 0,
          target: 33,
          isCustom: false,
        ),
        ZikrModel(
          id: 'zikr_2',
          title: "Astag'firulloha va atubu ilayh",
          arabic: "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ",
          meaning: "Allohdan mag'firat so'rayman va Unga tavba qilaman",
          count: 0,
          target: 100,
          isCustom: false,
        ),
        ZikrModel(
          id: 'zikr_3',
          title: "Allohumma solli 'ala sayyidina Muhammad",
          arabic: "اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ",
          meaning:
              "Ey Allohim, sayyidimiz Muhammad alayhissalomga salovat va rahmat yubor",
          count: 0,
          target: 33,
          isCustom: false,
        ),
        ZikrModel(
          id: 'zikr_4',
          title: "Hasbunallohu va ni'mal vakiyl",
          arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ",
          meaning: "Bizga Allohning O'zi yetarli va U naqadar go'zal Vakildir",
          count: 0,
          target: 33,
          isCustom: false,
        ),
      ];

  int _activeTab = 0; // 0: kundalik, 1: qazolar, 2: zikrlar
  bool _soundEnabled = true;
  bool _isOnline = true;
  String _selectedCityKey = 'Fergana';
  String _timesStatusText = '• Saqlangan vaqtlar';
  DateTime _now = DateTime.now();
  String _lastSavedDateKey = '';

  Map<String, String> _prayerTimes = {
    'bomdod': '04:55',
    'peshin': '12:48',
    'asr': '16:35',
    'shom': '18:22',
    'xufton': '19:40',
  };

  // null = Belgilanmagan, 'done' = O'qidim, 'qazo' = Qazo
  Map<String, String?> _dailyStatus = {
    'bomdod': null,
    'peshin': null,
    'asr': null,
    'shom': null,
    'xufton': null,
  };

  Map<String, int> _qazoCounts = {
    'bomdod': 0,
    'peshin': 0,
    'asr': 0,
    'shom': 0,
    'xufton': 0,
    'vitr': 0,
  };

  List<ZikrModel> _zikrs = [];
  String? _pressedZikrId;
  String? _poppedZikrId;

  // Maxsus Toast holati
  String? _toastMessage;
  Timer? _toastTimer;
  Timer? _periodicTimer;
  late AnimationController _pulseController;
  final ScrollController _dailyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _zikrs = defaultZikrs();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _loadStateFromPrefs();

    // Har 15 soniyada vaqt, joriy namoz oynasi va yangi kun (00:00) tekshiriladi
    _periodicTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkTimeAndNewDay();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _periodicTimer?.cancel();
    _pulseController.dispose();
    _dailyScrollController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // XOTIRADAN O'QISH VA YOZISH (shared_preferences)
  // ==========================================================================
  String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _formatDateKey(DateTime.now());

    setState(() {
      _soundEnabled = prefs.getBool('toat_sound_enabled') ?? true;
      _selectedCityKey = prefs.getString('toat_selected_city') ?? 'Fergana';
      _lastSavedDateKey = prefs.getString('toat_last_date') ?? todayKey;

      // Shahar zaxira vaqtlarini o'rnatish
      final city = cities.firstWhere(
        (c) => c.key == _selectedCityKey,
        orElse: () => cities.first,
      );
      _prayerTimes = Map<String, String>.from(city.fallbackTimes);

      // Keshdagi namoz vaqtlarini o'qish
      final cachedTimesJson =
          prefs.getString('toat_cached_times_$_selectedCityKey');
      if (cachedTimesJson != null) {
        try {
          final decoded = Map<String, dynamic>.from(jsonDecode(cachedTimesJson));
          _prayerTimes = decoded.map((k, v) => MapEntry(k, v.toString()));
          _timesStatusText = '• Saqlangan vaqtlar';
        } catch (_) {
          _timesStatusText = '• Ichki taqvim';
        }
      } else {
        _timesStatusText = '• Ichki taqvim';
      }

      // Yangi kun (00:00) tekshiruvi
      if (_lastSavedDateKey != todayKey) {
        _dailyStatus = {
          'bomdod': null,
          'peshin': null,
          'asr': null,
          'shom': null,
          'xufton': null,
        };
        _lastSavedDateKey = todayKey;
        prefs.setString('toat_last_date', todayKey);
        prefs.setString('toat_daily_status', jsonEncode(_dailyStatus));
      } else {
        final dailyJson = prefs.getString('toat_daily_status');
        if (dailyJson != null) {
          try {
            final decoded = Map<String, dynamic>.from(jsonDecode(dailyJson));
            _dailyStatus = {
              'bomdod': decoded['bomdod'] as String?,
              'peshin': decoded['peshin'] as String?,
              'asr': decoded['asr'] as String?,
              'shom': decoded['shom'] as String?,
              'xufton': decoded['xufton'] as String?,
            };
          } catch (_) {}
        }
      }

      // Qazolarni o'qish
      final qazoJson = prefs.getString('toat_qazo_counts');
      if (qazoJson != null) {
        try {
          final decoded = Map<String, dynamic>.from(jsonDecode(qazoJson));
          for (final item in qazoItems) {
            _qazoCounts[item.id] = (decoded[item.id] ?? 0) as int;
          }
        } catch (_) {}
      }

      // Zikrlarni o'qish
      final zikrJson = prefs.getString('toat_zikrs_list');
      if (zikrJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(zikrJson);
          if (decoded.isNotEmpty) {
            _zikrs = decoded
                .map((e) => ZikrModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
        } catch (_) {}
      }
    });

    await _fetchPrayerTimesFromApi(_selectedCityKey);
  }

  Future<void> _saveStateToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('toat_sound_enabled', _soundEnabled);
    await prefs.setString('toat_selected_city', _selectedCityKey);
    await prefs.setString('toat_last_date', _lastSavedDateKey);
    await prefs.setString('toat_daily_status', jsonEncode(_dailyStatus));
    await prefs.setString('toat_qazo_counts', jsonEncode(_qazoCounts));
    await prefs.setString(
      'toat_zikrs_list',
      jsonEncode(_zikrs.map((z) => z.toJson()).toList()),
    );
  }

  void _checkTimeAndNewDay() {
    final currentNow = DateTime.now();
    final todayKey = _formatDateKey(currentNow);
    bool dateChanged = false;

    if (_lastSavedDateKey.isNotEmpty && _lastSavedDateKey != todayKey) {
      dateChanged = true;
      _lastSavedDateKey = todayKey;
      _dailyStatus = {
        'bomdod': null,
        'peshin': null,
        'asr': null,
        'shom': null,
        'xufton': null,
      };
    }

    setState(() {
      _now = currentNow;
    });

    if (dateChanged) {
      _saveStateToPrefs();
      _showToast("Yangi kun boshlandi! Kundalik namozlar yangilandi.");
    }
  }

  // ==========================================================================
  // ALADHAN API ORQALI NAMOZ VAQTLARINI TORTISH VA KESHLASH
  // ==========================================================================
  String _cleanTime(String raw) {
    final match = RegExp(r'(\d{2}:\d{2})').firstMatch(raw);
    return match != null ? match.group(1)! : raw;
  }

  Future<void> _fetchPrayerTimesFromApi(String cityKey) async {
    setState(() {
      _timesStatusText = '• Vaqtlar yuklanmoqda...';
    });

    final city = cities.firstWhere(
      (c) => c.key == cityKey,
      orElse: () => cities.first,
    );

    final url = Uri.parse(
      'https://api.aladhan.com/v1/timingsByCity?city=$cityKey&country=Uzbekistan&method=3&school=1',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final timings = body['data']?['timings'];
        if (timings != null) {
          final updatedTimes = <String, String>{
            'bomdod': _cleanTime(
                timings['Fajr']?.toString() ?? city.fallbackTimes['bomdod']!),
            'peshin': _cleanTime(
                timings['Dhuhr']?.toString() ?? city.fallbackTimes['peshin']!),
            'asr': _cleanTime(
                timings['Asr']?.toString() ?? city.fallbackTimes['asr']!),
            'shom': _cleanTime(
                timings['Maghrib']?.toString() ?? city.fallbackTimes['shom']!),
            'xufton': _cleanTime(
                timings['Isha']?.toString() ?? city.fallbackTimes['xufton']!),
          };

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'toat_cached_times_$cityKey',
            jsonEncode(updatedTimes),
          );

          if (!mounted) return;
          setState(() {
            _isOnline = true;
            _prayerTimes = updatedTimes;
            _timesStatusText = '• Onlayn yangilangan';
          });
          return;
        }
      }
      throw Exception('API xatosi');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('toat_cached_times_$cityKey');
      if (!mounted) return;

      if (cached != null) {
        try {
          final decoded = Map<String, dynamic>.from(jsonDecode(cached));
          setState(() {
            _isOnline = false;
            _prayerTimes = decoded.map((k, v) => MapEntry(k, v.toString()));
            _timesStatusText = '• Oflayn (Saqlangan)';
          });
          return;
        } catch (_) {}
      }

      setState(() {
        _isOnline = false;
        _prayerTimes = Map<String, String>.from(city.fallbackTimes);
        _timesStatusText = '• Ichki taqvim';
      });
    }
  }

  // ==========================================================================
  // OVOZ, VIBRATSIYA VA TOAST XABARLARI
  // ==========================================================================
  void _playTasbehFeedback({bool isMilestone = false}) {
    if (isMilestone) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _toggleSound() {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
    _saveStateToPrefs();
    _showToast(
      _soundEnabled ? "Tasbeh ovozi yoqildi" : "Tasbeh ovozi o'chirildi",
    );
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2700), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  // ==========================================================================
  // SANA VA JORIY NAMOZ VAQTINI ANIQLASH MANTIQI
  // ==========================================================================
  String _getUzbekFormattedDate(DateTime dt) {
    const weekdays = [
      'Yakshanba',
      'Dushanba',
      'Seshanba',
      'Chorshanba',
      'Payshanba',
      'Juma',
      'Shanba',
    ];
    const months = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'Iyun',
      'Iyul',
      'Avgust',
      'Sentabr',
      'Oktabr',
      'Noyabr',
      'Dekabr',
    ];
    final weekdayName = weekdays[dt.weekday % 7];
    final monthName = months[dt.month - 1];
    return '$weekdayName, ${dt.day}-$monthName ${dt.year}';
  }

  String _getFormattedClock(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  int _timeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  Map<String, dynamic> _getCurrentAndNextPrayer() {
    final nowMins = _now.hour * 60 + _now.minute;
    final bMins = _timeToMinutes(_prayerTimes['bomdod'] ?? '04:55');
    final pMins = _timeToMinutes(_prayerTimes['peshin'] ?? '12:48');
    final aMins = _timeToMinutes(_prayerTimes['asr'] ?? '16:35');
    final sMins = _timeToMinutes(_prayerTimes['shom'] ?? '18:22');
    final xMins = _timeToMinutes(_prayerTimes['xufton'] ?? '19:40');

    if (nowMins >= bMins && nowMins < pMins) {
      return {
        'currentId': 'bomdod',
        'currentName': 'Bomdod',
        'currentTime': _prayerTimes['bomdod']!,
        'nextName': 'Peshin',
        'nextTime': _prayerTimes['peshin']!,
      };
    } else if (nowMins >= pMins && nowMins < aMins) {
      return {
        'currentId': 'peshin',
        'currentName': 'Peshin',
        'currentTime': _prayerTimes['peshin']!,
        'nextName': 'Asr',
        'nextTime': _prayerTimes['asr']!,
      };
    } else if (nowMins >= aMins && nowMins < sMins) {
      return {
        'currentId': 'asr',
        'currentName': 'Asr',
        'currentTime': _prayerTimes['asr']!,
        'nextName': 'Shom',
        'nextTime': _prayerTimes['shom']!,
      };
    } else if (nowMins >= sMins && nowMins < xMins) {
      return {
        'currentId': 'shom',
        'currentName': 'Shom',
        'currentTime': _prayerTimes['shom']!,
        'nextName': 'Xufton',
        'nextTime': _prayerTimes['xufton']!,
      };
    } else {
      return {
        'currentId': 'xufton',
        'currentName': 'Xufton',
        'currentTime': _prayerTimes['xufton']!,
        'nextName': 'Bomdod',
        'nextTime': _prayerTimes['bomdod']!,
      };
    }
  }

  // ==========================================================================
  // KUNDALIK NAMOZ HOLATINI O'ZGARTIRISH MANTIQI
  // ==========================================================================
  void _setPrayerStatus(String prayerId, String newStatus) {
    final prayerObj = dailyPrayers.firstWhere((p) => p.id == prayerId);
    final oldStatus = _dailyStatus[prayerId];

    if (oldStatus == newStatus) return;

    HapticFeedback.mediumImpact();
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    setState(() {
      _dailyStatus[prayerId] = newStatus;

      if (newStatus == 'done') {
        if (oldStatus == 'qazo') {
          final currentQazo = _qazoCounts[prayerId] ?? 0;
          _qazoCounts[prayerId] = math.max(0, currentQazo - 1);
          _showToast(
            "${prayerObj.name} o'qildi! Qazolar hisobidan -1 qaytarildi",
          );
        } else {
          _showToast("${prayerObj.name} namozi o'qildi deb belgilandi!");
        }
      } else if (newStatus == 'qazo') {
        final currentQazo = _qazoCounts[prayerId] ?? 0;
        _qazoCounts[prayerId] = currentQazo + 1;
        _showToast(
          "${prayerObj.name} qazo bo'ldi. Qazolar bo'limiga +1 qo'shildi",
        );
      }
    });

    _saveStateToPrefs();
  }

  // ==========================================================================
  // QAZOLAR BO'LIMI FUNKSIYALARI
  // ==========================================================================
  int get _totalQazoCount =>
      _qazoCounts.values.fold(0, (sum, item) => sum + item);

  void _changeQazoCount(String id, int delta) {
    final current = _qazoCounts[id] ?? 0;
    if (delta < 0 && current <= 0) return;

    HapticFeedback.lightImpact();
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    final item = qazoItems.firstWhere((e) => e.id == id);
    setState(() {
      _qazoCounts[id] = math.max(0, current + delta);
    });
    _saveStateToPrefs();

    if (delta < 0) {
      _showToast("${item.name}: 1 ta qazo o'qildi (-1)");
    } else {
      _showToast("${item.name}: +1 qazo qo'shildi");
    }
  }

  // ==========================================================================
  // ZIKRLAR (ELEKTRON TASBEH) FUNKSIYALARI
  // ==========================================================================
  int get _totalZikrCount =>
      _zikrs.fold(0, (sum, item) => sum + item.count);

  void _incrementZikr(ZikrModel zikr) {
    setState(() {
      zikr.count += 1;
      _pressedZikrId = zikr.id;
      _poppedZikrId = zikr.id;
    });

    final bool reachedTarget =
        zikr.target > 0 && zikr.count > 0 && zikr.count % zikr.target == 0;

    _playTasbehFeedback(isMilestone: reachedTarget);

    if (reachedTarget) {
      _showToast("Mashalloh! ${zikr.title} ${zikr.count} martaga yetdi!");
    }

    Future.delayed(const Duration(milliseconds: 130), () {
      if (mounted) {
        setState(() {
          _pressedZikrId = null;
          _poppedZikrId = null;
        });
      }
    });

    _saveStateToPrefs();
  }

  void _cycleZikrTarget(ZikrModel zikr) {
    HapticFeedback.selectionClick();
    setState(() {
      if (zikr.target == 33) {
        zikr.target = 99;
      } else if (zikr.target == 99) {
        zikr.target = 100;
      } else if (zikr.target == 100) {
        zikr.target = 0; // Cheksiz (∞)
      } else {
        zikr.target = 33;
      }
    });
    _saveStateToPrefs();
    final targetLabel = zikr.target == 0 ? 'Cheksiz (∞)' : '${zikr.target} ta';
    _showToast("Maqsad o'zgartirildi: $targetLabel");
  }

  void _resetSingleZikr(ZikrModel zikr) {
    HapticFeedback.mediumImpact();
    setState(() {
      zikr.count = 0;
    });
    _saveStateToPrefs();
    _showToast("${zikr.title} hisobi nolga tushirildi");
  }

  void _deleteCustomZikr(ZikrModel zikr) {
    HapticFeedback.mediumImpact();
    setState(() {
      _zikrs.removeWhere((z) => z.id == zikr.id);
    });
    _saveStateToPrefs();
    _showToast("${zikr.title} o'chirildi");
  }

  // ==========================================================================
  // 4 TA MODAL OYNA (DIALOGLAR)
  // ==========================================================================

  // 1-MODAL: Bugungi belgilarni tozalash
  void _showResetDailyModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.red50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.restart_alt_rounded,
                    color: AppColors.red600,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Bugungi belgilarni tozalash",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Bugungi 5 vaqt namoz uchun belgilangan holatlarni boshidan boshlamoqchimisiz? (Qazolar daftaridagi umumiy hisob o'zgarmaydi)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppColors.slate200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Bekor qilish",
                          style: TextStyle(
                            color: AppColors.slate600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _dailyStatus = {
                              'bomdod': null,
                              'peshin': null,
                              'asr': null,
                              'shom': null,
                              'xufton': null,
                            };
                          });
                          _saveStateToPrefs();
                          Navigator.of(ctx).pop();
                          _showToast("Bugungi belgilar tozalandi");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Tozalash",
                          style: TextStyle(fontWeight: FontWeight.w700),
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
  }

  // 2-MODAL: Qazo sonini qo'lda tahrirlash
  void _showEditQazoModal(QazoItem item) {
    final controller = TextEditingController(
      text: (_qazoCounts[item.id] ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.emerald50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.emerald700,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          const Text(
                            "Qazo sonini qo'lda tahrirlash",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                  decoration: InputDecoration(
                    labelText: "Qazo namozlar soni",
                    filled: true,
                    fillColor: AppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.emerald600,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppColors.slate200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Bekor qilish",
                          style: TextStyle(
                            color: AppColors.slate600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final val = int.tryParse(controller.text.trim()) ?? 0;
                          setState(() {
                            _qazoCounts[item.id] = math.max(0, val);
                          });
                          _saveStateToPrefs();
                          Navigator.of(ctx).pop();
                          _showToast(
                            "${item.name} qazo soni ${math.max(0, val)} ta qilib saqlandi",
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Saqlash",
                          style: TextStyle(fontWeight: FontWeight.w700),
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
  }

  // 3-MODAL: Ko'p kunlik qazo qo'shish
  void _showAddBulkQazoDaysModal() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.amber50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calculate_rounded,
                        color: AppColors.amber700,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ko'p kunlik qazo qo'shish",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          Text(
                            "Barcha 6 ta namozga teng qo'shiladi",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                  decoration: InputDecoration(
                    hintText: "Kunlar sonini kiriting (masalan: 30)",
                    filled: true,
                    fillColor: AppColors.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.emerald600,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [1, 7, 30, 365].map((d) {
                    return ActionChip(
                      backgroundColor: AppColors.amber50,
                      side: const BorderSide(color: AppColors.amber200),
                      label: Text(
                        '+$d kun',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber800,
                        ),
                      ),
                      onPressed: () {
                        controller.text = d.toString();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppColors.slate200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Bekor qilish",
                          style: TextStyle(
                            color: AppColors.slate600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final days =
                              int.tryParse(controller.text.trim()) ?? 0;
                          if (days <= 0) {
                            _showToast("Iltimos, to'g'ri kun sonini kiriting");
                            return;
                          }
                          setState(() {
                            for (final item in qazoItems) {
                              _qazoCounts[item.id] =
                                  (_qazoCounts[item.id] ?? 0) + days;
                            }
                          });
                          _saveStateToPrefs();
                          Navigator.of(ctx).pop();
                          _showToast(
                            "Barcha 6 ta namozga +$days kunlik qazo qo'shildi",
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Qo'shish",
                          style: TextStyle(fontWeight: FontWeight.w700),
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
  }

  // 4-MODAL: Yangi zikr qo'shish
  void _showAddZikrModal() {
    final titleCtrl = TextEditingController();
    final arabicCtrl = TextEditingController();
    final meaningCtrl = TextEditingController();
    int selectedTarget = 33;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.emerald50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_task_rounded,
                            color: AppColors.emerald700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Yangi zikr qo'shish",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate900,
                                ),
                              ),
                              Text(
                                "Shaxsiy tasbeh ro'yxatiga qo'shish",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Zikr matni *",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: "Masalan: Subhanallohi va bihamdihi",
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.slate200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Arabcha yozuvi",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: arabicCtrl,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(fontSize: 20, height: 1.6),
                      decoration: InputDecoration(
                        hintText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.slate200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Ma'nosi",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: meaningCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            "Allohni poklab yod etaman va Unga hamd aytaman",
                        filled: true,
                        fillColor: AppColors.slate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.slate200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Maqsad soni",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        {'label': '33', 'value': 33},
                        {'label': '99', 'value': 99},
                        {'label': '100', 'value': 100},
                        {'label': 'Cheksiz', 'value': 0},
                      ].map((opt) {
                        final int val = opt['value'] as int;
                        final bool isSelected = selectedTarget == val;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setModalState(() {
                                  selectedTarget = val;
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.emerald700
                                      : AppColors.slate100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  opt['label'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.slate700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(color: AppColors.slate200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Bekor qilish",
                              style: TextStyle(
                                color: AppColors.slate600,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                _showToast("Iltimos, zikr matnini kiriting");
                                return;
                              }
                              final newZikr = ZikrModel(
                                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                title: title,
                                arabic: arabicCtrl.text.trim(),
                                meaning: meaningCtrl.text.trim(),
                                count: 0,
                                target: selectedTarget,
                                isCustom: true,
                              );
                              setState(() {
                                _zikrs.add(newZikr);
                              });
                              _saveStateToPrefs();
                              Navigator.of(ctx).pop();
                              _showToast("Yangi zikr qo'shildi!");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Saqlash",
                              style: TextStyle(fontWeight: FontWeight.w700),
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
      },
    );
  }

  // ==========================================================================
  // ASOSIY EKRAN QURILISHI
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Stack(
        children: [
          Column(
            children: [
              _buildIslamicHeader(),
              Expanded(
                child: IndexedStack(
                  index: _activeTab,
                  children: [
                    _buildKundalikTab(),
                    _buildQazolarTab(),
                    _buildZikrlarTab(),
                  ],
                ),
              ),
            ],
          ),

          // Maxsus Toast Xabarnomasi
          if (_toastMessage != null)
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _toastMessage != null ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate900.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.amber300,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _toastMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================================================
  // 2. YUQORI QISM (HEADER - islamic-pattern)
  // ==========================================================================
  Widget _buildIslamicHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emerald800,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald950.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        child: CustomPaint(
          painter: IslamicPatternPainter(),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Yuqori qator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chapda: Hilol-Yulduz qutisi + Toat
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            alignment: Alignment.center,
                            child: const CrescentStarIcon(
                              size: 22,
                              color: AppColors.amber300,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Toat",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Ibodat va zikr kundaligi",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.emerald100,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // O'ngda: Ovoz tugmasi va Onlayn/Oflayn holat belgisi
                      Row(
                        children: [
                          InkWell(
                            onTap: _toggleSound,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Icon(
                                _soundEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                color: _soundEnabled
                                    ? AppColors.amber300
                                    : Colors.white70,
                                size: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? AppColors.emerald900.withOpacity(0.7)
                                  : AppColors.amber900.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, _) {
                                    return Opacity(
                                      opacity: _isOnline
                                          ? (0.4 + 0.6 * _pulseController.value)
                                          : 1.0,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isOnline
                                              ? AppColors.green400
                                              : AppColors.amber300,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isOnline ? "Onlayn" : "Oflayn",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pastki qator: Sana, Jonli soat va 14 ta shahar tanlash menyusi
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.emerald950.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Chapda: Kalendar + Bugungi sana va Soat
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: AppColors.amber300,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _getUzbekFormattedDate(_now),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text(
                                    "Soat: ",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.emerald100,
                                    ),
                                  ),
                                  Text(
                                    _getFormattedClock(_now),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amber300,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _timesStatusText,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.emerald100,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // O'ngda: 14 ta shahar DropdownButton
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.amber300,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCityKey,
                                  isDense: true,
                                  dropdownColor: AppColors.emerald900,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  items: cities.map((city) {
                                    return DropdownMenuItem<String>(
                                      value: city.key,
                                      child: Text(city.name),
                                    );
                                  }).toList(),
                                  onChanged: (newKey) {
                                    if (newKey == null) return;
                                    final cityObj = cities.firstWhere(
                                      (c) => c.key == newKey,
                                    );
                                    setState(() {
                                      _selectedCityKey = newKey;
                                      _prayerTimes = Map<String, String>.from(
                                        cityObj.fallbackTimes,
                                      );
                                    });
                                    _saveStateToPrefs();
                                    _fetchPrayerTimesFromApi(newKey);
                                    _showToast(
                                      "${cityObj.name} vaqtlari tanlandi",
                                    );
                                  },
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
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 3. 1-BO'LIM: KUNDALIK NAMOZLAR (kundalik tab)
  // ==========================================================================
  Widget _buildKundalikTab() {
    final info = _getCurrentAndNextPrayer();
    final String currentId = info['currentId'] as String;
    final String currentName = info['currentName'] as String;
    final String currentTime = info['currentTime'] as String;
    final String nextName = info['nextName'] as String;
    final String nextTime = info['nextTime'] as String;
    final String? currentStatus = _dailyStatus[currentId];

    final int doneCount =
        _dailyStatus.values.where((v) => v == 'done').length;
    final int qazoCount =
        _dailyStatus.values.where((v) => v == 'qazo').length;
    final int markedCount = doneCount + qazoCount;

    return ListView(
      controller: _dailyScrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Aqlli Joriy Namoz Eslatma Kartasi (smart-prayer-banner)
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.emerald800,
                AppColors.emerald700,
                AppColors.teal800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald900.withOpacity(0.20),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -10,
                child: Opacity(
                  opacity: 0.1,
                  child: const Icon(
                    Icons.mosque_rounded,
                    size: 110,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber400.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.amber300.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            "Hozir $currentName vaqti ($currentTime)",
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber300,
                            ),
                          ),
                        ),
                        Text(
                          "$nextName: $nextTime",
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emerald100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Hozir $currentName vaqti (${nextName}dan oldin). Bugun $currentName namozini o'qidingizmi?",
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (currentStatus == null)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _setPrayerStatus(currentId, 'done'),
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.green600,
                                size: 18,
                              ),
                              label: const Text(
                                "Ha, o'qidim",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.emerald800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _setPrayerStatus(currentId, 'qazo'),
                              icon: const Icon(
                                Icons.error_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: const Text(
                                "Yo'q (Qazo)",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.red500,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Bugungi $currentName namozi ${currentStatus == 'done' ? "O'qildi" : "Qazo"} deb belgilangan.",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _dailyScrollController.animateTo(
                                  240,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOut,
                                );
                              },
                              child: const Text(
                                "Ro'yxatda ko'rish",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.amber300,
                                  decoration: TextDecoration.underline,
                                ),
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

        // Kunlik Ko'rsatkich va 5 Bo'lakli Progress Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200.withOpacity(0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "BUGUNGI NATIJA",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doneCount == 5
                              ? "Mashalloh! Bugun barcha 5 vaqt namoz o'qildi!"
                              : "5 vaqtdan $markedCount tasi belgilandi",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: doneCount == 5
                                ? AppColors.green600
                                : AppColors.slate800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "O'qildi: $doneCount",
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Qazo: $qazoCount",
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: dailyPrayers.map((p) {
                  final st = _dailyStatus[p.id];
                  Color barColor = AppColors.slate200;
                  if (st == 'done') barColor = AppColors.green500;
                  if (st == 'qazo') barColor = AppColors.red500;
                  return Expanded(
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 5 Vaqt Namoz Ro'yxati
        ...dailyPrayers.map((prayer) {
          final String? status = _dailyStatus[prayer.id];
          final bool isCurrent = currentId == prayer.id;
          final String timeStr = _prayerTimes[prayer.id] ?? '--:--';

          Color cardBg = Colors.white;
          Color borderColor =
              isCurrent ? AppColors.emerald500 : AppColors.slate200;
          Color titleColor = AppColors.slate900;

          if (status == 'done') {
            cardBg = AppColors.green50;
            borderColor = AppColors.green400;
            titleColor = AppColors.green600;
          } else if (status == 'qazo') {
            cardBg = AppColors.red50;
            borderColor = AppColors.red400;
            titleColor = AppColors.red600;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: (status != null || isCurrent) ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // 44x44 ikonka qutisi
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: status == 'done'
                        ? AppColors.green600.withOpacity(0.12)
                        : status == 'qazo'
                            ? AppColors.red600.withOpacity(0.12)
                            : AppColors.emerald50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    prayer.icon,
                    color: status == 'done'
                        ? AppColors.green600
                        : status == 'qazo'
                            ? AppColors.red600
                            : AppColors.emerald700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // O'rta: Namoz nomi, vaqti va holat yozuvi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            prayer.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              timeStr,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (status == 'done')
                        const Text(
                          "✓ O'qildi",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green600,
                          ),
                        )
                      else if (status == 'qazo')
                        const Text(
                          "! Qazo bo'ldi (+1)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red600,
                          ),
                        )
                      else
                        Row(
                          children: [
                            const Text(
                              "Belgilanmagan",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amber50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.amber300,
                                  ),
                                ),
                                child: const Text(
                                  "Hozirgi vaqt",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.amber800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),

                // O'ngda: "O'qidim" va "Qazo" tugmalari
                Row(
                  children: [
                    InkWell(
                      onTap: () => _setPrayerStatus(prayer.id, 'done'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'done'
                              ? AppColors.green600
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "O'qidim",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: status == 'done'
                                ? Colors.white
                                : AppColors.slate700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _setPrayerStatus(prayer.id, 'qazo'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'qazo'
                              ? AppColors.red600
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Qazo",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: status == 'qazo'
                                ? Colors.white
                                : AppColors.slate700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),

        // Izoh va Kunning holatini tozalash tugmasi
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "Har kuni soat 00:00 da kundalik ro'yxat yangilanadi, qazolar va zikrlar hisobi esa doim saqlanib qoladi.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.slate400,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: _showResetDailyModal,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 16,
              color: AppColors.slate500,
            ),
            label: const Text(
              "Kunning holatini tozalash",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.slate500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 4. 2-BO'LIM: QAZOLAR DAFTARI (qazolar tab)
  // ==========================================================================
  Widget _buildQazolarTab() {
    final int total = _totalQazoCount;
    final int estDays = (total / 5).ceil();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Jami Qazolar Xulosa Kartasi
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.slate800,
                AppColors.slate900,
                AppColors.emerald950,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate900.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "QAZOLAR DAFTARI",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber300,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Jami qazo namozlar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      total == 0
                          ? "Alhamdulillah! Hozirda qayd etilgan qazo namozlaringiz yo'q."
                          : "Har kuni 1 kunlik qazo o'qisangiz, taxminan $estDays kunda tugatasiz.",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.emerald100,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(
                      total.toString(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber300,
                      ),
                    ),
                    const Text(
                      "ta namoz",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 6 ta Qazo Namoz Kartochkasi
        ...qazoItems.map((item) {
          final int count = _qazoCounts[item.id] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chapda: Namoz nomi, qalamcha va rakat soni
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _showEditQazoModal(item),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 15,
                                color: AppColors.slate400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.rakatInfo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),

                // O'ngda: O'qidim -1, joriy son va +1
                Row(
                  children: [
                    InkWell(
                      onTap: count > 0
                          ? () => _changeQazoCount(item.id, -1)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? AppColors.emerald600
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "O'qidim -1",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                count > 0 ? Colors.white : AppColors.slate400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _showEditQazoModal(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count.toString(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: count > 0
                                ? AppColors.red600
                                : AppColors.green600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _changeQazoCount(item.id, 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "+1",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 6),

        // Ko'p Kunlik Qazolarni Qo'shish Bloki
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.amber50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.amber200),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.amber300.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  color: AppColors.amber800,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ko'p kunlik qazolarni qo'shish",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Oldingi oylar yoki yillardan qolgan qazolarni barcha namozlarga teng qo'shishingiz mumkin.",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.amber800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _showAddBulkQazoDaysModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "+ Kun qo'shish",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 5. 3-BO'LIM: ZIKRLAR - ELEKTRON TASBEH (zikrlar tab)
  // ==========================================================================
  Widget _buildZikrlarTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Yuqori Hisob Kartasi
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.emerald100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: AppColors.emerald700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Elektron Tasbeh",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Sanash uchun zikr kartochkasini bosing",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "JAMI ZIKRLAR",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _totalZikrCount.toString(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Zikr Kartochkalari Ro'yxati
        ..._zikrs.map((zikr) {
          final bool isPressed = _pressedZikrId == zikr.id;
          final bool isPopped = _poppedZikrId == zikr.id;
          final String targetDisplay =
              zikr.target == 0 ? '∞' : zikr.target.toString();
          final int cycleProgress = zikr.target > 0
              ? (zikr.count % zikr.target == 0 && zikr.count > 0
                  ? zikr.target
                  : zikr.count % zikr.target)
              : zikr.count;
          final double progressRatio = zikr.target > 0
              ? (cycleProgress / zikr.target).clamp(0.0, 1.0)
              : 1.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedScale(
              scale: isPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOut,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  splashColor: AppColors.emerald100.withOpacity(0.6),
                  highlightColor: AppColors.emerald50.withOpacity(0.4),
                  onTap: () => _incrementZikr(zikr),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Yuqori qator: BOSIB SANANG (+1) badge va boshqaruv tugmalari
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "BOSIB SANANG (+1)",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.emerald700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    zikr.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Maqsadni o'zgartirish tugmasi
                                InkWell(
                                  onTap: () => _cycleZikrTarget(zikr),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.slate100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Maqsad: $targetDisplay",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Nolga tushirish tugmasi
                                InkWell(
                                  onTap: () => _resetSingleZikr(zikr),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.red50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "Nolga tushirish",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.red600,
                                      ),
                                    ),
                                  ),
                                ),
                                if (zikr.isCustom) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _deleteCustomZikr(zikr),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: AppColors.red50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: AppColors.red600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // O'rtada: Arabcha matn va ma'nosi
                        if (zikr.arabic.isNotEmpty || zikr.meaning.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.emerald50.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (zikr.arabic.isNotEmpty)
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      zikr.arabic,
                                      style: GoogleFonts.amiri(
                                        fontSize: 22,
                                        height: 1.8,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.emerald900,
                                      ),
                                    ),
                                  ),
                                if (zikr.meaning.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    zikr.meaning,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Pastda: Davriy ko'rsatkich + progress bar va o'ngda katta sanoq qutisi
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Davriy ko'rsatkich",
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate500,
                                        ),
                                      ),
                                      Text(
                                        zikr.target > 0
                                            ? "$cycleProgress / ${zikr.target}"
                                            : "${zikr.count} / ∞",
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.emerald700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progressRatio,
                                      minHeight: 8,
                                      backgroundColor: AppColors.slate100,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.emerald500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            AnimatedScale(
                              scale: isPopped ? 1.12 : 1.0,
                              duration: const Duration(milliseconds: 110),
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 72),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald700,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      zikr.count.toString(),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Text(
                                      "MARTA",
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.emerald100,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 6),

        // Yangi zikr qo'shish tugmasi
        InkWell(
          onTap: _showAddZikrModal,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.emerald500,
                width: 1.4,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.emerald700,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "Yangi zikr qo'shish",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 6. PASTKI NAVIGATSIYA PANELI (Bottom Navigation Bar)
  // ==========================================================================
  Widget _buildBottomNavigationBar() {
    final int totalQazo = _totalQazoCount;

    Widget buildNavItem({
      required int index,
      required String label,
      required IconData icon,
      int badgeCount = 0,
    }) {
      final bool isActive = _activeTab == index;
      return Expanded(
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _activeTab = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.emerald100
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: isActive
                            ? AppColors.emerald700
                            : AppColors.slate400,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: 2,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red500,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : badgeCount.toString(),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? AppColors.emerald700 : AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.slate200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            buildNavItem(
              index: 0,
              label: "Kundalik",
              icon: Icons.mosque_rounded,
            ),
            buildNavItem(
              index: 1,
              label: "Qazolar",
              icon: Icons.menu_book_rounded,
              badgeCount: totalQazo,
            ),
            buildNavItem(
              index: 2,
              label: "Zikrlar",
              icon: Icons.nights_stay_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
