import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String clientType;
  final String? tableNumber;
  final String? roomNumber;
  final String createdBy;
  final String createdByName;
  final String status;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentStatus;
  final DateTime createdAt;
  final String kitchenStatus; // pending, preparing, ready
  final bool isForKitchen;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.clientType,
    required this.tableNumber,
    required this.roomNumber,
    required this.createdBy,
    required this.createdByName,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentStatus,
    required this.createdAt,
    required this.kitchenStatus,
    required this.isForKitchen,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: documentId,
      orderNumber: (map['orderNumber'] ?? '').toString(),
      clientType: (map['clientType'] ?? '').toString(),
      tableNumber: map['tableNumber']?.toString(),
      roomNumber: map['roomNumber']?.toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      paymentStatus: (map['paymentStatus'] ?? '').toString(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      kitchenStatus: (map['kitchenStatus'] ?? 'pending').toString(),
      isForKitchen: map['isForKitchen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'clientType': clientType,
      'tableNumber': tableNumber,
      'roomNumber': roomNumber,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'status': status,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'kitchenStatus': kitchenStatus,
      'isForKitchen': isForKitchen,
    };
  }
}

enum KitchenStatus { pending, preparing, ready, served }

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
    default:
      return KitchenStatus.pending;
  }
}

String kitchenStatusToString(KitchenStatus status) {
  return status.name;
}
