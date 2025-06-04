import 'package:flutter/material.dart';
import 'package:pelada/core/extensions/match_helpers.dart';
import 'package:pelada/core/models/team_display.dart';

import '../components/app_logo_bar.dart';
import 'player_list_item.dart';

import '../../../../core/models/player.dart';
import '../../../../core/models/match.dart';

class PlayersManagementScreen extends StatefulWidget {
  final Match match;

  const PlayersManagementScreen({
    required this.match,
  });

  @override
  _PlayersManagementScreenState createState() => _PlayersManagementScreenState();
}

class _PlayersManagementScreenState extends State<PlayersManagementScreen> {
  late List<Player> _players;
  late List<Player> _setters;
  final _formKeyAddPlayer = GlobalKey<FormState>();
  final _formKeyReorder = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _newPlayerIsSetter = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _players = List.from(widget.match.players);
    _setters = List.from(widget.match.setters);
  }

  Match _getUpdatedMatch() {
   var updatedMatch = widget.match.copyWith(
      players: _players,
      setters: _setters,
      updatedAt: DateTime.now(),
    );
    return updatedMatch.generateTeams();
  }

  bool _isNameUnique(String name, {String? currentId}) {
    final lowerName = name.toLowerCase();
    return !_players.any((p) =>
    p.name.toLowerCase() == lowerName && p.id != currentId) &&
        !_setters.any((p) =>
        p.name.toLowerCase() == lowerName && p.id != currentId);
  }

  void _handleBack() {
    if (_formKeyReorder.currentState?.validate() ?? false) {
      Navigator.pop(context, _getUpdatedMatch());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _handleBack();
        }
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoBar(),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
        ),
        body: _buildBodyWithForm(),
      ),
    );
  }

  Widget _buildBodyWithForm() {
    return Column(
      children: [
        Expanded(
          child: _buildBody(), // Mantém a lista de jogadores
        ),
        _buildAddPlayerForm(),
      ],
    );
  }

  Widget _buildAddPlayerForm() {
    return  Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyAddPlayer,
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
                value: _newPlayerIsSetter,
                onChanged: (value) {
                  setState(() {
                    _newPlayerIsSetter = value ?? false;
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
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addPlayer() {
    if (_formKeyAddPlayer.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final name = _nameController.text.trim();

      try {
        final player = Player(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          isSetter: _newPlayerIsSetter,
        );

        if (_players.any((p) => p.name.toLowerCase() == player.name.toLowerCase())
            || _setters.any((p) => p.name.toLowerCase() == player.name.toLowerCase())) {
          throw Exception('Já existe um jogador com este nome');
        }
        setState(() {
          if (_newPlayerIsSetter) {
            _setters.add(player);
          } else {
            _players.add(player);
          }
        });

        _nameController.clear();
        _newPlayerIsSetter = false;
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

  Widget _buildBody() {
    return Form(
      key: _formKeyReorder,
      child: widget.match.separateSetters ? Row(
        children: [
          Expanded(
            child: _buildPlayerListColumn(
              title: 'Jogadores',
              players: _players,
              onReorder: (oldIndex, newIndex) =>
                  _handleReorder(false, oldIndex, newIndex),
              isSetterList: false,
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: _buildPlayerListColumn(
              title: 'Levantadores',
              players: _setters,
              onReorder: (oldIndex, newIndex) =>
                  _handleReorder(true, oldIndex, newIndex),
              isSetterList: true,
            ),
          ),
        ],
      )
      : _buildPlayerListColumn(
        title: 'Jogadores',
        players: _players,
        onReorder: (oldIndex, newIndex) =>
            _handleReorder(false, oldIndex, newIndex),
        isSetterList: false,
      ),
    );
  }

  Widget _buildPlayerListColumn({
    required String title,
    required List<Player> players,
    required Function(int, int) onReorder,
    required bool isSetterList,
  }) {
    final playersPerTeam = widget.match.separateSetters ? widget.match.playersPerTeam - 1 : widget.match.playersPerTeam;
    final setterPerTeam = 1;
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
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shrinkWrap: true,
            itemCount: players.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final player = players[index];

              TeamDisplay teamDisplay;
              if (isSetterList) {
                if (index < setterPerTeam) {
                  teamDisplay = TeamDisplay(label: 'Time A', backgroundColor: Colors.green.shade100);
                } else if (index < setterPerTeam * 2) {
                  teamDisplay = TeamDisplay(label: 'Time B', backgroundColor: Colors.blue.shade100);
                } else if (index < setterPerTeam * 3) {
                  teamDisplay = TeamDisplay(label: 'Próx', backgroundColor: Colors.yellow.shade100);
                } else {
                  teamDisplay = TeamDisplay(label: 'Fila', backgroundColor: Colors.grey.shade200);
                }
              } else {
                if (index < playersPerTeam) {
                  teamDisplay = TeamDisplay(label: 'Time A', backgroundColor: Colors.green.shade100);
                } else if (index < playersPerTeam * 2) {
                  teamDisplay = TeamDisplay(label: 'Time B', backgroundColor: Colors.blue.shade100);
                } else if (index < playersPerTeam * 3) {
                  teamDisplay = TeamDisplay(label: 'Próx', backgroundColor: Colors.yellow.shade100);
                } else {
                  teamDisplay = TeamDisplay(label: 'Fila', backgroundColor: Colors.grey.shade200);
                }
              }


              return PlayerListItem(
                key: ValueKey(player.id),
                player: player,
                onEdit: () => _showEditDialog(player, isSetterList),
                isSetter: isSetterList,
                teamDisplay: teamDisplay,
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleReorder(bool isSetterList, int oldIndex, int newIndex) {
    setState(() {
      final list = isSetterList ? _setters : _players;
      if (oldIndex < newIndex) newIndex--;
      final player = list.removeAt(oldIndex);
      list.insert(newIndex, player);
    });
  }

  void _showEditDialog(Player player, bool isCurrentlySetter) {
    final textController = TextEditingController(text: player.name);
    bool isSetter = isCurrentlySetter;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Jogador'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      if (value != player.name &&
                          !_isNameUnique(value, currentId: player.id)) {
                        return 'Nome já existe';
                      }
                      return null;
                    },
                  ),
                  if (widget.match.separateSetters)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: CheckboxListTile(
                        title: const Text('Levantador'),
                        contentPadding: EdgeInsets.zero,
                        value: isSetter,
                        onChanged: (value) =>
                            setState(() => isSetter = value!),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Excluir',
                      style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    _handleDeletePlayer(player, isCurrentlySetter);
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: const Text('Salvar'),
                  onPressed: () {
                    if (_formKeyReorder.currentState!.validate()) {
                      _handleSavePlayer(
                        player,
                        textController.text.trim(),
                        isSetter,
                        isCurrentlySetter,
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleSavePlayer(
      Player originalPlayer,
      String newName,
      bool newIsSetter,
      bool wasSetter,
      ) {
    setState(() {
      final updatedPlayer = originalPlayer.copyWith(name: newName, isSetter: newIsSetter);

      if (widget.match.separateSetters) {
        if (wasSetter && !newIsSetter) {
          if (_setters.length <= widget.match.getMinimumNumberOfSetters()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Não foi possível editar o jogador. O mínimo de levantadores é ${widget.match.getMinimumNumberOfSetters()}'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            _setters.remove(originalPlayer);
            _players.add(updatedPlayer);
          }
        } else if (!wasSetter && newIsSetter) {
          if (_players.length <= (widget.match.getMinimunNumberOfPlayers() - 2)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Não foi possível editar o jogador. O mínimo de jogadores é ${widget.match.getMinimunNumberOfPlayers()} para o formato de times selecionado'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            _players.remove(originalPlayer);
            _setters.add(updatedPlayer);
          }
        } else {
          final list = wasSetter ? _setters : _players;
          final index = list.indexOf(originalPlayer);
          list[index] = updatedPlayer;
        }
      } else {
        final index = _players.indexOf(originalPlayer);
        _players[index] = updatedPlayer;
      }
    });
  }

  void _handleDeletePlayer(Player player, bool isSetter) {
    setState(() {
      if (isSetter) {
        if (_setters.length <= widget.match.getMinimumNumberOfSetters()) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não foi possível excluir o levantador. O mínimo de levantadores é ${widget.match.getMinimumNumberOfSetters()}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          _setters.remove(player);
        }
      } else {
        if ((!widget.match.separateSetters && _players.length <= (widget.match.getMinimunNumberOfPlayers()))
        || (widget.match.separateSetters && _players.length <= (widget.match.getMinimunNumberOfPlayers() - 2))
        ) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Não foi possível excluir o jogador. O mínimo de jogadores é ${widget.match.getMinimunNumberOfPlayers()} para o formato de times selecionado'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          _players.remove(player);
        }
      }
    });
  }
}