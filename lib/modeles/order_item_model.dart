import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String id;
  final String establishmentId;

  final String menuItemId;
  final String name;

  final int quantity;
  final double unitPrice;
  final double totalPrice;

  final String note;
  final String targetDepartment;

  final bool isCancelled;
  final DateTime? cancelledAt;
  final String cancelledBy;
  final String cancelledByName;
  final String cancellationReason;

  const OrderItemModel({
    required this.id,
    required this.establishmentId,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.note,
    required this.targetDepartment,
    this.isCancelled = false,
    this.cancelledAt,
    this.cancelledBy = '',
    this.cancelledByName = '',
    this.cancellationReason = '',
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map, {String id = ''}) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return OrderItemModel(
      id: id,
      establishmentId: (map['establishmentId'] ?? '').toString(),

      menuItemId: (map['menuItemId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),

      quantity: toInt(map['quantity']),
      unitPrice: toDouble(map['unitPrice']),
      totalPrice: toDouble(map['totalPrice']),

      note: (map['note'] ?? '').toString(),

      targetDepartment: (map['targetDepartment'] ?? '').toString(),

      isCancelled: map['isCancelled'] == true,

      cancelledAt: map['cancelledAt'] is Timestamp
          ? (map['cancelledAt'] as Timestamp).toDate()
          : null,

      cancelledBy: (map['cancelledBy'] ?? '').toString(),

      cancelledByName: (map['cancelledByName'] ?? '').toString(),

      cancellationReason: (map['cancellationReason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,

      'menuItemId': menuItemId,
      'name': name,

      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,

      'note': note,

      'targetDepartment': targetDepartment,

      'isCancelled': isCancelled,

      'cancelledAt': cancelledAt == null
          ? null
          : Timestamp.fromDate(cancelledAt!),

      'cancelledBy': cancelledBy,
      'cancelledByName': cancelledByName,
      'cancellationReason': cancellationReason,
    };
  }

  OrderItemModel copyWith({
    String? id,
    String? establishmentId,

    String? menuItemId,
    String? name,

    int? quantity,
    double? unitPrice,
    double? totalPrice,

    String? note,
    String? targetDepartment,

    bool? isCancelled,
    DateTime? cancelledAt,

    String? cancelledBy,
    String? cancelledByName,
    String? cancellationReason,
  }) {
    return OrderItemModel(
      id: id ?? this.id,

      establishmentId: establishmentId ?? this.establishmentId,

      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,

      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,

      note: note ?? this.note,

      targetDepartment: targetDepartment ?? this.targetDepartment,

      isCancelled: isCancelled ?? this.isCancelled,

      cancelledAt: cancelledAt ?? this.cancelledAt,

      cancelledBy: cancelledBy ?? this.cancelledBy,

      cancelledByName: cancelledByName ?? this.cancelledByName,

      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
