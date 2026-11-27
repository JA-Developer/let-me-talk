import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tamaño visual de las tarjetas de pictogramas para adaptarse a cada persona.
enum GridDensity {
  large,
  medium,
  compact,
}

class VoiceViewSettings {
  final double speechRate;
  final double speechPitch;
  final bool speakOnTap;
  final GridDensity gridDensity;

  const VoiceViewSettings({
    this.speechRate = 0.48,
    this.speechPitch = 1.0,
    this.speakOnTap = true,
    this.gridDensity = GridDensity.medium,
  });

  VoiceViewSettings copyWith({
    double? speechRate,
    double? speechPitch,
    bool? speakOnTap,
    GridDensity? gridDensity,
  }) {
    return VoiceViewSettings(
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      speakOnTap: speakOnTap ?? this.speakOnTap,
      gridDensity: gridDensity ?? this.gridDensity,
    );
  }
}

/// Ajustes accesibles de voz, tamaño de cuadrícula e información de LetMeTalk y ARASAAC.
class SettingsSheet extends StatefulWidget {
  final VoiceViewSettings initialSettings;
  final ValueChanged<VoiceViewSettings> onChanged;
  final VoidCallback onTestVoice;

  const SettingsSheet({
    super.key,
    required this.initialSettings,
    required this.onChanged,
    required this.onTestVoice,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late VoiceViewSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _update(VoiceViewSettings next) {
    setState(() => _settings = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppTheme.primaryDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ajustes y Acerca de',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Material(
                color: AppTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppTheme.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: AppTheme.primary,
                        title: const Text(
                          'Leer al tocar un pictograma',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: const Text(
                          'Pronuncia cada palabra al agregarla a la frase',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        value: _settings.speakOnTap,
                        onChanged: (v) =>
                            _update(_settings.copyWith(speakOnTap: v)),
                      ),
                      const Divider(height: 20),
                      const Text(
                        'Tamaño de pictogramas',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<GridDensity>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: GridDensity.large,
                            label: Text('Grande'),
                          ),
                          ButtonSegment(
                            value: GridDensity.medium,
                            label: Text('Normal'),
                          ),
                          ButtonSegment(
                            value: GridDensity.compact,
                            label: Text('Compacto'),
                          ),
                        ],
                        selected: {_settings.gridDensity},
                        onSelectionChanged: (selected) {
                          _update(
                            _settings.copyWith(gridDensity: selected.first),
                          );
                        },
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Velocidad de voz',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            _rateLabel(_settings.speechRate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _settings.speechRate,
                        min: 0.25,
                        max: 0.80,
                        divisions: 11,
                        activeColor: AppTheme.primary,
                        onChanged: (v) =>
                            _update(_settings.copyWith(speechRate: v)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tono de voz',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${_settings.speechPitch.toStringAsFixed(1)}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _settings.speechPitch,
                        min: 0.8,
                        max: 1.3,
                        divisions: 10,
                        activeColor: AppTheme.primary,
                        onChanged: (v) =>
                            _update(_settings.copyWith(speechPitch: v)),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: widget.onTestVoice,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primarySoft,
                            foregroundColor: AppTheme.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.record_voice_over_rounded),
                          label: const Text(
                            'Probar voz',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0FDFA), Color(0xFFEEF2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.forum_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Acerca de LetMeTalk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'LetMeTalk es una aplicación de Comunicación Aumentativa y Alternativa (CAA) creada originalmente por AppNotize UG para ayudar a personas con dificultades del habla a expresarse mediante pictogramas.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pictogramas cortesía de ARASAAC (arasaac.org) — Gobierno de Aragón, bajo licencia Creative Commons BY-NC-SA. Más de 9,000 imágenes disponibles desde el buscador.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rateLabel(double rate) {
    if (rate < 0.4) return 'Pausada';
    if (rate > 0.6) return 'Rápida';
    return 'Natural';
  }
}
