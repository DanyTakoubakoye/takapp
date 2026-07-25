import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/controllers/room_consumption_controller.dart';

class FactureConsommationChambrePage extends StatefulWidget {
  const FactureConsommationChambrePage({super.key});

  @override
  State<FactureConsommationChambrePage> createState() =>
      _FactureConsommationChambrePageState();
}

class _FactureConsommationChambrePageState
    extends State<FactureConsommationChambrePage> {
  final TextEditingController roomController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  @override
  void dispose() {
    roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RoomConsumptionController>();

    final auth = context.watch<AuthController>();

    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur introuvable.')),
      );
    }

    final establishmentId = user.establishmentId.trim();

    if (establishmentId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Établissement introuvable.')),
      );
    }

    final isSmall = _isSmallScreen(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Facture Consommation Chambre")),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: Column(
            children: [
              _filters(context, establishmentId, isSmall),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (controller.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.errorMessage != null) {
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            controller.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }

                    if (controller.invoice == null) {
                      return const SizedBox.shrink();
                    }

                    if (controller.invoice!.lines.isEmpty) {
                      return const Center(
                        child: Text(
                          "Aucune consommation trouvée pour cette période.",
                        ),
                      );
                    }

                    return _table(controller, isSmall);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filters(BuildContext context, String establishmentId, bool isSmall) {
    final controller = context.read<RoomConsumptionController>();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 14),
        child: Column(
          children: [
            TextField(
              controller: roomController,
              decoration: const InputDecoration(labelText: "Numéro chambre"),
            ),
            const SizedBox(height: 10),
            if (isSmall) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text(
                    startDate == null
                        ? "Date début"
                        : "${startDate!.day.toString().padLeft(2, '0')}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.year}",
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (d != null) {
                      setState(() => startDate = d);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text(
                    endDate == null
                        ? "Date fin"
                        : "${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}",
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (d != null) {
                      setState(() => endDate = d);
                    }
                  },
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      child: Text(
                        startDate == null
                            ? "Date début"
                            : "${startDate!.day.toString().padLeft(2, '0')}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.year}",
                      ),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (d != null) {
                          setState(() => startDate = d);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      child: Text(
                        endDate == null
                            ? "Date fin"
                            : "${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}",
                      ),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );

                        if (d != null) {
                          setState(() => endDate = d);
                        }
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Afficher"),
                onPressed: () {
                  if (roomController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Veuillez saisir le numéro de chambre."),
                      ),
                    );

                    return;
                  }

                  if (startDate == null || endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Veuillez choisir les dates de début et de fin.",
                        ),
                      ),
                    );

                    return;
                  }

                  if (startDate!.isAfter(endDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "La date de début doit être antérieure ou égale à la date de fin.",
                        ),
                      ),
                    );

                    return;
                  }

                  controller.loadConsumption(
                    establishmentId: establishmentId,
                    roomNumber: roomController.text.trim(),
                    start: startDate!,
                    end: endDate!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(RoomConsumptionController controller, bool isSmall) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total : ${invoice.total.toStringAsFixed(0)} FCFA",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: invoice.lines.length,
            itemBuilder: (context, index) {
              final line = invoice.lines[index];

              return Card(
                child: ListTile(
                  contentPadding: EdgeInsets.all(isSmall ? 10 : 14),
                  title: Text(
                    line.itemName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "${line.quantity} x ${line.unitPrice.toStringAsFixed(0)} - ${line.source}\n"
                      "${line.createdAt.day.toString().padLeft(2, '0')}/"
                      "${line.createdAt.month.toString().padLeft(2, '0')}/"
                      "${line.createdAt.year} à "
                      "${line.createdAt.hour.toString().padLeft(2, '0')}:"
                      "${line.createdAt.minute.toString().padLeft(2, '0')}",
                    ),
                  ),
                  trailing: Text(
                    line.total.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
