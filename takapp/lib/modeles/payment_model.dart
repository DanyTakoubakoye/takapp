import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;

  /// SaaS
  final String establishmentId;

  /// Référence commande
  final String orderId;
  final String orderNumber;

  /// restaurant | hotel | bar
  final String clientType;

  /// room | restaurant | bar
  final String type;

  /// Encaissement
  final String receivedBy;
  final String receivedByName;

  /// cash | mobile_money | card | transfer
  final String method;

  final double amount;

  /// pending | paid | cancelled | refunded
  final String status;

  /// Gestion versements
  final String handoverStatus;
  final String? handoverId;

  /// Fiscalisation
  final bool isFiscalized;
  final String fiscalUid;

  /// Offline sync
  final bool pendingSync;
  final bool syncError;

  final DateTime? createdAt;

  const PaymentModel({
    required this.id,
    required this.establishmentId,

    required this.orderId,
    required this.orderNumber,

    required this.clientType,
    required this.type,

    required this.receivedBy,
    required this.receivedByName,

    required this.method,
    required this.amount,

    required this.status,

    required this.handoverStatus,
    required this.handoverId,

    required this.isFiscalized,
    required this.fiscalUid,

    required this.pendingSync,
    required this.syncError,

    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    double toDouble(dynamic value) {
      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    final ts = map['createdAt'];

    return PaymentModel(
      id: documentId,

      /// SaaS
      establishmentId: (map['establishmentId'] ?? '').toString(),

      /// Référence commande
      orderId: (map['orderId'] ?? '').toString(),

      orderNumber: (map['orderNumber'] ?? '').toString(),

      /// Type client
      clientType: (map['clientType'] ?? '').toString(),

      /// Type paiement
      type: (map['type'] ?? '').toString(),

      /// Encaissement
      receivedBy: (map['receivedBy'] ?? '').toString(),

      receivedByName: (map['receivedByName'] ?? '').toString(),

      /// Méthode paiement
      method: (map['method'] ?? '').toString(),

      amount: toDouble(map['amount']),

      /// Statut paiement
      status: (map['status'] ?? '').toString(),

      /// Versements
      handoverStatus: (map['handoverStatus'] ?? 'pending').toString(),

      handoverId: map['handoverId']?.toString(),

      /// Fiscalisation
      isFiscalized: map['isFiscalized'] == true,

      fiscalUid: (map['fiscalUid'] ?? '').toString(),

      /// Offline
      pendingSync: map['pendingSync'] == true,

      syncError: map['syncError'] == true,

      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,

      /// Référence commande
      'orderId': orderId,
      'orderNumber': orderNumber,

      /// Type client
      'clientType': clientType,

      /// Type paiement
      'type': type,

      /// Encaissement
      'receivedBy': receivedBy,
      'receivedByName': receivedByName,

      /// Paiement
      'method': method,
      'amount': amount,
      'status': status,

      /// Versements
      'handoverStatus': handoverStatus,
      'handoverId': handoverId,

      /// Fiscalisation
      'isFiscalized': isFiscalized,
      'fiscalUid': fiscalUid,

      /// Offline
      'pendingSync': pendingSync,
      'syncError': syncError,

      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? establishmentId,

    String? orderId,
    String? orderNumber,

    String? clientType,
    String? type,

    String? receivedBy,
    String? receivedByName,

    String? method,
    double? amount,

    String? status,

    String? handoverStatus,
    String? handoverId,

    bool? isFiscalized,
    String? fiscalUid,

    bool? pendingSync,
    bool? syncError,

    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,

      establishmentId: establishmentId ?? this.establishmentId,

      orderId: orderId ?? this.orderId,

      orderNumber: orderNumber ?? this.orderNumber,

      clientType: clientType ?? this.clientType,

      type: type ?? this.type,

      receivedBy: receivedBy ?? this.receivedBy,

      receivedByName: receivedByName ?? this.receivedByName,

      method: method ?? this.method,

      amount: amount ?? this.amount,

      status: status ?? this.status,

      handoverStatus: handoverStatus ?? this.handoverStatus,

      handoverId: handoverId ?? this.handoverId,

      isFiscalized: isFiscalized ?? this.isFiscalized,

      fiscalUid: fiscalUid ?? this.fiscalUid,

      pendingSync: pendingSync ?? this.pendingSync,

      syncError: syncError ?? this.syncError,

      createdAt: createdAt ?? this.createdAt,
    );
  }
}
