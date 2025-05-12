import 'package:flutter/material.dart';
import '../../../../core/models/match.dart';
import '../../../../core/models/team.dart';
import '../../../../core/models/player.dart';
import '../../../../core/services/storage_service.dart';

class MatchTeamsScreen extends StatefulWidget {
  final Match match;

  const MatchTeamsScreen({super.key, required this.match});

  @override
  State<MatchTeamsScreen> createState() => _MatchTeamsScreenState();
}

class _MatchTeamsScreenState extends State<MatchTeamsScreen> {
  late Match _match;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _generateTeams();
  }

  Future<void> _generateTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Gera os times baseado no modo de seleção
      final updatedMatch = _match.generateTeams();

      // Salva a pelada atualizada
      await StorageService.saveMatch(updatedMatch);

      setState(() {
        _match = updatedMatch;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar times: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Times Formados')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Times formados
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time 1
                        Expanded(
                          child: _buildTeamCard(
                            team: _match.teamInCourtA,
                            isFirstTeam: true,
                          ),
                        ),
                        const SizedBox(width: 2),
                        // Time 2
                        Expanded(
                          child: _buildTeamCard(
                            team: _match.teamInCourtB,
                            isFirstTeam: false,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Próximo time
                    if (_shouldDisplayNextTeam(_match.nextTeam))
                      _buildTeamCard(team: _match.nextTeam, isFirstTeam: false),
                    // Filas de espera
                    _match.separateSetters
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fila de jogadores normais
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTitleForPlayerList('Jogadores'),
                                  _buildWaitingQueue(
                                    players: _match.waitingQueue.players,
                                  ),
                                ],
                              ),
                            ),
                            const VerticalDivider(),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTitleForPlayerList('Levantadores'),
                                    _buildWaitingQueue(
                                      players: _match.waitingQueue.setterQueue,
                                    )
                                  ]
                              ),
                            )
                          ],
                        )
                        : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitleForPlayerList('Fila de Espera'),
                              _buildWaitingQueue(
                                players: _match.waitingQueue.players,
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildTitleForPlayerList(String title) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Jogadores',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTeamCard({required Team team, required bool isFirstTeam}) {
    final List<Player> displayPlayers = [
      if (team.setter != null) team.setter!,
      ...team.players,
    ];

    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Cabeçalho do time
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFirstTeam ? Colors.blue.shade100 : Colors.red.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Lista de jogadores
          SizedBox(
            width: double.infinity,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(5),
              itemCount: displayPlayers.length,
              itemBuilder: (context, index) {
                final player = displayPlayers[index];
                final isSetter =
                    team.setter != null && player.id == team.setter!.id;
                return ListTile(
                  title: Text(player.name),
                  subtitle: isSetter ? const Text('Levantador') : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingQueue({
    required List<Player> players,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return Card(child: ListTile(title: Text(player.name)));
        },
      ),
    );
  }

  bool _shouldDisplayNextTeam(Team team) {
    return team.players.isNotEmpty || team.setter != null;
  }
}
