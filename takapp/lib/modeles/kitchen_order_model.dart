import 'package:cloud_firestore/cloud_firestore.dart';

class KitchenOrderModel {
  final String id;
  final String establishmentId;
  final String orderNumber;
  final String clientType;
  final String? tableNumber;
  final String? roomNumber;
  final String createdBy;
  final String createdByName;
  final String status;
  final String kitchenStatus;
  final bool isForKitchen;
  final double total;
  final String paymentStatus;
  final DateTime? createdAt;

  const KitchenOrderModel({
    required this.id,
    required this.establishmentId,
    required this.orderNumber,
    required this.clientType,
    required this.tableNumber,
    required this.roomNumber,
    required this.createdBy,
    required this.createdByName,
    required this.status,
    required this.kitchenStatus,
    required this.isForKitchen,
    required this.total,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory KitchenOrderModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final ts = map['createdAt'];

    return KitchenOrderModel(
      id: documentId,
      establishmentId: (map['establishmentId'] ?? '').toString(),
      orderNumber: (map['orderNumber'] ?? '').toString(),
      clientType: (map['clientType'] ?? '').toString(),
      tableNumber: map['tableNumber']?.toString(),
      roomNumber: map['roomNumber']?.toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      kitchenStatus: (map['kitchenStatus'] ?? 'pending').toString(),
      isForKitchen: map['isForKitchen'] == true,
      total: ((map['total'] ?? 0) as num).toDouble(),
      paymentStatus: (map['paymentStatus'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
      'orderNumber': orderNumber,
      'clientType': clientType,
      'tableNumber': tableNumber,
      'roomNumber': roomNumber,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'status': status,
      'kitchenStatus': kitchenStatus,
      'isForKitchen': isForKitchen,
      'total': total,
      'paymentStatus': paymentStatus,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  KitchenOrderModel copyWith({
    String? id,
    String? establishmentId,
    String? orderNumber,
    String? clientType,
    String? tableNumber,
    String? roomNumber,
    String? createdBy,
    String? createdByName,
    String? status,
    String? kitchenStatus,
    bool? isForKitchen,
    double? total,
    String? paymentStatus,
    DateTime? createdAt,
  }) {
    return KitchenOrderModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      orderNumber: orderNumber ?? this.orderNumber,
      clientType: clientType ?? this.clientType,
      tableNumber: tableNumber ?? this.tableNumber,
      roomNumber: roomNumber ?? this.roomNumber,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      status: status ?? this.status,
      kitchenStatus: kitchenStatus ?? this.kitchenStatus,
      isForKitchen: isForKitchen ?? this.isForKitchen,
      total: total ?? this.total,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
