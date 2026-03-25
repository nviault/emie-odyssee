import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

// Type d'objet pour l'île (Bloc 0)
class IslandObject {
  final String icon;
  final int x;
  final int y;

  IslandObject({required this.icon, required this.x, required this.y});

  Map<String, dynamic> toJson() => {'icon': icon, 'x': x, 'y': y};
  factory IslandObject.fromJson(Map<String, dynamic> json) {
    return IslandObject(
      icon: json['icon'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
    );
  }

  @override
  String toString() => '$icon|$x|$y';

  static IslandObject fromString(String s) {
    final parts = s.split('|');
    return IslandObject(icon: parts[0], x: int.parse(parts[1]), y: int.parse(parts[2]));
  }
}

enum RewardEvent { success, characterEnters, objectAppears, characterLeaves }

class RewardSystem {
  final _rewardController = StreamController<RewardEvent>.broadcast();
  Stream<RewardEvent> get rewardStream => _rewardController.stream;

  final List<IslandObject> _currentObjects = [];
  List<IslandObject> get currentObjects => List.unmodifiable(_currentObjects);

  int get objectCount => _currentObjects.length;

  bool _isLoutreNext = true;
  DateTime? _lastRewardTime;

  final List<String> _rewardsPool = [
    '🌸', '🌳', '✨', '☁️', '💎', '🐚', '🍄', '🏮', '⛲', '🪨', '🦋', '🐝'
  ];

  RewardSystem();

  bool canTriggerReward() {
    if (_lastRewardTime == null) return true;
    return DateTime.now().difference(_lastRewardTime!) > const Duration(seconds: 10);
  }

  Future<void> triggerRewardSequence() async {
    if (!canTriggerReward()) return;
    _lastRewardTime = DateTime.now();

    _rewardController.add(RewardEvent.success);
    await Future.delayed(const Duration(milliseconds: 400));
    _rewardController.add(RewardEvent.characterEnters);
    await Future.delayed(const Duration(milliseconds: 1200));

    final random = Random();
    final icon = _rewardsPool[random.nextInt(_rewardsPool.length)];

    if (_currentObjects.length < 12) {
      int row = _currentObjects.length ~/ 4;
      int col = _currentObjects.length % 4;
      int x = (col * 25) + 10 + random.nextInt(5);
      int y = (row * 30) + 10 + random.nextInt(5);

      _currentObjects.add(IslandObject(icon: icon, x: x, y: y));
      await saveState();
    }

    _rewardController.add(RewardEvent.objectAppears);
    await Future.delayed(const Duration(milliseconds: 1500));
    _rewardController.add(RewardEvent.characterLeaves);
    _isLoutreNext = !_isLoutreNext;
  }

  bool get isLoutreActive => _isLoutreNext;

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? objectsStr = prefs.getStringList('island_objects_v1');
    if (objectsStr != null) {
      _currentObjects.clear();
      for (final s in objectsStr) {
        _currentObjects.add(IslandObject.fromString(s));
      }
    }
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> objectsStr = _currentObjects.map((o) => o.toString()).toList();
    await prefs.setStringList('island_objects_v1', objectsStr);
  }

  Future<void> resetIsland() async {
    _currentObjects.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('island_objects_v1');
  }

  void dispose() {
    _rewardController.close();
  }
}
