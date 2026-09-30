import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;

  /// SaaS
  final String establishmentId;

  final String orderNumber;

  /// Addition (ticket) regroupant toutes les commandes successives d'une même
  /// table ou d'une même chambre tant qu'elles ne sont pas encaissées.
  final String ticketId;

  /// restaurant | hotel | bar
  final String clientType;

  final String? tableNumber;
  final String? roomNumber;

  /// Fiche client rattachée. Chaîne vide = commande non rattachée.
  final String clientId;

  /// TRANSITION : SERVEUR RESPONSABLE de la vente (sens que lui donnent déjà
  /// toutes les requêtes, index et notifications). Pour les anciennes
  /// commandes, c'est aussi l'auteur (les deux se confondaient).
  final String createdBy;
  final String createdByName;

  /// Auteur réel de la saisie. `null` sur les anciennes commandes.
  final String? performedByUserId;
  final String? performedByUserName;

  /// Serveur responsable. `null` sur les anciennes commandes.
  final String? assignedServerId;
  final String? assignedServerName;

  /// Service (shift) de saisie. `null` : ancienne commande ou serveur hors
  /// système de shift.
  final String? shiftId;

  /// sent | preparing | ready | served | cancelled
  final String status;

  final double subtotal;
  final double tax;
  final double total;

  /// unpaid | partially_paid | paid
  final String paymentStatus;

  final DateTime createdAt;

  /// pending | preparing | ready | served | cancelled
  final String kitchenStatus;

  final bool isForKitchen;

  /// pending | preparing | ready | served | cancelled
  final String barStatus;

  final bool isForBar;

  /// Gestion stock
  final bool stockDeducted;
  final bool stockRestored;

  /// SaaS + Offline
  final bool pendingSync;
  final bool syncError;

  /// Annulations
  final bool hasCancelledItems;

  /// Fiscalisation (écrits sur la commande lors de la certification)
  final bool isFiscalized;
  final String fiscalStatus;

  const OrderModel({
    required this.id,
    required this.establishmentId,
    required this.orderNumber,
    this.ticketId = '',
    required this.clientType,
    required this.tableNumber,
    required this.roomNumber,
    required this.clientId,
    required this.createdBy,
    required this.createdByName,
    this.performedByUserId,
    this.performedByUserName,
    this.assignedServerId,
    this.assignedServerName,
    this.shiftId,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentStatus,
    required this.createdAt,
    required this.kitchenStatus,
    required this.isForKitchen,
    required this.barStatus,
    required this.isForBar,
    required this.stockDeducted,
    required this.stockRestored,
    required this.pendingSync,
    required this.syncError,
    required this.hasCancelledItems,
    this.isFiscalized = false,
    this.fiscalStatus = '',
  });

  /// Chaîne vide ou absente => `null` (ancienne commande).
  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  /// =========================
  /// LECTURE RÉTROCOMPATIBLE
  /// =========================
  ///
  /// À utiliser pour la RESPONSABILITÉ COMMERCIALE (listes du serveur,
  /// impayés, destinataire « prêt ») : `assignedServerId ?? createdBy`.
  String get effectiveAssignedServerId => assignedServerId ?? createdBy;

  String get effectiveAssignedServerName => assignedServerName ?? createdByName;

  /// À utiliser pour l'AUDIT (qui a réellement saisi) :
  /// `performedByUserId ?? createdBy` (anciennes commandes : auteur = créateur).
  String get effectivePerformedByUserId => performedByUserId ?? createdBy;

  String get effectivePerformedByUserName =>
      performedByUserName ?? createdByName;

  /// Saisie par quelqu'un d'autre que le serveur responsable.
  bool get isDelegated =>
      effectivePerformedByUserId != effectiveAssignedServerId;

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    double toDouble(dynamic value) {
      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime toDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      return DateTime.now();
    }

    return OrderModel(
      id: documentId,

      establishmentId: (map['establishmentId'] ?? '').toString(),

      orderNumber: (map['orderNumber'] ?? '').toString(),

      ticketId: (map['ticketId'] ?? '').toString(),

      clientType: (map['clientType'] ?? '').toString(),

      tableNumber: map['tableNumber']?.toString(),

      roomNumber: map['roomNumber']?.toString(),

      clientId: map['clientId']?.toString() ?? '',

      createdBy: (map['createdBy'] ?? '').toString(),

      createdByName: (map['createdByName'] ?? '').toString(),

      performedByUserId: _optionalString(map['performedByUserId']),
      performedByUserName: _optionalString(map['performedByUserName']),
      assignedServerId: _optionalString(map['assignedServerId']),
      assignedServerName: _optionalString(map['assignedServerName']),
      shiftId: _optionalString(map['shiftId']),

      status: (map['status'] ?? '').toString(),

      subtotal: toDouble(map['subtotal']),

      tax: toDouble(map['tax']),

      total: toDouble(map['total']),

      paymentStatus: (map['paymentStatus'] ?? '').toString(),

      createdAt: toDateTime(map['createdAt']),

      kitchenStatus: (map['kitchenStatus'] ?? 'pending').toString(),

      isForKitchen: map['isForKitchen'] == true,

      barStatus: (map['barStatus'] ?? 'pending').toString(),

      isForBar: map['isForBar'] == true,

      stockDeducted: map['stockDeducted'] == true,

      stockRestored: map['stockRestored'] == true,

      pendingSync: map['pendingSync'] == true,

      syncError: map['syncError'] == true,

      hasCancelledItems: map['hasCancelledItems'] == true,
      isFiscalized: map['isFiscalized'] == true,
      fiscalStatus: (map['fiscalStatus'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      /// SaaS
      'establishmentId': establishmentId,

      'orderNumber': orderNumber,

      'ticketId': ticketId,

      'clientType': clientType,

      'tableNumber': tableNumber,
      'roomNumber': roomNumber,

      'clientId': clientId,

      'createdBy': createdBy,
      'createdByName': createdByName,

      // Absents des anciennes commandes : jamais réécrits à vide.
      if (performedByUserId != null) 'performedByUserId': performedByUserId,
      if (performedByUserName != null)
        'performedByUserName': performedByUserName,
      if (assignedServerId != null) 'assignedServerId': assignedServerId,
      if (assignedServerName != null) 'assignedServerName': assignedServerName,
      if (shiftId != null) 'shiftId': shiftId,

      'status': status,

      'subtotal': subtotal,
      'tax': tax,
      'total': total,

      'paymentStatus': paymentStatus,

      'createdAt': Timestamp.fromDate(createdAt),

      'kitchenStatus': kitchenStatus,
      'isForKitchen': isForKitchen,

      'barStatus': barStatus,
      'isForBar': isForBar,

      'stockDeducted': stockDeducted,
      'stockRestored': stockRestored,

      /// Offline sync
      'pendingSync': pendingSync,
      'syncError': syncError,

      /// Annulations
      'hasCancelledItems': hasCancelledItems,
      'isFiscalized': isFiscalized,
      'fiscalStatus': fiscalStatus,
    };
  }

  OrderModel copyWith({
    String? id,
    String? establishmentId,
    String? orderNumber,
    String? ticketId,
    String? clientType,
    String? tableNumber,
    String? roomNumber,
    String? clientId,
    String? createdBy,
    String? createdByName,
    String? status,
    double? subtotal,
    double? tax,
    double? total,
    String? paymentStatus,
    DateTime? createdAt,
    String? kitchenStatus,
    bool? isForKitchen,
    String? barStatus,
    bool? isForBar,
    bool? stockDeducted,
    bool? stockRestored,
    bool? pendingSync,
    bool? syncError,
    bool? hasCancelledItems,
    bool? isFiscalized,
    String? fiscalStatus,
  }) {
    return OrderModel(
      id: id ?? this.id,

      establishmentId: establishmentId ?? this.establishmentId,

      orderNumber: orderNumber ?? this.orderNumber,

      ticketId: ticketId ?? this.ticketId,

      clientType: clientType ?? this.clientType,

      tableNumber: tableNumber ?? this.tableNumber,

      roomNumber: roomNumber ?? this.roomNumber,

      clientId: clientId ?? this.clientId,

      createdBy: createdBy ?? this.createdBy,

      createdByName: createdByName ?? this.createdByName,

      // Acteurs figés à la création : jamais modifiés par copyWith.
      performedByUserId: performedByUserId,
      performedByUserName: performedByUserName,
      assignedServerId: assignedServerId,
      assignedServerName: assignedServerName,
      shiftId: shiftId,

      status: status ?? this.status,

      subtotal: subtotal ?? this.subtotal,

      tax: tax ?? this.tax,

      total: total ?? this.total,

      paymentStatus: paymentStatus ?? this.paymentStatus,

      createdAt: createdAt ?? this.createdAt,

      kitchenStatus: kitchenStatus ?? this.kitchenStatus,

      isForKitchen: isForKitchen ?? this.isForKitchen,

      barStatus: barStatus ?? this.barStatus,

      isForBar: isForBar ?? this.isForBar,

      stockDeducted: stockDeducted ?? this.stockDeducted,

      stockRestored: stockRestored ?? this.stockRestored,

      pendingSync: pendingSync ?? this.pendingSync,

      syncError: syncError ?? this.syncError,

      hasCancelledItems: hasCancelledItems ?? this.hasCancelledItems,
      isFiscalized: isFiscalized ?? this.isFiscalized,
      fiscalStatus: fiscalStatus ?? this.fiscalStatus,
    );
  }
}

enum KitchenStatus { pending, preparing, ready, served, cancelled }

KitchenStatus kitchenStatusFromString(String status) {
  switch (status) {
    case 'pending':
      return KitchenStatus.pending;

    case 'preparing':
      return KitchenStatus.preparing;

    case 'ready':
      return KitchenStatus.ready;

    case 'served':
      return KitchenStatus.served;

    case 'cancelled':
      return KitchenStatus.cancelled;

    default:
      return KitchenStatus.pending;
  }
}

String kitchenStatusToString(KitchenStatus status) {
  return status.name;
}
