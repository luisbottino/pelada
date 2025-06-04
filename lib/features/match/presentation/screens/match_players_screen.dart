import 'package:flutter/material.dart';
import '../../../../core/models/match.dart';
import '../../../../core/models/team.dart';
import '../../../../core/models/player.dart';
import '../../../../core/services/storage_service.dart';
import '../components/app_logo_bar.dart';
import 'match_teams_screen.dart';

class MatchPlayersScreen extends StatefulWidget {
  final Match match;

  const MatchPlayersScreen({
    super.key,
    required this.match,
  });

  @override
  State<MatchPlayersScreen> createState() => _MatchPlayersScreenState();
}

class _MatchPlayersScreenState extends State<MatchPlayersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSetter = false;
  bool _isLoading = false;
  List<Player> _players = [];
  List<Player> _setters = [];

  @override
  void initState() {
    super.initState();
    _players = List.from(widget.match.players);
    _players = List.from(widget.match.setters);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final player = Player(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          isSetter: _isSetter,
        );

        // Verifica se já existe um jogador com o mesmo nome
        if (_players.any((p) => p.name.toLowerCase() == player.name.toLowerCase())
        || _setters.any((p) => p.name.toLowerCase() == player.name.toLowerCase())) {
          throw Exception('Já existe um jogador com este nome');
        }

        setState(() {
          if (_isSetter) {
            _setters.add(player);
          } else {
            _players.add(player);
          }
        });

        _nameController.clear();
        _isSetter = false;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _removePlayer(Player player) async {
    setState(() {
      if (player.isSetter) {
        _setters.remove(player);
      } else {
        _players.remove(player);
      }
    });
  }

  Future<void> _finishRegistration() async {
    // Verifica se tem jogadores suficientes para formar 2 times
    final playersPerTeam = _getPlayersPerTeam();
    final minPlayers = playersPerTeam * 2; // Mínimo para 2 times

    if (_players.length < minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'É necessário ter pelo menos $minPlayers jogadores para formar 2 times',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Se a opção de separar levantadores estiver ativa, verifica se tem pelo menos 2
    if (widget.match.separateSetters && _setters.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário ter pelo menos 2 levantadores'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Atualiza a pelada com os jogadores registrados
      final updatedMatch = widget.match.copyWith(
        players: _players,
        setters: _setters
      );

      // Salva a pelada atualizada
      await StorageService.saveMatch(updatedMatch);

      if (mounted) {
        // Navega para a tela de times
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MatchTeamsScreen(match: updatedMatch),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar pelada: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _getPlayersPerTeam() {
    switch (widget.match.format) {
      case TeamFormat.twoVsTwo:
        return 2;
      case TeamFormat.threeVsThree:
        return 3;
      case TeamFormat.fourVsFour:
        return 4;
      case TeamFormat.sixVsSix:
        return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppLogoBar(),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.match.separateSetters
                ? Row(
                    children: [
                      // Lista de jogadores normais
                      Expanded(
                        child: _buildPlayersList(
                          title: 'Jogadores',
                          players: _players,
                        ),
                      ),
                      const VerticalDivider(),
                      // Lista de levantadores
                      Expanded(
                        child: _buildPlayersList(
                          title: 'Levantadores',
                          players: _setters,
                        ),
                      ),
                    ],
                  )
                : _buildPlayersList(
                    title: 'Jogadores',
                    players: _players,
                  ),
          ),
          // Formulário para adicionar jogador
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Jogador',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome do jogador';
                      }
                      return null;
                    },
                  ),
                  if (widget.match.separateSetters) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Levantador?'),
                      value: _isSetter,
                      onChanged: (value) {
                        setState(() {
                          _isSetter = value ?? false;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addPlayer,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.white
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Adicionar Jogador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _finishRegistration,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white
                          ),
                          child: const Text('Criar times', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList({
    required String title,
    required List<Player> players,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final counter = index + 1;
              return Card(
                child: ListTile(
                  title: Text(counter.toString() + ' - ' + player.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removePlayer(player),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 