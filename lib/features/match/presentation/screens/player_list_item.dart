import 'package:flutter/material.dart';
import 'package:pelada/core/models/team_display.dart';

import '../../../../core/models/player.dart';

class PlayerListItem extends StatelessWidget {
  final Player player;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSetter;
  final TeamDisplay teamDisplay;

  const PlayerListItem({
    required Key key,
    required this.player,
    required this.onEdit,
    required this.onDelete,
    required this.isSetter,
    required this.teamDisplay
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: key,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
        color: teamDisplay.backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                player.name,
                style: TextStyle(
                  fontSize: 14,
                  overflow: TextOverflow.ellipsis
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                teamDisplay.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.red)),
                    ]
                  ),
                )
              ]
            ),
          ],
        ),
      ),
    );
  }
}