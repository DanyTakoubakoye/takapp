import 'package:flutter/material.dart';

import 'package:takapp/modeles/room_model.dart';
import 'package:takapp/services/room_service.dart';

import 'package:takapp/modeles/reservation_model.dart';
import 'package:takapp/services/reservation_service.dart';
import 'package:takapp/vues/gerante/facturation_chambre_page.dart';



class RoomsBoardPage extends StatefulWidget {
  final String establishmentId;

  const RoomsBoardPage({super.key, required this.establishmentId});

  @override
  State<RoomsBoardPage> createState() => _RoomsBoardPageState();
}

class _RoomsBoardPageState extends State<RoomsBoardPage> {
  final RoomService _roomService = RoomService();
  final ReservationService _reservationService = ReservationService();

  // Créé une seule fois : recréé dans build(), il relancerait l'abonnement à
  // chaque rebuild et remettrait l'écran en chargement.
  late final Stream<List<RoomModel>> _roomsStream;

  String get establishmentId => widget.establishmentId.trim();

  @override
  void initState() {
    super.initState();
    _roomsStream = _roomService.streamRooms(establishmentId: establishmentId);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Libre';
      case 'occupied':
        return 'Occupée';
      case 'cleaning':
        return 'À nettoyer';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'cleaning':
        return Colors.orange;
      case 'maintenance':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle;
      case 'occupied':
        return Icons.person;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.meeting_room;
    }
  }

  Future<void> _changeStatus(RoomModel room) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Chambre ${room.number} — changer l\'état',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              for (final s in const [
                'available',
                'occupied',
                'cleaning',
                'maintenance',
              ])
                ListTile(
                  leading: Icon(_statusIcon(s), color: _statusColor(s)),
                  title: Text(_statusLabel(s)),
                  trailing: room.status == s
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(s),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == room.status) return;

    try {
      await _roomService.updateRoomStatus(
        establishmentId: establishmentId,
        roomId: room.id,
        status: selected,
      );
      _showMessage('Chambre ${room.number} : ${_statusLabel(selected)}');
    } catch (e) {
      _showMessage('Erreur : $e');
    }
  }

  Future<void> _onRoomTap(RoomModel room) async {
    // Chambre occupée → proposer le check-out en priorité
    if (room.status == 'occupied') {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (sheetContext) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Chambre ${room.number} (occupée)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Check-out (départ du client)'),
                  onTap: () => Navigator.pop(sheetContext, 'checkout'),
                ),
                ListTile(
                  leading: const Icon(Icons.tune, color: Colors.blueGrey),
                  title: const Text('Changer l\'état manuellement'),
                  onTap: () => Navigator.pop(sheetContext, 'status'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );

      if (action == 'checkout') {
        await _doCheckOutFromBoard(room);
      } else if (action == 'status') {
        await _changeStatus(room);
      }
      return;
    }

    // Autres états → menu de changement d'état classique
    await _changeStatus(room);
  }

  Future<void> _doCheckOutFromBoard(RoomModel room) async {
    // Retrouver la réservation active de cette chambre
    ReservationModel? resa;
    try {
      resa = await _reservationService.activeReservationForRoom(
        establishmentId: establishmentId,
        roomId: room.id,
      );
    } catch (e) {
      _showMessage('Erreur : $e');
      return;
    }

    if (resa == null) {
      // Pas de réservation liée : proposer juste de libérer la chambre
      _showMessage(
        'Aucune réservation active trouvée pour cette chambre. '
        'Vous pouvez changer son état manuellement.',
      );
      return;
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check-out'),
        content: Text(
          'Confirmer le départ de ${resa!.clientName} '
          '(chambre ${room.number}) ?\n\n'
          'La chambre passera "à nettoyer".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmer le départ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _reservationService.checkOut(
        establishmentId: establishmentId,
        reservationId: resa.id,
      );
      if (!mounted) return;
      _showMessage('Check-out effectué.');
      _proposeFacturation(resa);
    } catch (e) {
      _showMessage('Erreur : $e');
    }
  }

  Future<void> _proposeFacturation(ReservationModel resa) async {
    final goToBilling = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Facturer le séjour ?'),
        content: Text(
          'Voulez-vous établir la facture de ${resa.clientName} maintenant ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Facturer'),
          ),
        ],
      ),
    );

    if (goToBilling == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FacturationChambrePage(
            establishmentId: establishmentId,
            reservation: resa,
          ),
        ),
      );
    }
  }

  Widget _buildLegend() {
    Widget dot(String status) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _statusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(_statusLabel(status), style: const TextStyle(fontSize: 12)),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        dot('available'),
        dot('occupied'),
        dot('cleaning'),
        dot('maintenance'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 500
        ? 2
        : width < 900
        ? 3
        : width < 1300
        ? 4
        : 6;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan des chambres')),
      body: StreamBuilder<List<RoomModel>>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: SelectableText('Erreur : ${snapshot.error}'));
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune chambre.\nAjoutez vos chambres pour voir le plan.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Compteurs par état
          final counts = <String, int>{};
          for (final r in rooms) {
            counts[r.status] = (counts[r.status] ?? 0) + 1;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rooms.length} chambres · '
                      '${counts['available'] ?? 0} libres · '
                      '${counts['occupied'] ?? 0} occupées · '
                      '${counts['cleaning'] ?? 0} à nettoyer',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildLegend(),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final color = _statusColor(room.status);

                    return InkWell(
                      onTap: () => _onRoomTap(room),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color, width: 2),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _statusIcon(room.status),
                              color: color,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              room.number,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              room.roomTypeName,
                              style: const TextStyle(fontSize: 11),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _statusLabel(room.status),
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
