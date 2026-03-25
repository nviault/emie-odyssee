import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'ui/theme/ac_theme.dart';
import 'core/audio/audio_processor.dart';
import 'core/rewards/reward_system.dart';
import 'ui/widgets/island_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EmieOdysseeApp());
}

class EmieOdysseeApp extends StatelessWidget {
  const EmieOdysseeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "L'Odyssée de l'Île d'Émie",
      theme: ACTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AudioProcessor _audioProcessor = AudioProcessor();
  final RewardSystem _rewardSystem = RewardSystem();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _successSub;

  bool _isGameActive = false;
  String _currentExercise = '';
  int _stars = 0;
  bool _showRewardAnimation = false;
  bool _showFlash = false;

  // Pro Settings
  int _bpm = 60;
  int _delta = 200;
  double _micSensitivity = 50.0;

  Timer? _proLongPressTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _successSub = _audioProcessor.successStream.listen((_) => _handleSuccess());
  }

  @override
  void dispose() {
    _successSub?.cancel();
    _audioProcessor.dispose();
    _rewardSystem.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bpm = prefs.getInt('bpm') ?? 60;
      _delta = prefs.getInt('delta') ?? 200;
      _micSensitivity = prefs.getDouble('mic') ?? 50.0;
      _stars = prefs.getInt('stars') ?? 0;
    });
    _audioProcessor.setThreshold(1.0 - (_micSensitivity / 100));
    _audioProcessor.setDelta(_delta);
    await _rewardSystem.loadState();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bpm', _bpm);
    await prefs.setInt('delta', _delta);
    await prefs.setDouble('mic', _micSensitivity);
    await prefs.setInt('stars', _stars);
  }

  void _startExercise(String type) {
    setState(() {
      _isGameActive = true;
      _currentExercise = type;
    });

    if (type == 'voice' || type == 'prompt') {
      _audioProcessor.startVoiceExercise();
    }
  }

  void _stopExercise() {
    _audioProcessor.stopVoiceExercise();
    setState(() {
      _isGameActive = false;
      _currentExercise = '';
    });
  }

  void _handleSuccess() {
    if (_showFlash || !_isGameActive) return;

    setState(() {
      _stars++;
      _showFlash = true;
    });

    _playRewardSound();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showFlash = false);
    });

    _saveSettings();

    if (_stars >= 3) {
      setState(() {
        _stars = 0;
        _showRewardAnimation = true;
      });
      _rewardSystem.triggerRewardSequence();
    }
  }

  void _playRewardSound() {
     _audioPlayer.play(AssetSource('sounds/bell.wav')).catchError((_) => null);
  }

  void _showProPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProPanel(
        bpm: _bpm,
        delta: _delta,
        mic: _micSensitivity,
        onChanged: (newBpm, newDelta, newMic) {
          setState(() {
            _bpm = newBpm;
            _delta = newDelta;
            _micSensitivity = newMic;
          });
          _audioProcessor.setDelta(_delta);
          _audioProcessor.setThreshold(1.0 - (_micSensitivity / 100));
          _saveSettings();
        },
        onReset: () async {
          await _rewardSystem.resetIsland();
          setState(() {
            _stars = 0;
          });
          _saveSettings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ACTheme.colorSkyHigh, ACTheme.colorBackground],
              ),
            ),
          ),

          Center(
            child: IslandWidget(
              objects: _rewardSystem.currentObjects,
              showRewardAnimation: _showRewardAnimation,
              isLoutreActive: _rewardSystem.isLoutreActive,
              onAnimationComplete: () {
                setState(() {
                  _showRewardAnimation = false;
                  if (_isGameActive) _stopExercise();
                });
              },
            ),
          ),

          if (!_isGameActive) ...[
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "L'Île d'Émie",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: ACTheme.colorAccentWarm,
                    shadows: [
                      const Shadow(color: Colors.white, offset: Offset(2, 2)),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ACMenuButton(label: "Rythme", onTap: () => _startExercise('rhythm')),
                      const SizedBox(width: 20),
                      _ACMenuButton(label: "Voix", onTap: () => _startExercise('voice')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    children: [
                      _ACMenuButton(label: "Ascenseur", onTap: () => _startExercise('prompt'), color: ACTheme.colorAccentWarm),
                      _ACMenuButton(label: "Bisou", onTap: () => _startExercise('prompt'), color: ACTheme.colorAccentWarm),
                      _ACMenuButton(label: "Saut", onTap: () => _startExercise('prompt'), color: ACTheme.colorAccentWarm),
                    ],
                  ),
                ],
              ),
            ),
          ],

          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: ACTheme.colorAccentWarm, width: 3),
              ),
              child: Text("Étoiles : $_stars/3", style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),

          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onLongPressStart: (_) {
                _proLongPressTimer = Timer(const Duration(seconds: 5), _showProPanel);
              },
              onLongPressEnd: (_) {
                _proLongPressTimer?.cancel();
              },
              child: Container(
                width: 100,
                height: 100,
                color: Colors.transparent,
              ),
            ),
          ),

          if (_isGameActive)
            _GameOverlay(
              exercise: _currentExercise,
              audioProcessor: _audioProcessor,
              onClose: _stopExercise,
              onTap: () {
                if (_currentExercise == 'rhythm') {
                  _audioProcessor.registerTap(_bpm);
                  _handleSuccess();
                }
              },
            ),

          if (_showFlash)
            Positioned.fill(
              child: Container(
                color: ACTheme.colorFlash,
              ),
            ),
        ],
      ),
    );
  }
}

class _ACMenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ACMenuButton({required this.label, required this.onTap, this.color});

  @override
  State<_ACMenuButton> createState() => _ACMenuButtonState();
}

class _ACMenuButtonState extends State<_ACMenuButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.05), weight: 120),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 80),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ACFlatShadowDecorator(
        child: ElevatedButton(
          onPressed: () {
            _controller.forward(from: 0.0);
            widget.onTap();
          },
          style: widget.color != null ? ElevatedButton.styleFrom(backgroundColor: widget.color) : null,
          child: Text(widget.label),
        ),
      ),
    );
  }
}

class _GameOverlay extends StatelessWidget {
  final String exercise;
  final AudioProcessor audioProcessor;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const _GameOverlay({
    required this.exercise,
    required this.audioProcessor,
    required this.onClose,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    String title = exercise.substring(0, 1).toUpperCase() + exercise.substring(1);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: ACTheme.colorCardOverlay,
        child: Center(
          child: ACFlatShadowDecorator(
            child: Card(
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 20),
                    const Text("Fais du bruit ou tapote !", textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<double>(
                      valueListenable: audioProcessor.rmsNotifier,
                      builder: (context, rms, child) {
                        return Container(
                          width: 200,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ACTheme.colorBorder, width: 2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: rms.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: ACTheme.colorPrimary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(onPressed: onClose, child: const Text("Quitter")),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProPanel extends StatefulWidget {
  final int bpm;
  final int delta;
  final double mic;
  final Function(int, int, double) onChanged;
  final VoidCallback onReset;

  const _ProPanel({
    required this.bpm,
    required this.delta,
    required this.mic,
    required this.onChanged,
    required this.onReset,
  });

  @override
  State<_ProPanel> createState() => _ProPanelState();
}

class _ProPanelState extends State<_ProPanel> {
  late double _bpm;
  late double _delta;
  late double _mic;

  @override
  void initState() {
    super.initState();
    _bpm = widget.bpm.toDouble();
    _delta = widget.delta.toDouble();
    _mic = widget.mic;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: ACTheme.colorSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(top: BorderSide(color: ACTheme.colorBorder, width: 2.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Espace Pro", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Text("BPM : ${_bpm.round()}"),
          Slider(
            value: _bpm,
            min: 40,
            max: 120,
            activeColor: ACTheme.colorPrimary,
            onChanged: (v) => setState(() => _bpm = v),
            onChangeEnd: (v) => widget.onChanged(_bpm.round(), _delta.round(), _mic),
          ),
          Text("Delta (ms) : ${_delta.round()}"),
          Slider(
            value: _delta,
            min: 50,
            max: 400,
            activeColor: ACTheme.colorSecondary,
            onChanged: (v) => setState(() => _delta = v),
            onChangeEnd: (v) => widget.onChanged(_bpm.round(), _delta.round(), _mic),
          ),
          Text("Sensibilité micro : ${_mic.round()}"),
          Slider(
            value: _mic,
            min: 1,
            max: 100,
            activeColor: ACTheme.colorAccentWarm,
            onChanged: (v) => setState(() => _mic = v),
            onChangeEnd: (v) => widget.onChanged(_bpm.round(), _delta.round(), _mic),
          ),
          const Divider(height: 40, color: ACTheme.colorBorder),
          Center(
            child: ElevatedButton(
              onPressed: widget.onReset,
              style: ElevatedButton.styleFrom(backgroundColor: ACTheme.colorAccentWarm),
              child: const Text("Réinitialiser l'île"),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer"))),
        ],
      ),
    );
  }
}
