import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finger_selection_game/models/game_settings.dart';

/// Oyun ayarlarını cihazda kalıcı olarak saklayan sınıf
class SettingsStorage {
  static const String _settingsKey = 'game_settings';

  /// Kullanıcı ayarlarını kaydeder
  static Future<bool> saveSettings(GameSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // GameSettings nesnesini JSON'a dönüştürüp kaydet
      final Map<String, dynamic> settingsMap = {
        'winnerCount': settings.winnerCount,
        'enableVibration': settings.enableVibration,
        'themeMode': settings.themeMode.index,
        'particleEffect': settings.particleEffect.index,
        'lightEffectStyle': settings.lightEffectStyle.index,
        'requireParticipantCount': settings.requireParticipantCount,
        'requiredParticipants': settings.requiredParticipants,
      };

      final String settingsJson = jsonEncode(settingsMap);

      return await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Ayarlar kaydedilirken hata oluştu: $e');
      return false;
    }
  }

  /// Kaydedilmiş kullanıcı ayarlarını yükler
  static Future<GameSettings?> loadSettings() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? settingsJson = prefs.getString(_settingsKey);

      if (settingsJson == null) {
        return null; // Kaydedilmiş ayar yok
      }

      final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);

      return GameSettings(
        winnerCount: settingsMap['winnerCount'] ?? 1,
        enableVibration: settingsMap['enableVibration'] ?? true,
        themeMode: GameThemeMode.values[settingsMap['themeMode'] ?? 0],
        particleEffect:
            ParticleEffectType.values[settingsMap['particleEffect'] ?? 0],
        lightEffectStyle:
            LightEffectStyle.values[settingsMap['lightEffectStyle'] ?? 0],
        requireParticipantCount:
            settingsMap['requireParticipantCount'] ?? false,
        requiredParticipants: settingsMap['requiredParticipants'] ?? 2,
      );
    } catch (e) {
      print('Ayarlar yüklenirken hata oluştu: $e');
      return null;
    }
  }

  /// Kaydedilmiş ayarları siler
  static Future<bool> clearSettings() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_settingsKey);
    } catch (e) {
      print('Ayarlar silinirken hata oluştu: $e');
      return false;
    }
  }
}
