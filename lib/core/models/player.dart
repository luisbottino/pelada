import 'package:hive/hive.dart';

part 'player.g.dart';

@HiveType(typeId: 0)
class Player {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final bool isSetter; // Indica se o jogador é levantador

  Player({
    required this.id,
    required this.name,
    this.isSetter = false,
  });

  // Método para criar uma cópia do jogador com campos modificados
  Player copyWith({
    String? id,
    String? name,
    bool? isSetter,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isSetter: isSetter ?? this.isSetter,
    );
  }

  // Método para converter o jogador em um Map (útil para persistência)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isSetter': isSetter,
    };
  }

  // Método para criar um jogador a partir de um Map
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      name: map['name'] as String,
      isSetter: map['isSetter'] as bool,
    );
  }

  @override
  String toString() => 'Player(id: $id, name: $name, isSetter: $isSetter)';
} 