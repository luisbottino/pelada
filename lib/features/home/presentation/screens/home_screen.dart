import 'package:flutter/material.dart';
import 'package:pelada/core/models/match.dart';
import 'package:pelada/core/services/storage_service.dart';

import '../../../../core/models/team.dart';
import '../../../match/presentation/screens/match_teams_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Match>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = StorageService.getAllMatches(); // Ajuste para seu método de busca
  }

  Future<void> _refreshMatches() async {
    setState(() {
      _matchesFuture = StorageService.getAllMatches();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/new-match');
              },
              icon: const Icon(Icons.sports_volleyball, size: 28, color: Colors.white),
              label: const Text('Nova Pelada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/logo-removebg-preview.png',
              height: 240,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder(
                  future: _matchesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }
                    final matches = snapshot.data ?? [];

                    return ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(match.name),
                              subtitle: Text(_getFormatLabel(match.format)),
                              trailing: const Icon(Icons.arrow_forward, size: 18),
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => MatchTeamsScreen(match: match)
                                    )
                                );
                              },
                            )
                          );
                        }
                    );
                  }
              ),
            ),
          ],
        ),
      ),
    );
  }
} 