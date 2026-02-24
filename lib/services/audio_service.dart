import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

abstract class AudioService {
  Future<void> initialize();
  Future<void> setSoundEnabled(bool enabled);
  Future<void> onAppLifecycleChange(AppLifecycleState state);
  Future<void> playCollect();
  Future<void> playPurchase();
  Future<void> playLevelUp();
  Future<void> playBoost();
  Future<void> playPrestige();
}

class SynthAudioService implements AudioService {
  SynthAudioService();

  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _initialized = false;
  bool _enabled = false;
  bool _foreground = true;

  late final Uint8List _musicLoop;
  late final Uint8List _collectSfx;
  late final Uint8List _purchaseSfx;
  late final Uint8List _levelUpSfx;
  late final Uint8List _boostSfx;
  late final Uint8List _prestigeSfx;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _musicLoop = _buildMusicLoop();
    _collectSfx = _buildGlideSfx(
      startHz: 900,
      endHz: 1280,
      durationSeconds: 0.11,
      volume: 0.5,
    );
    _purchaseSfx = _buildStackedSfx(
      tones: const [
        _Tone(hz: 420, seconds: 0.06),
        _Tone(hz: 560, seconds: 0.08),
      ],
      volume: 0.45,
    );
    _levelUpSfx = _buildStackedSfx(
      tones: const [
        _Tone(hz: 520, seconds: 0.06),
        _Tone(hz: 680, seconds: 0.07),
        _Tone(hz: 840, seconds: 0.1),
      ],
      volume: 0.58,
    );
    _boostSfx = _buildStackedSfx(
      tones: const [
        _Tone(hz: 720, seconds: 0.08),
        _Tone(hz: 920, seconds: 0.08),
        _Tone(hz: 1160, seconds: 0.1),
      ],
      volume: 0.52,
    );
    _prestigeSfx = _buildGlideSfx(
      startHz: 520,
      endHz: 180,
      durationSeconds: 0.35,
      volume: 0.62,
    );

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _initialized = true;
  }

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    _enabled = enabled;
    if (!_initialized) {
      await initialize();
    }

    if (_enabled && _foreground) {
      await _startMusic();
    } else {
      await _musicPlayer.stop();
    }
  }

  @override
  Future<void> onAppLifecycleChange(AppLifecycleState state) async {
    _foreground = state == AppLifecycleState.resumed;
    if (!_initialized) {
      return;
    }

    if (_enabled && _foreground) {
      await _startMusic();
    } else {
      await _musicPlayer.stop();
    }
  }

  @override
  Future<void> playCollect() => _playSfx(_collectSfx, volume: 0.68);

  @override
  Future<void> playPurchase() => _playSfx(_purchaseSfx, volume: 0.62);

  @override
  Future<void> playLevelUp() => _playSfx(_levelUpSfx, volume: 0.72);

  @override
  Future<void> playBoost() => _playSfx(_boostSfx, volume: 0.72);

  @override
  Future<void> playPrestige() => _playSfx(_prestigeSfx, volume: 0.8);

  Future<void> _startMusic() async {
    await _musicPlayer.stop();
    await _musicPlayer.play(BytesSource(_musicLoop), volume: 0.22);
  }

  Future<void> _playSfx(Uint8List bytes, {required double volume}) async {
    if (!_enabled || !_initialized) {
      return;
    }

    final player = AudioPlayer();
    StreamSubscription<void>? subscription;

    try {
      subscription = player.onPlayerComplete.listen((_) {
        unawaited(subscription?.cancel());
        unawaited(player.dispose());
      });

      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(BytesSource(bytes), volume: volume);
    } catch (_) {
      await subscription?.cancel();
      await player.dispose();
    }
  }

  Uint8List _buildMusicLoop() {
    const notes = <_Tone>[
      _Tone(hz: 392, seconds: 0.2),
      _Tone(hz: 440, seconds: 0.2),
      _Tone(hz: 523, seconds: 0.2),
      _Tone(hz: 659, seconds: 0.26),
      _Tone(hz: 587, seconds: 0.22),
      _Tone(hz: 523, seconds: 0.2),
      _Tone(hz: 440, seconds: 0.2),
      _Tone(hz: 392, seconds: 0.28),
      _Tone(hz: 330, seconds: 0.2),
      _Tone(hz: 392, seconds: 0.2),
      _Tone(hz: 440, seconds: 0.2),
      _Tone(hz: 523, seconds: 0.34),
    ];

    return _buildStackedSfx(
      tones: notes,
      volume: 0.22,
      sampleRate: 22050,
      includeHarmony: true,
      includePulse: true,
    );
  }

  Uint8List _buildStackedSfx({
    required List<_Tone> tones,
    required double volume,
    int sampleRate = 22050,
    bool includeHarmony = false,
    bool includePulse = false,
  }) {
    final totalSamples = tones
        .map((tone) => (tone.seconds * sampleRate).floor())
        .fold<int>(0, (sum, part) => sum + part);

    final pcm = Float32List(totalSamples);
    var writeIndex = 0;

    for (final tone in tones) {
      final samples = (tone.seconds * sampleRate).floor();
      for (var i = 0; i < samples; i += 1) {
        final t = i / sampleRate;
        final progress = i / max(1, samples - 1);
        final attack = min(1.0, progress / 0.08);
        final release = min(1.0, (1 - progress) / 0.2);
        final envelope = attack * release;

        var value = sin(2 * pi * tone.hz * t);
        if (includeHarmony) {
          value += 0.28 * sin(2 * pi * tone.hz * 1.5 * t);
        }
        if (includePulse) {
          value += 0.22 * sin(2 * pi * 2 * t);
        }

        pcm[writeIndex + i] = (value * envelope * volume).clamp(-1, 1);
      }
      writeIndex += samples;
    }

    return _pcm16ToWav(pcm, sampleRate: sampleRate);
  }

  Uint8List _buildGlideSfx({
    required double startHz,
    required double endHz,
    required double durationSeconds,
    required double volume,
    int sampleRate = 22050,
  }) {
    final samples = (durationSeconds * sampleRate).floor();
    final pcm = Float32List(samples);

    var phase = 0.0;
    for (var i = 0; i < samples; i += 1) {
      final progress = i / max(1, samples - 1);
      final hz = startHz + (endHz - startHz) * progress;
      final attack = min(1.0, progress / 0.12);
      final release = min(1.0, (1 - progress) / 0.25);
      final envelope = attack * release;

      phase += (2 * pi * hz) / sampleRate;
      final value = sin(phase) + (0.24 * sin(phase * 0.5));
      pcm[i] = (value * envelope * volume).clamp(-1, 1);
    }

    return _pcm16ToWav(pcm, sampleRate: sampleRate);
  }

  Uint8List _pcm16ToWav(Float32List samples, {required int sampleRate}) {
    final bytesPerSample = 2;
    final channels = 1;
    final dataSize = samples.length * bytesPerSample;
    final totalSize = 44 + dataSize;

    final data = ByteData(totalSize);

    void writeString(int offset, String value) {
      for (var i = 0; i < value.length; i += 1) {
        data.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    data.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
    data.setUint16(32, channels * bytesPerSample, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    data.setUint32(40, dataSize, Endian.little);

    var offset = 44;
    for (final sample in samples) {
      final clamped = sample.clamp(-1.0, 1.0);
      final intSample = (clamped * 32767).round();
      data.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return data.buffer.asUint8List();
  }
}

class _Tone {
  const _Tone({required this.hz, required this.seconds});

  final double hz;
  final double seconds;
}
