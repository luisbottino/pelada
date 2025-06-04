import 'package:flutter/material.dart';
import 'package:pelada/features/match/presentation/components/app_logo_bar.dart';
import '../../../../core/models/match.dart';
import '../../../../core/models/team.dart';
import '../../../../core/services/storage_service.dart';
import 'match_players_screen.dart';

class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({super.key});

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  TeamFormat _selectedFormat = TeamFormat.fourVsFour;
  bool _separateSetters = false;
  bool _randomSelection = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getFormatLabel(TeamFormat format) {
    switch (format) {
      case TeamFormat.twoVsTwo:
        return '2x2';
      case TeamFormat.threeVsThree:
        return '3x3';
      case TeamFormat.fourVsFour:
        return '4x4';
      case TeamFormat.sixVsSix:
        return '6x6';
    }
  }

  Future<void> _createMatch() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final match = Match(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          format: _selectedFormat,
          separateSetters: _separateSetters,
          teamSelectionMode: _randomSelection ? TeamSelectionMode.random : TeamSelectionMode.sequential,
        );

        await StorageService.saveMatch(match);
        
        if (mounted) {
          final updatedMatch = await Navigator.push<Match>(
            context,
            MaterialPageRoute(
              builder: (context) => MatchPlayersScreen(match: match),
            ),
          );

          if (updatedMatch != null) {
            Navigator.pop(context, updatedMatch);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar pelada: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppLogoBar(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _createMatch,
              icon: const Icon(Icons.add, size: 28, color: Colors.white),
              label: const Text('Criar Pelada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                elevation: 6,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            )
          )
        )
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Pelada',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome da pelada';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Formato do Jogo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TeamFormat>(
                        value: _selectedFormat,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: TeamFormat.values.map((format) {
                          return DropdownMenuItem(
                            value: format,
                            child: Text(_getFormatLabel(format)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedFormat = value;
                            if (value == TeamFormat.twoVsTwo) {
                              _separateSetters = false;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configurações',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Seleção Aleatória'),
                        subtitle: const Text(
                          'Se ativado, os times serão formados aleatoriamente. '
                          'Caso contrário, serão formados por ordem de chegada.',
                        ),
                        value: _randomSelection,
                        onChanged: (value) {
                          setState(() {
                            _randomSelection = value;
                          });
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Separar Levantadores'),
                        subtitle: Text(
                          _selectedFormat == TeamFormat.twoVsTwo
                              ? 'Não disponível para formato 2x2'
                              : 'Se ativado, os levantadores terão uma fila separada e '
                                  'rotacionarão entre os times.',
                        ),
                        value: _separateSetters,
                        onChanged: _selectedFormat == TeamFormat.twoVsTwo
                            ? null
                            : (value) {
                                setState(() {
                                  _separateSetters = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ),
              // const SizedBox(height: 24),
              // ElevatedButton(
              //   onPressed: _isLoading ? null : _createMatch,
              //   style: ElevatedButton.styleFrom(
              //     foregroundColor: Colors.white,
              //     padding: const EdgeInsets.symmetric(vertical: 16),
              //   ),
              //   child: _isLoading
              //       ? const SizedBox(
              //           height: 20,
              //           width: 20,
              //           child: CircularProgressIndicator(
              //             strokeWidth: 2,
              //           ),
              //         )
              //       : const Text('Criar Pelada'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
} 