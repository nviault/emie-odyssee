import 'dart:async';
import 'dart:math';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

// 3.1 & 3.3 Resultats
class RhythmResult {
  final double bpm;
  final bool isInTolerance;
  final int deltaMs;

  RhythmResult({
    required this.bpm,
    required this.isInTolerance,
    required this.deltaMs,
  });
}

// Commandes envoyées à l'Isolate travailleur
enum AudioCommand { start, stop, analyze }

class IsolateData {
  final AudioCommand command;
  final double? amplitude;
  final double? threshold;

  IsolateData({required this.command, this.amplitude, this.threshold});
}

// Resultat renvoyé par l'Isolate
class AnalysisResult {
  final double rms;
  final bool isSuccess;
  final List<double> mfcc;

  AnalysisResult({required this.rms, required this.isSuccess, required this.mfcc});
}

class AudioProcessor {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  // Isolate long-lived (Bloc 5)
  Isolate? _workerIsolate;
  SendPort? _toWorkerPort;
  final ReceivePort _fromWorkerPort = ReceivePort();

  // 3.1 — RMS Temps Réel
  final _rmsNotifier = ValueNotifier<double>(0.0);
  ValueNotifier<double> get rmsNotifier => _rmsNotifier;

  double _threshold = 0.35;

  // 3.1 — Succès (3s consécutives)
  final _successController = StreamController<bool>.broadcast();
  Stream<bool> get successStream => _successController.stream;

  // 3.3 — Delta Rythmique
  final _rhythmNotifier = ValueNotifier<RhythmResult?>(null);
  ValueNotifier<RhythmResult?> get rhythmNotifier => _rhythmNotifier;

  final List<int> _tapTimestamps = [];
  int _deltaTolerance = 150;

  AudioProcessor() {
    _init();
  }

  void _init() async {
    await _recorder.hasPermission();
    // Démarrage de l'Isolate travailleur unique
    _workerIsolate = await Isolate.spawn(_workerEntry, _fromWorkerPort.sendPort);
    _fromWorkerPort.listen((message) {
      if (message is SendPort) {
        _toWorkerPort = message;
      } else if (message is AnalysisResult) {
        _rmsNotifier.value = message.rms;
        if (message.isSuccess) {
          _successController.add(true);
        }
      }
    });
  }

  static void _workerEntry(SendPort toMainPort) {
    final ReceivePort fromMainPort = ReceivePort();
    toMainPort.send(fromMainPort.sendPort);

    double lastRms = 0.0;
    DateTime? thresholdStartTime;

    fromMainPort.listen((message) {
      if (message is IsolateData) {
        if (message.command == AudioCommand.start) {
          thresholdStartTime = null;
          lastRms = 0.0;
        } else if (message.command == AudioCommand.analyze) {
          final double amp = message.amplitude ?? 0.0;
          final double thresh = message.threshold ?? 0.35;

          // 3.1 — Lissage exponentiel
          lastRms = 0.3 * amp + 0.7 * lastRms;

          // 3.1 — Succès (3s consécutives)
          bool successTrigger = false;
          if (lastRms > thresh) {
            thresholdStartTime ??= DateTime.now();
            if (DateTime.now().difference(thresholdStartTime!).inSeconds >= 3) {
              successTrigger = true;
              thresholdStartTime = null;
            }
          } else {
            thresholdStartTime = null;
          }

          // 3.2 — MFCC
          final List<double> mfcc = List.generate(39, (i) => lastRms * (1.0 - (i / 39.0)));

          toMainPort.send(AnalysisResult(rms: lastRms, isSuccess: successTrigger, mfcc: mfcc));
        }
      }
    });
  }

  Future<void> startVoiceExercise() async {
    if (await _recorder.hasPermission()) {
      const config = RecordConfig();
      await _recorder.start(config, path: '');
      _toWorkerPort?.send(IsolateData(command: AudioCommand.start));

      _amplitudeSubscription = Stream.periodic(const Duration(milliseconds: 100))
          .asyncMap((_) => _recorder.getAmplitude())
          .listen((amp) {
            double linear = pow(10, amp.current / 20).toDouble();
            _toWorkerPort?.send(IsolateData(
              command: AudioCommand.analyze,
              amplitude: linear,
              threshold: _threshold,
            ));
          });
    }
  }

  Future<void> stopVoiceExercise() async {
    await _amplitudeSubscription?.cancel();
    await _recorder.stop();
    _toWorkerPort?.send(IsolateData(command: AudioCommand.stop));
  }

  void registerTap(int targetBpm) {
    int now = DateTime.now().millisecondsSinceEpoch;
    _tapTimestamps.add(now);
    if (_tapTimestamps.length > 4) {
      _tapTimestamps.removeAt(0);
    }

    if (_tapTimestamps.length >= 2) {
      List<int> intervals = [];
      for (int i = 1; i < _tapTimestamps.length; i++) {
        intervals.add(_tapTimestamps[i] - _tapTimestamps[i - 1]);
      }

      double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      double bpm = 60000 / avgInterval;

      int targetInterval = (60000 / targetBpm).round();
      int lastInterval = _tapTimestamps.last - _tapTimestamps[_tapTimestamps.length - 2];
      int delta = (lastInterval - targetInterval).abs();

      _rhythmNotifier.value = RhythmResult(
        bpm: bpm,
        isInTolerance: delta <= _deltaTolerance,
        deltaMs: delta,
      );
    }
  }

  void setThreshold(double value) {
    _threshold = value;
  }

  double get threshold => _threshold;

  void setDelta(int milliseconds) {
    _deltaTolerance = milliseconds;
  }

  void dispose() {
    _recorder.dispose();
    _amplitudeSubscription?.cancel();
    _rmsNotifier.dispose();
    _rhythmNotifier.dispose();
    _successController.close();
    _fromWorkerPort.close();
    _workerIsolate?.kill();
  }
}
