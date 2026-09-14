import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/hygiene_daily_controller.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/room_model.dart';
import 'package:takapp/modeles/store_stock_model.dart';
import 'package:takapp/services/room_service.dart';
import 'package:takapp/services/store_stock_service.dart';

class HygieneDailyPage extends StatefulWidget {
  final String establishmentId;

  const HygieneDailyPage({super.key, required this.establishmentId});

  @override
  State<HygieneDailyPage> createState() => _HygieneDailyPageState();
}

class _HygieneDailyPageState extends State<HygieneDailyPage> {
  final RoomService _roomService = RoomService();

  // Le stream est créé une seule fois : le recréer dans build() relancerait
  // l'abonnement à chaque rebuild et remettrait le StreamBuilder en attente.
  late final Stream<List<RoomModel>> _roomsStream;

  String get establishmentId => widget.establishmentId.trim();

  @override
  void initState() {
    super.initState();
    _roomsStream = _roomService.streamRooms(establishmentId: establishmentId);
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'available':
        return l10n.roomStatusAvailable;
      case 'occupied':
        return l10n.roomStatusOccupied;
      case 'cleaning':
        return l10n.roomStatusCleaning;
      case 'maintenance':
        return l10n.roomStatusMaintenance;
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

  /// Ouvre le formulaire de ménage pré-rempli pour la chambre choisie.
  Future<void> _openCleaningForm({String initialRoomNumber = ''}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _CleaningFormSheet(
          establishmentId: establishmentId,
          initialRoomNumber: initialRoomNumber,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 500
        ? 2
        : width < 900
        ? 3
        : width < 1300
        ? 4
        : 6;

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hygieneRoomsToPrepareTitle),
        actions: [
          IconButton(
            tooltip: l10n.manualEntry,
            onPressed: () => _openCleaningForm(),
            icon: const Icon(Icons.edit_note),
          ),
          IconButton(
            onPressed: () => context.read<AuthController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<RoomModel>>(
        stream: _roomsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: SelectableText(l10n.commonError('${snapshot.error}')),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noRoomSimple, textAlign: TextAlign.center),
              ),
            );
          }

          // Chambres "à nettoyer" en premier
          final sorted = [...rooms];
          sorted.sort((a, b) {
            int rank(String s) => s == 'cleaning' ? 0 : 1;
            final r = rank(a.status).compareTo(rank(b.status));
            if (r != 0) return r;
            final an = int.tryParse(a.number);
            final bn = int.tryParse(b.number);
            if (an != null && bn != null) return an.compareTo(bn);
            return a.number.compareTo(b.number);
          });

          final cleaningCount = rooms
              .where((r) => r.status == 'cleaning')
              .length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  cleaningCount > 0
                      ? l10n.roomsToCleanHint(cleaningCount)
                      : l10n.noRoomToCleanHint,
                  style: const TextStyle(fontStyle: FontStyle.italic),
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
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final room = sorted[index];
                    final color = _statusColor(room.status);

                    return InkWell(
                      onTap: () =>
                          _openCleaningForm(initialRoomNumber: room.number),
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
                              _statusLabel(room.status, l10n),
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

/// =========================
/// FORMULAIRE DE MÉNAGE (bottom sheet)
/// =========================
class _CleaningFormSheet extends StatefulWidget {
  final String establishmentId;
  final String initialRoomNumber;

  const _CleaningFormSheet({
    required this.establishmentId,
    required this.initialRoomNumber,
  });

  @override
  State<_CleaningFormSheet> createState() => _CleaningFormSheetState();
}

class _CleaningFormSheetState extends State<_CleaningFormSheet> {
  final StoreStockService _stockService = StoreStockService();

  late final TextEditingController _roomController;
  final TextEditingController _noteController = TextEditingController();
  final List<_HygieneLineInput> _lines = [_HygieneLineInput()];

  // build() dépend de MediaQuery.viewInsets : sans ce cache, l'ouverture du
  // clavier recréerait le stream, détruirait les champs et refermerait
  // aussitôt le clavier.
  late final Stream<List<StoreStockModel>> _stocksStream;

  String get establishmentId => widget.establishmentId.trim();

  @override
  void initState() {
    super.initState();
    _roomController = TextEditingController(text: widget.initialRoomNumber);
    _stocksStream = _stockService.streamStocksForStore(
      establishmentId: establishmentId,
      store: 'hotel',
    );
  }

  @override
  void dispose() {
    _roomController.dispose();
    _noteController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(List<StoreStockModel> stocks) async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final controller = context.read<HygieneDailyController>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errUserNotFound)));
      return;
    }

    final room = _roomController.text.trim();
    if (room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errRoomNumberRequired)),
      );
      return;
    }

    final List<Map<String, dynamic>> usedItems = [];

    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final quantity = double.tryParse(line.quantityController.text.trim());

      if ((line.selectedStockId == null || line.selectedStockId!.isEmpty) &&
          line.quantityController.text.trim().isEmpty) {
        continue;
      }

      if (line.selectedStockId == null || line.selectedStockId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errSelectProductAtLine(i + 1)),
          ),
        );
        return;
      }

      final selectedMatches = stocks
          .where((e) => e.itemId == line.selectedStockId)
          .toList();

      if (selectedMatches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errProductNotFoundAtLine(i + 1))),
        );
        return;
      }

      final selected = selectedMatches.first;

      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidQuantityAtLine(i + 1))),
        );
        return;
      }

      usedItems.add({
        'itemId': selected.itemId,
        'itemName': selected.itemName,
        'unit': selected.unit,
        'quantityUsed': quantity,
      });
    }

    if (usedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errAddAtLeastOneProductUsed)),
      );
      return;
    }

    final success = await controller.createDailyEntry(
      establishmentId: establishmentId,
      roomNumber: room,
      preparedBy: user.uid,
      preparedByName: user.name,
      note: _noteController.text.trim(),
      usedItems: usedItems,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cleaningRecordedForRoom(room))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorText(l10n) ?? l10n.errUnknown),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<HygieneDailyController>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: StreamBuilder<List<StoreStockModel>>(
          stream: _stocksStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText('Erreur : ${snapshot.error}'),
              );
            }

            final stocks = snapshot.data ?? [];

            for (final line in _lines) {
              final exists = stocks.any(
                (e) => e.itemId == line.selectedStockId,
              );
              if (!exists) {
                line.selectedStockId = null;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    l10n.declareCleaningTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _roomController,
                    decoration: InputDecoration(
                      labelText: l10n.labelPreparedRoomNumber,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.labelNote,
                      hintText: l10n.hintCleaningNotes,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (stocks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '${l10n.noProductInHotelStock} '
                        '${l10n.canSaveWithoutItem}',
                      ),
                    )
                  else
                    ...List.generate(_lines.length, (index) {
                      final line = _lines[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.labelProductIndex(index + 1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (_lines.length > 1)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          line.dispose();
                                          _lines.removeAt(index);
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: line.selectedStockId,
                                decoration: InputDecoration(
                                  labelText: l10n.labelProductUsed,
                                ),
                                items: stocks.map((item) {
                                  final label =
                                      '${item.itemName} (${item.unit}) - stock: ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)}';
                                  return DropdownMenuItem<String>(
                                    value: item.itemId,
                                    child: Text(label),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    line.selectedStockId = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: line.quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: l10n.labelQuantityUsed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  if (stocks.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _lines.add(_HygieneLineInput());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.actionAddProduct),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: controller.isSubmitting
                        ? null
                        : () => _submit(stocks),
                    icon: controller.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(l10n.actionSaveCleaning),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HygieneLineInput {
  String? selectedStockId;
  final TextEditingController quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}
