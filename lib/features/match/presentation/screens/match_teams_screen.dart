import 'package:flutter/material.dart';
import '../components/app_logo_bar.dart';
import 'player_management_screen.dart';

import '../../../../core/extensions/match_helpers.dart';
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
  final primaryColor = Color(0xFF1976D2);
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
      appBar: AppBar(
        title: AppLogoBar(),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: _showOptionsMenu,
        elevation: 6,
        child: const Icon(Icons.sports_volleyball, color: Colors.white),
      ),
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
                            colorTeam: Colors.green.shade100,
                          ),
                        ),
                        const SizedBox(width: 2),
                        // Time 2
                        Expanded(
                          child: _buildTeamCard(
                            team: _match.teamInCourtB,
                            colorTeam: Colors.blue.shade100,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Próximo time
                    if (_shouldDisplayNextTeam(_match.nextTeam))
                      _buildTeamCard(
                          team: _match.nextTeam,
                          colorTeam: Colors.yellow.shade100,
                      ),
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
                                  _buildTitleForPlayerList(title: 'Jogadores'),
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
                                    _buildTitleForPlayerList(title: 'Levantadores'),
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
                              _buildTitleForPlayerList(title: 'Fila de Espera'),
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

  Widget _buildTitleForPlayerList({required String title}) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTeamCard({required Team team, required Color colorTeam}) {
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
              color: colorTeam,
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
                const SizedBox(width: 10),
                if (team.victories > 0) ...[
                  Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20,),
                  const SizedBox(width: 4),
                  Text(
                    '${team.victories}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold
                    ),
                  )
                ]
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

  void _showOptionsMenu() {
    final hasNext = _match.hasNextTeamPlayers();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.navigate_next),
                title: const Text('Próximo time'),
                enabled: hasNext,
                onTap: hasNext
                    ? () {
                          Navigator.pop(context);
                          _callNextTeam();
                        }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar lista'),
                onTap: () {
                  Navigator.pop(context);
                  _callEditPlayers();
                },
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Início'),
                onTap: () {
                  Navigator.pushNamed(context, '/');
                },
              )
            ],
          ),
        );
      }
    );
  }

  void _callEditPlayers() async {
    final updatedMatch = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayersManagementScreen(match: _match),
      ),
    );

    if (updatedMatch != null) {
      setState(() {
        _match = updatedMatch.generateTeams();
      });

      await StorageService.saveMatch(_match);
    }
  }

  void _callNextTeam() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black
                  ),
                  children: [
                    const TextSpan(text: 'Selecione o '),
                    TextSpan(
                      text: 'VENCEDOR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextSpan(text: ' da partida'),
                  ]
                ),
              ),
              icon: Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 48,
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.groups, color: Colors.green,),
                      label: Text(
                        _match.teamInCourtA.name,
                        style: TextStyle(
                            color: Colors.green
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _processNextRound(winningTeam: _match.teamInCourtA);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.groups, color: Colors.blue),
                      label: Text(
                        _match.teamInCourtB.name,
                        style: TextStyle(
                            color: Colors.blue
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _processNextRound(winningTeam: _match.teamInCourtB);
                      },
                    ),
                  )
                ],
              )
          );
        }
    );
  }

  void _processNextRound({required Team winningTeam}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedMatch = _match.processNextRound(winningTeam: winningTeam);

      await StorageService.saveMatch(updatedMatch);

      setState(() {
        _match = updatedMatch;
      });
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar próxima: ${e.toString()}'),
            backgroundColor: Colors.red,
          )
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


