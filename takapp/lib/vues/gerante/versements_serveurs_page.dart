import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:takapp/controllers/auth_controller.dart';
import 'package:takapp/core/constants/app_payment_methods.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/payment_model.dart';
import 'package:takapp/modeles/server_handover_model.dart';
import 'package:takapp/services/gerante_handover_service.dart';
import 'package:takapp/services/pdf_service.dart';
import 'package:takapp/services/printer_service.dart';

class VersementsServeursPage extends StatelessWidget {
  final String establishmentId;

  const VersementsServeursPage({super.key, required this.establishmentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final safeEstablishmentId = establishmentId.trim();

    if (safeEstablishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    final service = GeranteHandoverService();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.serverHandoversTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<ServerHandoverModel>>(
          stream: service.streamPendingHandovers(
            establishmentId: safeEstablishmentId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(l10n.errorPrefixed('${snapshot.error}')),
              );
            }

            final handovers = snapshot.data ?? [];

            if (handovers.isEmpty) {
              return Center(child: Text(l10n.noPendingHandover));
            }

            return ListView.separated(
              itemCount: handovers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final handover = handovers[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          handover.serveurName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.declaredAmountLine(
                            handover.declaredAmount.toStringAsFixed(0),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.includedPaymentsLine(handover.paymentIds.length),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GeranteHandoverDetailPage(
                                    establishmentId: safeEstablishmentId,
                                    handover: handover,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined),
                            label: Text(l10n.actionOpen),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class GeranteHandoverDetailPage extends StatefulWidget {
  final String establishmentId;
  final ServerHandoverModel handover;

  const GeranteHandoverDetailPage({
    super.key,
    required this.establishmentId,
    required this.handover,
  });

  @override
  State<GeranteHandoverDetailPage> createState() =>
      _GeranteHandoverDetailPageState();
}

class _GeranteHandoverDetailPageState extends State<GeranteHandoverDetailPage> {
  late final TextEditingController validatedAmountController;

  final Set<String> selectedPaymentIds = {};
  final GeranteHandoverService geranteService = GeranteHandoverService();

  String get establishmentId => widget.establishmentId.trim();

  @override
  void initState() {
    super.initState();

    validatedAmountController = TextEditingController(
      text: widget.handover.declaredAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    validatedAmountController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      _showSnack(l10n.errUserNotFound);
      return;
    }

    if (establishmentId.isEmpty) {
      _showSnack(l10n.errEstablishmentNotFound);
      return;
    }

    final amount = double.tryParse(validatedAmountController.text.trim());

    if (amount == null) {
      _showSnack(l10n.errObservedAmountInvalid);
      return;
    }

    await geranteService.validateSelectedPayments(
      establishmentId: establishmentId,
      handoverId: widget.handover.id,
      selectedPaymentIds: selectedPaymentIds.toList(),
      validatedAmount: amount,
      managerId: user.uid,
      managerName: user.name,
    );

    if (!mounted) return;

    Navigator.pop(context);
    _showSnack(l10n.ordersValidated);
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      _showSnack(l10n.errUserNotFound);
      return;
    }

    if (establishmentId.isEmpty) {
      _showSnack(l10n.errEstablishmentNotFound);
      return;
    }

    final amount = double.tryParse(validatedAmountController.text.trim());

    if (amount == null) {
      _showSnack(l10n.errObservedAmountInvalid);
      return;
    }

    await geranteService.rejectSelectedPayments(
      establishmentId: establishmentId,
      handoverId: widget.handover.id,
      selectedPaymentIds: selectedPaymentIds.toList(),
      validatedAmount: amount,
      managerId: user.uid,
      managerName: user.name,
    );

    if (!mounted) return;

    Navigator.pop(context);
    _showSnack(l10n.ordersRejected);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pdfService = context.read<PdfService>();
    final printerService = context.read<PrinterService>();

    if (establishmentId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.errEstablishmentNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.handoverTitleFor(widget.handover.serveurName)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.declaredAmountLine(
                            widget.handover.declaredAmount.toStringAsFixed(0),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: validatedAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.labelObservedAmount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FutureBuilder<List<PaymentModel>>(
                      future: geranteService.getPaymentsForHandover(
                        establishmentId: establishmentId,
                        paymentIds: widget.handover.paymentIds,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              l10n.errorPrefixed('${snapshot.error}'),
                            ),
                          );
                        }

                        final payments = snapshot.data ?? [];

                        if (payments.isEmpty) {
                          return Center(child: Text(l10n.noPaymentFound));
                        }

                        return ListView.separated(
                          itemCount: payments.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final payment = payments[index];

                            final alreadyValidated = widget
                                .handover
                                .validatedPaymentIds
                                .contains(payment.id);

                            final alreadyRejected = widget
                                .handover
                                .rejectedPaymentIds
                                .contains(payment.id);

                            return CheckboxListTile(
                              value: selectedPaymentIds.contains(payment.id),
                              onChanged: (alreadyValidated || alreadyRejected)
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedPaymentIds.add(payment.id);
                                        } else {
                                          selectedPaymentIds.remove(payment.id);
                                        }
                                      });
                                    },
                              title: Text(payment.orderNumber),
                              // `method` est un code technique : on le rend
                              // via le libellé localisé partagé.
                              subtitle: Text(
                                l10n.methodAmountLine(
                                      AppPaymentMethods.label(
                                        l10n,
                                        payment.method,
                                      ),
                                      payment.amount.toStringAsFixed(0),
                                    ) +
                                    (alreadyValidated
                                        ? l10n.suffixAlreadyValidated
                                        : '') +
                                    (alreadyRejected
                                        ? l10n.suffixRejected
                                        : ''),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: selectedPaymentIds.isEmpty ? null : _reject,
                      child: Text(l10n.actionRejectSelection),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedPaymentIds.isEmpty ? null : _validate,
                      child: Text(l10n.actionValidateSelection),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final payments = await geranteService
                            .getPaymentsForHandover(
                              establishmentId: establishmentId,
                              paymentIds: widget.handover.paymentIds,
                            );

                        final bytes = await pdfService
                            .buildManagerValidationPdf(
                              l10n: l10n,
                              handover: widget.handover,
                              payments: payments,
                            );

                        await printerService.printPdf(
                          Uint8List.fromList(bytes),
                        );
                      },
                      icon: const Icon(Icons.print_outlined),
                      label: Text(l10n.actionPrint),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
