import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'package:finger_selection_game/screens/settings_screen.dart';
import 'package:finger_selection_game/screens/intro_screen.dart';
import 'package:finger_selection_game/models/game_settings.dart';
import 'package:finger_selection_game/screens/multi_touch_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cihaz oryantasyonunu ayarla
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Tam ekran modunu ayarla
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Uygulama başlarken kaydedilmiş ayarları yükle
  try {
    await GameSettings.loadFromPrefs();
  } catch (e) {
    print('Ayarlar yüklenirken hata: $e');
    // Hata olursa varsayılan ayarlarla devam et
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parmak Seçme Oyunu',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E86C1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF2E86C1),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
        ),
      ),
      initialRoute: '/multi-touch',
      routes: {
        '/intro': (context) => const IntroScreen(),
        '/game': (context) => const MainGameScreen(),
        '/multi-touch': (context) => const MultiTouchScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  final GameSettings _settings = GameSettings(
    winnerCount: 1,
    enableVibration: true,
    themeMode: GameThemeMode.neon,
    particleEffect: ParticleEffectType.confetti,
    lightEffectStyle: LightEffectStyle.standard,
    requireParticipantCount: false,
    requiredParticipants: 2,
    countdownSeconds: 3,
    gameMode: GameMode.normal,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameScreen(settings: _settings),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsScreen(settings: _settings),
            ),
          );

          if (result != null) {
            setState(() {
              _settings.winnerCount = result.winnerCount;
              _settings.enableVibration = result.enableVibration;
              _settings.themeMode = result.themeMode;
              _settings.particleEffect = result.particleEffect;
              _settings.lightEffectStyle = result.lightEffectStyle;
              _settings.requireParticipantCount =
                  result.requireParticipantCount;
              _settings.requiredParticipants = result.requiredParticipants;
              _settings.countdownSeconds = result.countdownSeconds;
              _settings.gameMode = result.gameMode;
            });
          }
        },
        elevation: 4,
        backgroundColor: const Color(0xFF2E86C1),
        child: const Icon(Icons.settings, color: Colors.white, size: 32),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final GameSettings settings;

  const GameScreen({Key? key, required this.settings}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final Map<int, TouchPoint> _activePoints = {};
  final List<int> _winners = [];
  final List<int> _previousWinners = []; // Önceki turda kazananlar
  final List<int> _globalWinnerHistory = []; // Tüm kazanan geçmişi
  final Random _random = Random();

  // Oyun durumu
  bool _gameActive = false;
  bool _showWinners = false;
  int _countdownValue = 3;

  // Animasyonlar
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  Timer? _confettiTimer;
  final List<Map<String, dynamic>> _confettiParticles = [];

  @override
  void initState() {
    super.initState();

    // Titreşim animasyonu
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Dönen ışık animasyonu
    _rotateController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    // Tam ekran modu
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _confettiTimer?.cancel();
    super.dispose();
  }

  // Rastgele parlak renk oluştur - tema moduna göre
  Color _getRandomColor() {
    // Tema moduna göre renk paletini seç
    List<Color> colorPalette;

    switch (widget.settings.themeMode) {
      case GameThemeMode.dark:
        colorPalette = [
          Colors.blue.shade600,
          Colors.purple.shade600,
          Colors.indigo.shade600,
        ];
        break;
      case GameThemeMode.neon:
        colorPalette = [
          Colors.greenAccent.shade400,
          Colors.pinkAccent.shade400,
          Colors.cyanAccent.shade400,
          Colors.yellowAccent.shade400,
          Colors.purpleAccent.shade400,
        ];
        break;
      default: // light
        colorPalette = [
          Colors.red.shade500,
          Colors.blue.shade500,
          Colors.green.shade500,
          Colors.amber.shade500,
          Colors.pink.shade500,
        ];
    }

    return colorPalette[_random.nextInt(colorPalette.length)];
  }

  // Konfeti parçacığı oluştur
  void _createConfetti() {
    if (widget.settings.particleEffect == ParticleEffectType.none) return;

    // Konfeti zamanlamasını ayarla
    _confettiTimer?.cancel();
    _confettiTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_showWinners || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Ekranın üstünden konfetiler oluştur
        final screenWidth = MediaQuery.of(context).size.width;
        for (int i = 0; i < 3; i++) {
          _confettiParticles.add({
            'x': _random.nextDouble() * screenWidth,
            'y': -20.0,
            'color': _getRandomColor(),
            'size': _random.nextDouble() * 10 + 5,
            'velocity': _random.nextDouble() * 2 + 3,
            'angle': _random.nextDouble() * 0.4 - 0.2,
            'rotation': _random.nextDouble() * 360,
            'rotationSpeed': _random.nextDouble() * 10 - 5,
            'lifetime': 0,
            'type': widget.settings.particleEffect == ParticleEffectType.sparkle
                ? 'star'
                : 'confetti',
          });
        }

        // Eski parçacıkları temizle
        _confettiParticles.removeWhere((p) => p['lifetime'] > 100);

        // Parçacıkları hareket ettir
        for (final particle in _confettiParticles) {
          particle['y'] += particle['velocity'];
          particle['x'] += particle['angle'];
          particle['rotation'] += particle['rotationSpeed'];
          particle['lifetime'] += 1;
        }
      });
    });
  }

  // Geri sayım başlat
  void _startCountdown() {
    if (_activePoints.isEmpty) return;

    // Önce mevcut kaydedilmiş kazananları temizle (yeni oyun başlatırken)
    _winners.clear();

    setState(() {
      _countdownValue = widget.settings.countdownSeconds;
      _gameActive = true;
      _showWinners = false;
      _confettiParticles.clear();
      _confettiTimer?.cancel();
    });

    // Hafif titreşim ile geri sayımı başlat
    if (widget.settings.enableVibration) {
      HapticFeedback.mediumImpact();
    }

    // Geri sayım mantığını ayarlara göre değiştir
    void _runCountdown(int secondsLeft) {
      if (!mounted) return;

      if (secondsLeft > 0) {
        setState(() {
          _countdownValue = secondsLeft;
        });

        if (widget.settings.enableVibration) {
          HapticFeedback.lightImpact();
        }

        // 1 saniye sonra tekrar çağır
        Future.delayed(const Duration(seconds: 1), () {
          _runCountdown(secondsLeft - 1);
        });
      } else {
        // Geri sayım bitti, kazananı seç
        setState(() {
          _countdownValue = 0;
        });

        // Hafif gecikme ile kazananı seç
        Future.delayed(const Duration(milliseconds: 800), () {
          _selectWinners();
        });
      }
    }

    // Geri sayımı başlat
    _runCountdown(_countdownValue);
  }

  // Rastgele kazanan seç
  void _selectWinners() {
    if (_activePoints.isEmpty) return;

    setState(() {
      _winners.clear();

      // Gerekli katılımcı sayısını kontrol et
      if (widget.settings.requireParticipantCount &&
          _activePoints.length < widget.settings.requiredParticipants) {
        // Yeterli katılımcı yok, oyunu iptal et
        _gameActive = false;
        return;
      }

      final keys = _activePoints.keys.toList();

      // Oyun moduna göre kazanan seçme mantığını değiştir
      switch (widget.settings.gameMode) {
        case GameMode.elimination:
          // Eleme modu: En çok puan alan kişiler kalır
          // Bu modda her turda bir kişi elenir
          if (_previousWinners.isNotEmpty) {
            // Önceki turdaki kazananları dikkate al
            for (final id in _previousWinners) {
              keys.remove(id);
            }
          }

          if (keys.isEmpty) {
            // Eğer tüm oyuncular daha önce kazandıysa, herkesi ekle
            keys.addAll(_activePoints.keys);
          }

          // Rastgele bir kişiyi seç
          if (keys.isNotEmpty) {
            final randomIndex = _random.nextInt(keys.length);
            _winners.add(keys[randomIndex]);
          }
          break;

        case GameMode.fairMode:
          // Adil mod: Daha önce seçilmeyenler öncelikli
          // Şans faktörünü azaltır ve herkesin eşit şekilde seçilmesini sağlar
          List<int> notSelectedBefore = [];

          for (final id in keys) {
            if (!_globalWinnerHistory.contains(id)) {
              notSelectedBefore.add(id);
            }
          }

          // Kazanan sayısı kadar kişi seç
          final winnerCount =
              min(widget.settings.winnerCount, _activePoints.length);

          // Önce hiç seçilmemiş olanlardan seç
          if (notSelectedBefore.isNotEmpty) {
            notSelectedBefore.shuffle();
            for (int i = 0;
                i < min(winnerCount, notSelectedBefore.length);
                i++) {
              _winners.add(notSelectedBefore[i]);
              _globalWinnerHistory.add(notSelectedBefore[i]);
            }
          }

          // Eğer yeterli sayıda seçilmediyse, diğerlerinden de seç
          if (_winners.length < winnerCount) {
            keys.shuffle();
            for (final id in keys) {
              if (!_winners.contains(id) && _winners.length < winnerCount) {
                _winners.add(id);
                _globalWinnerHistory.add(id);
              }
            }
          }
          break;

        case GameMode.normal:
        default:
          // Normal mod: Tamamen rastgele
          // Ayarlara göre kazanan sayısını belirle
          final winnerCount =
              min(widget.settings.winnerCount, _activePoints.length);

          // Kazanacakları rastgele seç
          keys.shuffle();
          for (int i = 0; i < winnerCount; i++) {
            _winners.add(keys[i]);
          }
          break;
      }

      // Geçmiş kazananları güncelle
      _previousWinners.clear();
      _previousWinners.addAll(_winners);

      _showWinners = true;
      _gameActive = false;

      // Titreşim efekti
      if (widget.settings.enableVibration) {
        HapticFeedback.heavyImpact();
      }

      // Konfeti efektini başlat
      _createConfetti();
    });
  }

  // Temalara göre arka plan gradyanını getir
  Gradient _getBackgroundGradient() {
    switch (widget.settings.themeMode) {
      case GameThemeMode.dark:
        return RadialGradient(
          colors: [Colors.blue.shade900.withOpacity(0.3), Colors.black],
          center: Alignment.center,
          radius: 1.2,
        );
      case GameThemeMode.neon:
        return LinearGradient(
          colors: [
            Colors.black,
            Colors.purple.shade900.withOpacity(0.5),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default: // light
        return RadialGradient(
          colors: [Colors.blue.shade200.withOpacity(0.3), Colors.blue.shade900],
          center: Alignment.center,
          radius: 1.2,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan
          Container(
            decoration: BoxDecoration(
              gradient: _getBackgroundGradient(),
            ),
          ),

          // Grid lines - neon tema için
          if (widget.settings.themeMode == GameThemeMode.neon)
            CustomPaint(
              size: Size.infinite,
              painter: GridPainter(
                color: Colors.cyanAccent.withOpacity(0.2),
                horizontalGap: 30,
                verticalGap: 30,
              ),
            ),

          // Çoklu dokunma alanı
          Positioned.fill(
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                if (_showWinners)
                  return; // Kazananlar ekrandayken yeni dokunuşları engelle

                final now = DateTime.now().millisecondsSinceEpoch.toDouble();
                setState(() {
                  _activePoints[event.pointer] = TouchPoint(
                    id: event.pointer,
                    position: event.localPosition,
                    color: _getRandomColor(),
                    startTime: now,
                    pressure: event.pressure,
                    trail: [event.localPosition],
                  );
                });

                // Hafif geribildirim
                if (widget.settings.enableVibration) {
                  HapticFeedback.lightImpact();
                }
              },
              onPointerMove: (PointerMoveEvent event) {
                if (_showWinners || _gameActive)
                  return; // Oyun aktifken hareketi engelle

                if (_activePoints.containsKey(event.pointer)) {
                  setState(() {
                    _activePoints[event.pointer] =
                        _activePoints[event.pointer]!.copyWith(
                      position: event.localPosition,
                      pressure: event.pressure,
                    );
                  });
                }
              },
              onPointerUp: (PointerUpEvent event) {
                if (_showWinners) return; // Kazananlar ekrandayken silme

                setState(() {
                  _activePoints.remove(event.pointer);
                });
              },
              onPointerCancel: (PointerCancelEvent event) {
                setState(() {
                  _activePoints.remove(event.pointer);
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: _activePoints.isEmpty && !_gameActive && !_showWinners
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.touch_app,
                              color: Colors.white,
                              size: 80,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Ekrana dokun',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.settings.requireParticipantCount
                                  ? '${widget.settings.requiredParticipants} katılımcı gerekli'
                                  : 'İstediğin kadar parmak ile dokun',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // Dokunma noktaları
          ..._activePoints.values.map((point) {
            final isWinner = _winners.contains(point.id);
            final now = DateTime.now().millisecondsSinceEpoch.toDouble();
            final age = now - point.startTime;

            // Boyut hesapla
            final pressureFactor = 0.5 + (point.pressure * 0.5);
            final pulseSize =
                60.0 * pressureFactor + (isWinner ? 8 * sin(age / 200) : 0);

            // Farklı ışık efektleri
            double glowSpread = 2.0;
            double glowBlur = 10.0;

            if (isWinner) {
              switch (widget.settings.lightEffectStyle) {
                case LightEffectStyle.stars:
                  glowSpread = 15.0;
                  glowBlur = 30.0;
                  break;
                case LightEffectStyle.pulse:
                  glowSpread = 5.0 + (8.0 * _pulseController.value);
                  glowBlur = 10.0 + (15.0 * _pulseController.value);
                  break;
                case LightEffectStyle.standard:
                default:
                  glowSpread = 5.0;
                  glowBlur = 15.0;
                  break;
              }
            }

            return Stack(
              children: [
                // Işık halkası
                if (isWinner)
                  Positioned(
                    left: point.position.dx - 100,
                    top: point.position.dy - 100,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isWinner
                                    ? Colors.yellow.shade500.withOpacity(0.7)
                                    : point.color.withOpacity(0.5),
                                blurRadius: glowBlur,
                                spreadRadius: glowSpread,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                // Rotasyon efekti (sadece kazananlar için)
                if (isWinner &&
                    widget.settings.lightEffectStyle == LightEffectStyle.stars)
                  Positioned(
                    left: point.position.dx - 120,
                    top: point.position.dy - 120,
                    child: AnimatedBuilder(
                      animation: _rotateController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotateController.value * 2 * pi,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              gradient: SweepGradient(
                                colors: [
                                  Colors.yellow.withOpacity(0.0),
                                  Colors.yellow.withOpacity(0.5),
                                  Colors.yellow.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Dokunma noktası
                Positioned(
                  left: point.position.dx - (pulseSize / 2),
                  top: point.position.dy - (pulseSize / 2),
                  child: Container(
                    width: pulseSize,
                    height: pulseSize,
                    decoration: BoxDecoration(
                      color: isWinner
                          ? Colors.yellow.shade500.withOpacity(0.8)
                          : point.color.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isWinner
                              ? Colors.yellow.shade500.withOpacity(0.8)
                              : point.color.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: isWinner ? 5 : 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${point.id}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isWinner ? 20 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),

          // Konfeti parçacıkları
          ..._confettiParticles.map((particle) {
            final size = particle['size'] as double;
            final rotation = particle['rotation'] as double;
            final opacity = 1.0 - (particle['lifetime'] / 100);

            if (particle['type'] == 'star') {
              return Positioned(
                left: particle['x'] - size / 2,
                top: particle['y'] - size / 2,
                child: Transform.rotate(
                  angle: rotation * pi / 180,
                  child: Icon(
                    Icons.star,
                    color: (particle['color'] as Color).withOpacity(opacity),
                    size: size * 2,
                  ),
                ),
              );
            } else {
              return Positioned(
                left: particle['x'] - size / 2,
                top: particle['y'] - size / 2,
                child: Transform.rotate(
                  angle: rotation * pi / 180,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: (particle['color'] as Color).withOpacity(opacity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }
          }).toList(),

          // Geri sayım göstergesi
          if (_gameActive)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _countdownValue > 0
                            ? "$_countdownValue"
                            : "Seçiliyor...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _countdownValue > 0 ? 120 : 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "${_activePoints.length} Oyuncu Hazır",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      if (widget.settings.requireParticipantCount &&
                          _activePoints.length <
                              widget.settings.requiredParticipants)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            "En az ${widget.settings.requiredParticipants} oyuncu gerekli!",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Kazanan göstergesi
          if (_showWinners && _winners.isNotEmpty)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade700.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              _winners.length > 1 ? "KAZANANLAR!" : "KAZANAN!",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Column(
                              children: _winners
                                  .map((winnerId) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Text(
                                          "Oyuncu $winnerId",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showWinners = false;
                            _confettiParticles.clear();
                          });
                        },
                        child: const Text(
                          "Tekrar Oyna",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Oyuncu sayısı bilgisi
          if (_activePoints.isNotEmpty && !_gameActive && !_showWinners)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Oyuncu Sayısı: ${_activePoints.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.settings.requireParticipantCount)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            'Gerekli: ${widget.settings.requiredParticipants}',
                            style: TextStyle(
                              color: _activePoints.length >=
                                      widget.settings.requiredParticipants
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Oyun başlatma butonu
          if (_activePoints.isNotEmpty && !_gameActive && !_showWinners)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (widget.settings.requireParticipantCount &&
                        _activePoints.length <
                            widget.settings.requiredParticipants) {
                      // Yeterli oyuncu yok, uyarı göster
                      if (widget.settings.enableVibration) {
                        HapticFeedback.vibrate();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'En az ${widget.settings.requiredParticipants} oyuncu gerekli!',
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: Colors.red.shade700,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    _startCountdown();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.casino,
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Seçimi Başlat",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

// Grid çizgilerini çizen yardımcı sınıf
class GridPainter extends CustomPainter {
  final Color color;
  final double horizontalGap;
  final double verticalGap;

  GridPainter({
    required this.color,
    required this.horizontalGap,
    required this.verticalGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    // Yatay çizgiler
    for (double y = 0; y <= size.height; y += verticalGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Dikey çizgiler
    for (double x = 0; x <= size.width; x += horizontalGap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
