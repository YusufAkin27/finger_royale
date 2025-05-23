import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finger_selection_game/screens/settings_screen.dart';
import 'package:finger_selection_game/models/game_settings.dart';
import 'dart:async';

// Dokunuş tanıma özelleştirmeleri kaldırıldı

class TouchPoint {
  final int id;
  final Offset position;
  final Color color;
  final double size;
  final double startTime;
  final double pressure;
  final double velocity;
  final List<Offset> trail;

  // Optimize edilmiş constructor - trail sadece gerektiğinde kullanılacak
  TouchPoint({
    required this.id,
    required this.position,
    required this.color,
    this.size = 60.0,
    required this.startTime,
    this.pressure = 1.0,
    this.velocity = 0.0,
    List<Offset>? trail,
  }) : trail = trail ?? const [];

  TouchPoint copyWith({
    int? id,
    Offset? position,
    Color? color,
    double? size,
    double? startTime,
    double? pressure,
    double? velocity,
    List<Offset>? trail,
  }) {
    return TouchPoint(
      id: id ?? this.id,
      position: position ?? this.position,
      color: color ?? this.color,
      size: size ?? this.size,
      startTime: startTime ?? this.startTime,
      pressure: pressure ?? this.pressure,
      velocity: velocity ?? this.velocity,
      trail: trail ?? this.trail,
    );
  }

  // Hareket hızını hesapla - statik metod daha verimli
  static double calculateVelocity(
      Offset previous, Offset current, double timeDelta) {
    if (timeDelta <= 0) return 0.0;
    final distance = (current - previous).distance;
    return distance / timeDelta;
  }
}

class MultiTouchScreen extends StatefulWidget {
  const MultiTouchScreen({super.key});

  @override
  State<MultiTouchScreen> createState() => _MultiTouchScreenState();
}

class _MultiTouchScreenState extends State<MultiTouchScreen>
    with SingleTickerProviderStateMixin {
  final Map<int, TouchPoint> _activePoints = {};
  final Random _random = Random();
  AnimationController? _animationController;
  final int _maxTrailPoints =
      10; // İz için maksimum nokta sayısı - 20'den 10'a düşürüldü
  final Map<int, Offset> _previousPositions = {};
  final Map<int, double> _lastUpdateTime = {};

  // Maksimum dokunma sayısı - çok yüksek bir değer ayarlandı
  final int _maxTouchPoints =
      100; // Kullanıcı talebi üzerine en yüksek değere çıkarıldı

  // İstatistikler
  int _totalTouches = 0;
  double _maxVelocity = 0.0;
  double _maxPressure = 0.0;

  // Oyun değişkenleri
  bool _gameActive = false;
  List<int> _winners = [];
  int _countdownValue = 3;
  bool _waitingForPlayers = true; // Oyuncuları bekleme modu
  bool _autoRestartEnabled = true; // Otomatik yeniden başlama
  Timer? _resetTimer; // Oyun resetleme timer'ı
  bool _pageNeedsRefresh = false; // Sayfa tamamen yenilenme ihtiyacı
  int _autoRestartSeconds = 5; // Otomatik yeniden başlama için geri sayım
  bool _sequentialTouching =
      true; // Teker teker dokunma modu - varsayılan olarak açık

  // Basitleştirilmiş ayarlar - kullanıcı isteğine göre değiştirildi
  bool _showTrails = false; // İzleri göster - kapalı
  bool _useRainbowColors =
      false; // Gökkuşağı renkleri kullan - kapalı, sadece beyaz
  bool _showTouchId = false; // ID'leri gösterme
  bool _rippleEffect = false; // Dalga efekti - kapalı

  // Efektler
  final List<Map<String, dynamic>> _ripples = [];

  // Diğer ayarlar - katılımcı sayısı 6 olarak güncellendi
  final GameSettings _gameSettings = GameSettings(
    winnerCount: 1,
    enableVibration: true,
    themeMode: GameThemeMode.neon,
    particleEffect: ParticleEffectType.confetti,
    lightEffectStyle: LightEffectStyle.standard,
    requireParticipantCount:
        true, // Varsayılan olarak katılımcı sayısını kontrol etsin
    requiredParticipants: 6, // 4'ten 6'ya yükseltildi
    countdownSeconds: 3,
    gameMode: GameMode.normal,
  );

  // Son gösterilen mesaj için değişken
  String? _lastMessage;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();

    // Işıklar için animasyon controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Tam ekran modu
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Ayarları hafızadan yükle
    _loadSettings();
  }

  // Ayarları SharedPreferences'ten yükle
  Future<void> _loadSettings() async {
    try {
      final loadedSettings = await GameSettings.loadFromPrefs();
      setState(() {
        _gameSettings.winnerCount = loadedSettings.winnerCount;
        _gameSettings.enableVibration = loadedSettings.enableVibration;
        _gameSettings.themeMode = loadedSettings.themeMode;
        _gameSettings.particleEffect = loadedSettings.particleEffect;
        _gameSettings.lightEffectStyle = loadedSettings.lightEffectStyle;
        _gameSettings.requireParticipantCount =
            loadedSettings.requireParticipantCount;
        _gameSettings.requiredParticipants =
            loadedSettings.requiredParticipants;
        _gameSettings.countdownSeconds = loadedSettings.countdownSeconds;
        _gameSettings.gameMode = loadedSettings.gameMode;
      });
    } catch (e) {
      // Yükleme hatası olursa varsayılan ayarları kullan
      print('Ayarlar yüklenemedi: $e');
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  // Sayfayı yenile - tüm değişkenleri sıfırla
  void _resetPage() {
    setState(() {
      _totalTouches = 0;
      _maxVelocity = 0.0;
      _maxPressure = 0.0;
      _winners = [];
      _gameActive = false;
      _waitingForPlayers = true;
      _ripples.clear();
      _pageNeedsRefresh = false;

      // Tüm parmak verileri ve izi temizle
      _activePoints.clear();
      _previousPositions.clear();
      _lastUpdateTime.clear();

      // Debug için yardımcı çıktı
      print("Sayfa resetlendi, tüm parmaklar temizlendi");
    });
  }

  // Yeni eklenen fonksiyon: Katılımcı sayısını kontrol et ve gerekirse oyunu başlat
  void _checkParticipantCount() {
    if (!_waitingForPlayers || _gameActive) return;

    final int requiredCount = _gameSettings.requireParticipantCount
        ? _gameSettings.requiredParticipants
        : 2; // Eğer zorunlu değilse en az 2 kişi olsun

    if (_activePoints.length >= requiredCount) {
      // Katılımcı sayısı tamamlandı, otomatik başlat
      setState(() {
        _waitingForPlayers = false;
      });

      // Kısa bir gecikme ile başlat (oyuncular hazırlansın)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _activePoints.length >= requiredCount) {
          _startCountdown();
        } else {
          // Eğer bu sürede oyuncu sayısı azaldıysa tekrar bekleme moduna geç
          setState(() {
            _waitingForPlayers = true;
          });
        }
      });
    }
  }

  // Rastgele kazanan seç - ışık efekti kalıcı yapıldı
  void _selectRandomWinner() {
    if (_activePoints.isEmpty) return;

    // Titreşim efekti
    if (_gameSettings.enableVibration) {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      // Kazananları temizle
      _winners = [];

      // Gerekli katılımcı sayısını kontrol et
      if (_gameSettings.requireParticipantCount &&
          _activePoints.length < _gameSettings.requiredParticipants) {
        // Yeterli katılımcı yok, oyunu iptal et
        _gameActive = false;
        _waitingForPlayers = true;
        return;
      }

      // Ayarlara göre kazanan sayısını belirle
      final winnerCount = min(_gameSettings.winnerCount, _activePoints.length);

      // Tüm katılımcıları karıştır
      final keys = _activePoints.keys.toList();
      keys.shuffle(_random);

      // Kazanan sayısı kadar katılımcı seç
      for (int i = 0; i < winnerCount; i++) {
        _winners.add(keys[i]);
      }

      _gameActive = false;

      // Otomatik oyunu yeniden başlatmak için bayrak ayarla
      _pageNeedsRefresh = true;
    });

    // Belirli bir süre sonra oyunu otomatik başlat ve sayfayı temizle
    if (_autoRestartEnabled) {
      _resetTimer?.cancel();

      // Daha kısa süre - 3 saniye
      _autoRestartSeconds = 3;

      // Her saniyede bir güncelleme gösteren timer başlat
      _resetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _autoRestartSeconds--;

            // Süre dolduğunda oyunu sıfırla
            if (_autoRestartSeconds <= 0) {
              _resetPage(); // Tüm sayfayı temizle
              timer.cancel();
            }
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  // Parmaklar için renk oluştur - artık sadece beyaz
  Color _getRandomBrightColor() {
    // Kullanıcı talebi üzerine her zaman beyaz renk dön
    return Colors.white;
  }

  // Tema renklerini getir
  List<Color> _getThemeColors() {
    switch (_gameSettings.themeMode) {
      case GameThemeMode.light:
        return [
          Colors.blue.shade400,
          Colors.green.shade400,
          Colors.amber.shade400,
          Colors.red.shade400,
          Colors.purple.shade400,
        ];
      case GameThemeMode.dark:
        return [
          Colors.blue.shade700,
          Colors.purple.shade700,
          Colors.teal.shade700,
          Colors.deepOrange.shade700,
          Colors.indigo.shade700,
        ];
      case GameThemeMode.neon:
      default:
        return [
          Colors.greenAccent.shade400,
          Colors.pinkAccent.shade400,
          Colors.cyanAccent.shade400,
          Colors.yellowAccent.shade400,
          Colors.purpleAccent.shade400,
        ];
    }
  }

  // Dalga efekti oluştur - daha verimli bir yaklaşım
  void _createRipple(Offset position, Color color) {
    if (!_rippleEffect) return;

    // Maksimum dalga efekti sayısını sınırla - performans için
    if (_ripples.length >= 10) {
      // En eski dalgayı kaldır
      setState(() {
        _ripples.removeAt(0);
      });
    }

    setState(() {
      _ripples.add({
        'position': position,
        'startTime': DateTime.now().millisecondsSinceEpoch,
        'color': Colors.white, // Beyaz dalga efekti kullan
      });
    });

    // Daha kısa süre - 1.5 saniye
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          if (_ripples.isNotEmpty) {
            _ripples.removeAt(0);
          }
        });
      }
    });
  }

  // Geri sayım başlat
  void _startCountdown() {
    setState(() {
      _countdownValue = _gameSettings.countdownSeconds;
      _gameActive = true;
      _winners = [];

      // Her parmağa özel titreşimli geri sayım hissi
      if (_gameSettings.enableVibration) {
        HapticFeedback.lightImpact();
      }
    });

    // Geri sayım göstermeden arkada say ve sürpriz yap
    Future.delayed(Duration(seconds: _gameSettings.countdownSeconds), () {
      if (!mounted) return;

      // Sürpriz son - kazananları seç
      _selectRandomWinner();
    });
  }

  // Onboard mesajı gösterme fonksiyonu
  void _showMessage(String message) {
    setState(() {
      _lastMessage = message;
    });

    // Mevcut zamanlayıcıyı iptal et
    _messageTimer?.cancel();

    // Yeni zamanlayıcı başlat - mesaj 3 saniye sonra kaybolacak
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _lastMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutu sadece gerekirse hesaplanacak
    // final screenSize = MediaQuery.of(context).size;

    // Eski dalga efektlerini temizle (süre 1.5 saniye, 2000ms->1500ms)
    final now = DateTime.now().millisecondsSinceEpoch;
    _ripples.removeWhere((ripple) => now - ripple['startTime'] > 1500);

    // Maksimum dalga sayısını sınırla - performans için
    if (_ripples.length > 10) {
      _ripples.removeRange(0, _ripples.length - 10);
    }

    // Performans için gereksiz widget'ları minimize et
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plan tasarımı
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.blue.shade900.withOpacity(0.3),
                  Colors.black,
                ],
                center: Alignment.center,
                radius: 1.2,
              ),
            ),
          ),

          // Dalga efektleri - _rippleEffect true ise göster, performans için
          if (_rippleEffect)
            ..._ripples.map((ripple) {
              final age = now - ripple['startTime'];
              final progress = age / 1500; // 0.0 - 1.0 arası (1.5 saniye)
              final size = progress * 200.0; // Maksimum 200px çap (küçültüldü)
              final opacity = 1.0 - progress; // Zamanla sönümle

              // Sadece görünür dalga efektlerini çiz (saydamlık > 0.05)
              if (opacity < 0.05) return const SizedBox.shrink();

              return Positioned(
                left: ripple['position'].dx - (size / 2),
                top: ripple['position'].dy - (size / 2),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ripple['color']
                          .withOpacity(opacity * 0.5), // Daha hafif
                      width: 1.5, // Daha ince çizgi
                    ),
                  ),
                ),
              );
            }),

          // Çoklu dokunma alanı - tamamen yeni bir yaklaşım
          Listener(
            behavior: HitTestBehavior
                .opaque, // En önemli - tüm dokunuşları yakalamak için
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: _activePoints.isEmpty && _waitingForPlayers
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 30),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.blue.shade400.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade500.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
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
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.blue.shade900.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    _gameSettings.requireParticipantCount
                                        ? '${_gameSettings.requiredParticipants} katılımcı gerekli'
                                        : 'İstediğin kadar parmak ile dokun',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // İzler - sadece _showTrails true ise göster (performans için)
          if (_showTrails)
            ..._activePoints.values.map((point) {
              // Çok kısa izleri çizme - en az 3 nokta olsun
              if (point.trail.length < 3) return const SizedBox.shrink();

              // Performans için iz noktalarını azalt
              final trail = point.trail.length > 10
                  ? point.trail.sublist(point.trail.length - 10)
                  : point.trail;

              return CustomPaint(
                painter: TrailPainter(
                  points: trail,
                  color: Colors.white.withOpacity(0.5), // Beyaz ve yarı saydam
                  strokeWidth: 2.0, // Daha ince çizgi
                ),
              );
            }),

          // Dokunma noktaları - normalize edilmiş beyaz renk
          ..._activePoints.values.map((point) {
            final now = DateTime.now().millisecondsSinceEpoch.toDouble();
            final age = now - point.startTime;

            // Kazananlar için farklı boyut ve efekt
            final isWinner = _winners.contains(point.id);

            // Boyut hesapla (basınçla ölçeklendir)
            final pressureFactor =
                0.5 + (point.pressure * 0.5); // 0.5-1.0 arası
            final pulseSize = isWinner
                ? point.size * 1.2 // Kazananlara daha büyük boyut
                : point.size * pressureFactor + (8 * sin(age / 300));

            // Hız ölçeklendirme (0-1 arası)
            final velocityFactor = min(1.0, point.velocity / 2000);

            return Stack(
              children: [
                // Işık halkası - küçültülmüş ve beyaz renk
                Positioned(
                  left: point.position.dx - 50, // 75'ten 50'ye küçültüldü
                  top: point.position.dy - 50,
                  child: AnimatedBuilder(
                    animation: _animationController!,
                    builder: (context, child) {
                      return Container(
                        width: 100, // 150'den 100'e küçültüldü
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(isWinner
                                  ? 0.95 // Kazanan için daha parlak ışık
                                  : 0.5 *
                                      _animationController!.value *
                                      (0.6 + velocityFactor * 0.2)),
                              blurRadius: isWinner ? 30 : 20,
                              spreadRadius: isWinner
                                  ? 15 // Kazanan için daha geniş ışık
                                  : 3 + 10 * _animationController!.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Dokunma noktası - her zaman beyaz renk
                Positioned(
                  left: point.position.dx - (pulseSize / 2),
                  top: point.position.dy - (pulseSize / 2),
                  child: Container(
                    width: pulseSize,
                    height: pulseSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isWinner
                            ? 2.5
                            : 1.5, // Kazananlar için daha kalın çerçeve
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(isWinner ? 0.9 : 0.6),
                          blurRadius: isWinner ? 12 : 8 + (velocityFactor * 6),
                          spreadRadius: isWinner ? 5 : 1 + (velocityFactor * 3),
                        ),
                      ],
                    ),
                    // ID'leri sadece _showTouchId true ise göster
                    child: _showTouchId
                        ? Center(
                            child: Text(
                              '${point.id}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            );
          }).toList(),

          // Katılımcı bilgisi göstergesi - GestureDetector kullanımı kaldırıldı
          if (_activePoints.isNotEmpty && _waitingForPlayers)
            Positioned.fill(
              child: MouseRegion(
                // Touch'ları engellemeyen bir interaksiyon kullan
                opaque: false,
                hitTestBehavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors
                      .transparent, // Saydam arka plan tüm ekranı kapsıyor
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Katılımcılar',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${_activePoints.length} / ${_gameSettings.requiredParticipants}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (_gameSettings.requireParticipantCount &&
                              _activePoints.length <
                                  _gameSettings.requiredParticipants)
                            Text(
                              'Daha ${_gameSettings.requiredParticipants - _activePoints.length} kişi gerekli',
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_activePoints.length >=
                              _gameSettings.requiredParticipants)
                            const Text(
                              'Oyun başlıyor...',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Ayarlar butonu - touch olaylarının çakışmaması için iyileştirilmiş
          Positioned(
            top: 40,
            right: 20,
            child: InkWell(
              onTap: () async {
                // Ayarlar sayfasına git
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      settings: _gameSettings,
                      sequentialTouching:
                          _sequentialTouching, // Teker teker dokunma ayarını geçir
                    ),
                  ),
                );

                // Dönen ayarları güncelle
                if (result != null) {
                  setState(() {
                    _gameSettings.winnerCount = result.settings.winnerCount;
                    _gameSettings.enableVibration =
                        result.settings.enableVibration;
                    _gameSettings.themeMode = result.settings.themeMode;
                    _gameSettings.particleEffect =
                        result.settings.particleEffect;
                    _gameSettings.lightEffectStyle =
                        result.settings.lightEffectStyle;
                    _gameSettings.requireParticipantCount =
                        result.settings.requireParticipantCount;
                    _gameSettings.requiredParticipants =
                        result.settings.requiredParticipants;
                    _gameSettings.countdownSeconds =
                        result.settings.countdownSeconds;
                    _gameSettings.gameMode = result.settings.gameMode;

                    // Teker teker dokunma ayarını güncelle
                    _sequentialTouching = result.sequentialTouching;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          // Geri sayım göstergesi - gizli, sadece titreşim ile hissettir
          // Görünür göstergeyi kaldır ve sadece minimal bir gösterge bırak
          if (_gameActive)
            Positioned(
              bottom: 40,
              right: 40,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

          // Kazanan göstergesi - tamamen değiştirildi, sadece kazananların beyaz ışıkları
          ..._winners.map((winnerId) {
            if (_activePoints.containsKey(winnerId)) {
              final point = _activePoints[winnerId]!;
              return Positioned(
                left: point.position.dx - 60,
                top: point.position.dy - 60,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Kazananlar için sabit, parlak ve güçlü beyaz ışık
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        blurRadius: 25,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Onboard mesaj göstergesi
          if (_lastMessage != null)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade600.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    _lastMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Yeni pointer işleme fonksiyonları
  void _handlePointerDown(PointerDownEvent event) {
    // Oyun aktifken yeni parmak eklemeyi engelle
    if (_gameActive || !_waitingForPlayers) return;

    // Maksimum dokunma sayısı kontrolü
    if (_activePoints.length >= _maxTouchPoints) {
      return;
    }

    // Teker teker dokunma modu aktifse ve halihazırda başka bir parmak varsa
    // bu parmağın sahibi (katılımcı) aynı değilse engelle
    if (_sequentialTouching && _activePoints.isNotEmpty) {
      // Olay sırasında ekrana dokunulan parmak sayısı 2 veya daha fazla ise
      if (event.buttons == 1) {
        // Sadece bir parmak basıldı
        // Yeni bir parmak ekrana basılmış olabilir, mevcut parmaklar resetlenmeden yeni parmağı eklemiyoruz
        setState(() {
          // Ekrandaki tüm parmakları temizle - yeni parmağın girmesine izin ver
          _activePoints.clear();
          _previousPositions.clear();
          _lastUpdateTime.clear();
        });
      } else {
        // Birden fazla parmak aynı anda ekranda, bu parmağı reddet
        return;
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch.toDouble();

    print("Parmak basıldı ID: ${event.pointer}"); // Debug çıktısı

    setState(() {
      _totalTouches++;
      _activePoints[event.pointer] = TouchPoint(
        id: event.pointer,
        position: event.localPosition,
        color: _getRandomBrightColor(),
        startTime: now,
        pressure: event.pressure,
        trail: _showTrails ? [event.localPosition] : [],
      );

      // İstatistikleri güncelle
      if (event.pressure > _maxPressure) {
        _maxPressure = event.pressure;
      }

      // Dalga efekti - sadece _rippleEffect true ise
      if (_rippleEffect) {
        _createRipple(event.localPosition, Colors.white);
      }
    });

    _previousPositions[event.pointer] = event.localPosition;
    _lastUpdateTime[event.pointer] = now;

    // Hafif geribildirim
    if (_gameSettings.enableVibration) {
      HapticFeedback.lightImpact();
    }

    // Katılımcı sayısını kontrol et
    _checkParticipantCount();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    // Mevcut parmağı güncelle
    if (_activePoints.containsKey(event.pointer)) {
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();
      final previousPosition =
          _previousPositions[event.pointer] ?? event.localPosition;
      final lastUpdate = _lastUpdateTime[event.pointer] ?? now;
      final timeDelta = (now - lastUpdate) / 1000; // saniye cinsinden

      // Hız hesapla
      final velocity = TouchPoint.calculateVelocity(
          previousPosition, event.localPosition, timeDelta);

      // İstatistik güncelle
      if (velocity > _maxVelocity) {
        _maxVelocity = velocity;
      }

      // İz yok ise liste güncelleme işlemi yapılmaz - performans için
      List<Offset>? updatedTrail;
      if (_showTrails) {
        updatedTrail = List.from(_activePoints[event.pointer]!.trail);
        updatedTrail.add(event.localPosition);

        // İz listesini maksimum uzunlukta tut
        if (updatedTrail.length > _maxTrailPoints) {
          updatedTrail =
              updatedTrail.sublist(updatedTrail.length - _maxTrailPoints);
        }
      }

      setState(() {
        _activePoints[event.pointer] = _activePoints[event.pointer]!.copyWith(
          position: event.localPosition,
          pressure: event.pressure,
          velocity: velocity,
          trail: updatedTrail ?? _activePoints[event.pointer]!.trail,
        );
      });

      // Değerleri güncelle
      _previousPositions[event.pointer] = event.localPosition;
      _lastUpdateTime[event.pointer] = now;
    }
    // Olmayan bir parmak tespiti - bazen PointerDown olayı kaçabilir, bu yüzden burada da takip ediyoruz
    else if (!_gameActive &&
        _waitingForPlayers &&
        _activePoints.length < _maxTouchPoints) {
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();

      print("Parmak hareket ile algılandı ID: ${event.pointer}");

      setState(() {
        _totalTouches++;
        _activePoints[event.pointer] = TouchPoint(
          id: event.pointer,
          position: event.localPosition,
          color: _getRandomBrightColor(),
          startTime: now,
          pressure: event.pressure,
          trail: _showTrails ? [event.localPosition] : [],
        );
      });

      _previousPositions[event.pointer] = event.localPosition;
      _lastUpdateTime[event.pointer] = now;

      // Katılımcı sayısını kontrol et
      _checkParticipantCount();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    // Oyun aktifken yapılan işlemleri engelle
    if (_gameActive) return;

    print("Parmak kaldırıldı ID: ${event.pointer}"); // Debug çıktısı

    // Parmağı kaldır
    if (_activePoints.containsKey(event.pointer)) {
      // Dalga efekti
      if (_rippleEffect) {
        _createRipple(_activePoints[event.pointer]!.position, Colors.white);
      }

      setState(() {
        _activePoints.remove(event.pointer);
        _previousPositions.remove(event.pointer);
        _lastUpdateTime.remove(event.pointer);

        // Eğer beklenenden daha az oyuncu kaldıysa bekleme moduna dön
        if (_waitingForPlayers == false) {
          _waitingForPlayers = true;
        }

        // Eğer hiç aktif parmak kalmadıysa sayfayı temizle
        if (_activePoints.isEmpty) {
          _resetPage();
        }
      });
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    print("Parmak iptal ID: ${event.pointer}"); // Debug çıktısı

    setState(() {
      _activePoints.remove(event.pointer);
      _previousPositions.remove(event.pointer);
      _lastUpdateTime.remove(event.pointer);

      // Eğer beklenenden daha az oyuncu kaldıysa bekleme moduna dön
      if (_waitingForPlayers == false) {
        _waitingForPlayers = true;
      }

      // Eğer hiç aktif parmak kalmadıysa sayfayı temizle
      if (_activePoints.isEmpty) {
        _resetPage();
      }
    });
  }
}

// İz çizimini gerçekleştiren CustomPainter
class TrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  TrailPainter(
      {required this.points, required this.color, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrailPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
