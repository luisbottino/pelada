import 'package:flutter/material.dart';
import '../../../../core/models/match.dart';
import '../../../../core/models/team.dart';

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
  TeamSelectionMode _selectionMode = TeamSelectionMode.random;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createMatch() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implementar a criação da pelada
      final match = Match(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        format: _selectedFormat,
        separateSetters: _separateSetters,
        teamSelectionMode: _selectionMode,
      );

      // TODO: Salvar a pelada e navegar para a próxima tela
      Navigator.pop(context, match);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Pelada'),
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
                    return 'Por favor, insira um nome para a pelada';
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
                          if (value != null) {
                            setState(() {
                              _selectedFormat = value;
                            });
                          }
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
                        title: const Text('Separar Levantadores'),
                        subtitle: const Text(
                          'Criar uma fila separada para levantadores',
                        ),
                        value: _separateSetters,
                        onChanged: (value) {
                          setState(() {
                            _separateSetters = value;
                          });
                        },
                      ),
                      const Divider(),
                      const Text(
                        'Modo de Seleção dos Times',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RadioListTile<TeamSelectionMode>(
                        title: const Text('Aleatório'),
                        subtitle: const Text('Sortear os times'),
                        value: TeamSelectionMode.random,
                        groupValue: _selectionMode,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectionMode = value;
                            });
                          }
                        },
                      ),
                      RadioListTile<TeamSelectionMode>(
                        title: const Text('Sequencial'),
                        subtitle: const Text('Times por ordem de chegada'),
                        value: TeamSelectionMode.sequential,
                        groupValue: _selectionMode,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectionMode = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createMatch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Informar Jogadores'),
              ),
            ],
          ),
        ),
      ),
    );
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
} 