import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finger_selection_game/models/game_settings.dart';

class SettingsScreen extends StatefulWidget {
  final GameSettings settings;
  final bool sequentialTouching; // Teker teker dokunma modu

  const SettingsScreen({
    super.key,
    required this.settings,
    this.sequentialTouching = true, // Varsayılan değer: açık
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _editedSettings;
  late bool _sequentialTouching; // Teker teker dokunma modu

  @override
  void initState() {
    super.initState();
    // Orijinal ayarların bir kopyasını düzenlemek için kullan
    _editedSettings = widget.settings.copyWith();
    _sequentialTouching = widget.sequentialTouching;
  }

  // Ayarları kaydet ve geri dön
  void _saveSettingsAndReturn() async {
    // Ayarları cihaza kaydet
    await _editedSettings.saveToPrefs();
    if (mounted) {
      // Ayarları ve sıralı dokunma modunu birlikte döndür
      Navigator.pop(context, {
        'settings': _editedSettings,
        'sequentialTouching': _sequentialTouching,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Oyun Ayarları',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Değişiklikleri kaydetmeden geri dön
            Navigator.pop(context, null);
          },
        ),
        actions: [
          TextButton(
            onPressed: _saveSettingsAndReturn,
            child: const Text(
              'KAYDET',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.blue.shade900.withOpacity(0.7),
              Colors.black,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSettingSection(
              title: 'Temel Ayarlar',
              children: [
                _buildWinnerCountSetting(),
                _buildVibrationSetting(),
                _buildCountdownSetting(),
                _buildRequiredParticipantsSetting(),
                _buildSequentialTouchSetting(),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingSection(
              title: 'Görsel Ayarlar',
              children: [
                _buildThemeModeSetting(),
                _buildLightEffectSetting(),
                _buildParticleEffectSetting(),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingSection(
              title: 'Oyun Modu',
              children: [
                _buildGameModeSetting(),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _saveSettingsAndReturn,
                child: const Text(
                  'AYARLARI KAYDET',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(
      {required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.blue, height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildWinnerCountSetting() {
    return ListTile(
      title: const Text(
        'Kazanan Sayısı',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        'Kaç kişi kazanacak: ${_editedSettings.winnerCount}',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: () {
              if (_editedSettings.winnerCount > 1) {
                setState(() {
                  _editedSettings = _editedSettings.copyWith(
                    winnerCount: _editedSettings.winnerCount - 1,
                  );
                });
              }
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _editedSettings.winnerCount.toString(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              setState(() {
                _editedSettings = _editedSettings.copyWith(
                  winnerCount: _editedSettings.winnerCount + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVibrationSetting() {
    return SwitchListTile(
      title: const Text(
        'Titreşim',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        'Oyun sırasında titreşim efektleri',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      value: _editedSettings.enableVibration,
      activeColor: Colors.blue,
      onChanged: (value) {
        setState(() {
          _editedSettings = _editedSettings.copyWith(enableVibration: value);
        });
      },
    );
  }

  Widget _buildCountdownSetting() {
    return ListTile(
      title: const Text(
        'Geri Sayım Süresi',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        'Seçim öncesi geri sayım süresi: ${_editedSettings.countdownSeconds} saniye',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: () {
              if (_editedSettings.countdownSeconds > 1) {
                setState(() {
                  _editedSettings = _editedSettings.copyWith(
                    countdownSeconds: _editedSettings.countdownSeconds - 1,
                  );
                });
              }
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _editedSettings.countdownSeconds.toString(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              if (_editedSettings.countdownSeconds < 10) {
                setState(() {
                  _editedSettings = _editedSettings.copyWith(
                    countdownSeconds: _editedSettings.countdownSeconds + 1,
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredParticipantsSetting() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text(
            'Katılımcı Sayısını Zorunlu Tut',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Belirli sayıda katılımcı olmadan oyun başlamaz',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          value: _editedSettings.requireParticipantCount,
          activeColor: Colors.blue,
          onChanged: (value) {
            setState(() {
              _editedSettings =
                  _editedSettings.copyWith(requireParticipantCount: value);
            });
          },
        ),
        if (_editedSettings.requireParticipantCount)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Gerekli Katılımcı Sayısı: ${_editedSettings.requiredParticipants}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: () {
                        if (_editedSettings.requiredParticipants > 2) {
                          setState(() {
                            _editedSettings = _editedSettings.copyWith(
                              requiredParticipants:
                                  _editedSettings.requiredParticipants - 1,
                            );
                          });
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _editedSettings.requiredParticipants.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _editedSettings = _editedSettings.copyWith(
                            requiredParticipants:
                                _editedSettings.requiredParticipants + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildThemeModeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tema Seçimi',
            style: TextStyle(color: Colors.white),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildThemeOption(
                title: 'Aydınlık',
                icon: Icons.light_mode,
                isSelected: _editedSettings.themeMode == GameThemeMode.light,
                onTap: () {
                  setState(() {
                    _editedSettings = _editedSettings.copyWith(
                        themeMode: GameThemeMode.light);
                  });
                },
                color: Colors.blue.shade300,
              ),
              const SizedBox(width: 8),
              _buildThemeOption(
                title: 'Karanlık',
                icon: Icons.dark_mode,
                isSelected: _editedSettings.themeMode == GameThemeMode.dark,
                onTap: () {
                  setState(() {
                    _editedSettings =
                        _editedSettings.copyWith(themeMode: GameThemeMode.dark);
                  });
                },
                color: Colors.purple.shade700,
              ),
              const SizedBox(width: 8),
              _buildThemeOption(
                title: 'Neon',
                icon: Icons.nightlight_round,
                isSelected: _editedSettings.themeMode == GameThemeMode.neon,
                onTap: () {
                  setState(() {
                    _editedSettings =
                        _editedSettings.copyWith(themeMode: GameThemeMode.neon);
                  });
                },
                color: Colors.greenAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.black45,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightEffectSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Işık Efektleri',
            style: TextStyle(color: Colors.white),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildEffectOption(
                title: 'Standart',
                icon: Icons.lightbulb_outline,
                isSelected: _editedSettings.lightEffectStyle ==
                    LightEffectStyle.standard,
                onTap: () {
                  setState(() {
                    _editedSettings = _editedSettings.copyWith(
                        lightEffectStyle: LightEffectStyle.standard);
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildEffectOption(
                title: 'Nabız',
                icon: Icons.favorite,
                isSelected:
                    _editedSettings.lightEffectStyle == LightEffectStyle.pulse,
                onTap: () {
                  setState(() {
                    _editedSettings = _editedSettings.copyWith(
                        lightEffectStyle: LightEffectStyle.pulse);
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildEffectOption(
                title: 'Yıldızlar',
                icon: Icons.star,
                isSelected:
                    _editedSettings.lightEffectStyle == LightEffectStyle.stars,
                onTap: () {
                  setState(() {
                    _editedSettings = _editedSettings.copyWith(
                        lightEffectStyle: LightEffectStyle.stars);
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildParticleEffectSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Parçacık Efektleri',
            style: TextStyle(color: Colors.white),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildEffectOption(
                title: 'Konfeti',
                icon: Icons.celebration,
                isSelected: _editedSettings.particleEffect ==
                    ParticleEffectType.confetti,
                onTap: () {
                  setState(() {
                    _editedSettings = _editedSettings.copyWith(
                        particleEffect: ParticleEffectType.confetti);
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildEffectOption(
                title: 'Havai Fişek',
                icon: Icons.auto_awesome,
                isSelected: _editedSettings.particleEffect ==
                    ParticleEffectType.fireworks,
                onTap: () {
                  setState(() {
                    _editedSettings = _editedSettings.copyWith(
                        particleEffect: ParticleEffectType.fireworks);
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildEffectOption(
                title: 'Parıltı',
                icon: Icons.blur_on,
                isSelected: _editedSettings.particleEffect ==
                    ParticleEffectType.sparkle,
                onTap: () {
                  setState(() {
                    _editedSettings = _editedSettings.copyWith(
                        particleEffect: ParticleEffectType.sparkle);
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildEffectOption(
                title: 'Efektsiz',
                icon: Icons.do_not_disturb,
                isSelected:
                    _editedSettings.particleEffect == ParticleEffectType.none,
                onTap: () {
                  setState(() {
                    _editedSettings = _editedSettings.copyWith(
                        particleEffect: ParticleEffectType.none);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEffectOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.black45,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameModeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Oyun Modu Seçimi',
            style: TextStyle(color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildGameModeOption(
                title: 'Normal Mod',
                description: 'Tamamen rastgele seçim yapılır.',
                isSelected: _editedSettings.gameMode == GameMode.normal,
                onTap: () {
                  setState(() {
                    _editedSettings =
                        _editedSettings.copyWith(gameMode: GameMode.normal);
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildGameModeOption(
                title: 'Eleme Modu',
                description: 'Her turda bir kişi elenir, son kalan kazanır.',
                isSelected: _editedSettings.gameMode == GameMode.elimination,
                onTap: () {
                  setState(() {
                    _editedSettings = _editedSettings.copyWith(
                        gameMode: GameMode.elimination);
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildGameModeOption(
                title: 'Adil Mod',
                description:
                    'Şans faktörü azaltılır, daha önce seçilmeyenler önceliklendirilir.',
                isSelected: _editedSettings.gameMode == GameMode.fairMode,
                onTap: () {
                  setState(() {
                    _editedSettings =
                        _editedSettings.copyWith(gameMode: GameMode.fairMode);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameModeOption({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.black38,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.blue : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSequentialTouchSetting() {
    return SwitchListTile(
      title: const Text(
        'Teker Teker Dokunma',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        'Oyuncular aynı anda değil, sırayla dokunur',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      value: _sequentialTouching,
      activeColor: Colors.blue,
      onChanged: (value) {
        setState(() {
          _sequentialTouching = value;
        });
      },
    );
  }
}
