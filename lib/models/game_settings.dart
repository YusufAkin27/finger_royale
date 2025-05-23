// Importing LightState from a separate file
import 'light_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameThemeMode { light, dark, neon }

enum ParticleEffectType {
  confetti,
  fireworks,
  sparkle,
  none,
}

enum LightEffectStyle { standard, pulse, stars }

enum GameMode { normal, elimination, fairMode }

class GameSettings {
  int winnerCount;
  bool enableVibration;
  GameThemeMode themeMode;
  ParticleEffectType particleEffect;
  LightEffectStyle lightEffectStyle;
  bool requireParticipantCount;
  int requiredParticipants;
  int countdownSeconds;
  GameMode gameMode;

  GameSettings({
    this.winnerCount = 1,
    this.enableVibration = true,
    this.themeMode = GameThemeMode.neon,
    this.particleEffect = ParticleEffectType.confetti,
    this.lightEffectStyle = LightEffectStyle.standard,
    this.requireParticipantCount = false,
    this.requiredParticipants = 2,
    this.countdownSeconds = 3,
    this.gameMode = GameMode.normal,
  });

  GameSettings copyWith({
    int? winnerCount,
    bool? enableVibration,
    GameThemeMode? themeMode,
    ParticleEffectType? particleEffect,
    LightEffectStyle? lightEffectStyle,
    bool? requireParticipantCount,
    int? requiredParticipants,
    int? countdownSeconds,
    GameMode? gameMode,
  }) {
    return GameSettings(
      winnerCount: winnerCount ?? this.winnerCount,
      enableVibration: enableVibration ?? this.enableVibration,
      themeMode: themeMode ?? this.themeMode,
      particleEffect: particleEffect ?? this.particleEffect,
      lightEffectStyle: lightEffectStyle ?? this.lightEffectStyle,
      requireParticipantCount:
          requireParticipantCount ?? this.requireParticipantCount,
      requiredParticipants: requiredParticipants ?? this.requiredParticipants,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      gameMode: gameMode ?? this.gameMode,
    );
  }

  // Ayarları SharedPreferences'e kaydeden metot
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('winnerCount', winnerCount);
    await prefs.setBool('enableVibration', enableVibration);
    await prefs.setInt('themeMode', themeMode.index);
    await prefs.setInt('particleEffect', particleEffect.index);
    await prefs.setInt('lightEffectStyle', lightEffectStyle.index);
    await prefs.setBool('requireParticipantCount', requireParticipantCount);
    await prefs.setInt('requiredParticipants', requiredParticipants);
    await prefs.setInt('countdownSeconds', countdownSeconds);
    await prefs.setInt('gameMode', gameMode.index);
  }

  // SharedPreferences'ten ayarları yükleyen statik metot
  static Future<GameSettings> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    return GameSettings(
      winnerCount: prefs.getInt('winnerCount') ?? 1,
      enableVibration: prefs.getBool('enableVibration') ?? true,
      themeMode: GameThemeMode.values[prefs.getInt('themeMode') ?? 2],
      particleEffect:
          ParticleEffectType.values[prefs.getInt('particleEffect') ?? 0],
      lightEffectStyle:
          LightEffectStyle.values[prefs.getInt('lightEffectStyle') ?? 0],
      requireParticipantCount:
          prefs.getBool('requireParticipantCount') ?? false,
      requiredParticipants: prefs.getInt('requiredParticipants') ?? 2,
      countdownSeconds: prefs.getInt('countdownSeconds') ?? 3,
      gameMode: GameMode.values[prefs.getInt('gameMode') ?? 0],
    );
  }
}
