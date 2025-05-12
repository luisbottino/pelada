import 'package:hive_flutter/hive_flutter.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/waiting_queue.dart';

class StorageService {
  static const String _matchesBoxName = 'matches';
  static const String _playersBoxName = 'players';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Registra os adaptadores
    Hive.registerAdapter(PlayerAdapter());
    Hive.registerAdapter(TeamFormatAdapter());
    Hive.registerAdapter(TeamAdapter());
    Hive.registerAdapter(WaitingQueueAdapter());
    Hive.registerAdapter(TeamSelectionModeAdapter());
    Hive.registerAdapter(MatchAdapter());

    await Hive.deleteBoxFromDisk(_matchesBoxName);
    
    // Abre as boxes
    await Hive.openBox<Match>(_matchesBoxName);
    await Hive.openBox<Player>(_playersBoxName);
  }

  // Métodos para Match
  static Future<void> saveMatch(Match match) async {
    final box = Hive.box<Match>(_matchesBoxName);
    await box.put(match.id, match);
  }

  static Future<Match?> getMatch(String id) async {
    final box = Hive.box<Match>(_matchesBoxName);
    return box.get(id);
  }

  static Future<List<Match>> getAllMatches() async {
    final box = Hive.box<Match>(_matchesBoxName);
    return box.values.toList();
  }

  static Future<void> deleteMatch(String id) async {
    final box = Hive.box<Match>(_matchesBoxName);
    await box.delete(id);
  }

  // Métodos para Player
  static Future<void> savePlayer(Player player) async {
    final box = Hive.box<Player>(_playersBoxName);
    await box.put(player.id, player);
  }

  static Future<Player?> getPlayer(String id) async {
    final box = Hive.box<Player>(_playersBoxName);
    return box.get(id);
  }

  static Future<List<Player>> getAllPlayers() async {
    final box = Hive.box<Player>(_playersBoxName);
    return box.values.toList();
  }

  static Future<void> deletePlayer(String id) async {
    final box = Hive.box<Player>(_playersBoxName);
    await box.delete(id);
  }
} 