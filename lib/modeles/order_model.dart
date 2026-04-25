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

  final String kitchenStatus;
  final bool isForKitchen;

  final String barStatus;
  final bool isForBar;

  final bool stockDeducted;
  final bool stockRestored;

  final bool hasCancelledItems;

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
    required this.barStatus,
    required this.isForBar,
    required this.stockDeducted,
    required this.stockRestored,
    required this.hasCancelledItems,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime toDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return OrderModel(
      id: documentId,
      orderNumber: (map['orderNumber'] ?? '').toString(),
      clientType: (map['clientType'] ?? '').toString(),
      tableNumber: map['tableNumber']?.toString(),
      roomNumber: map['roomNumber']?.toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? '').toString(),
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
      hasCancelledItems: map['hasCancelledItems'] == true,
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
      'barStatus': barStatus,
      'isForBar': isForBar,
      'stockDeducted': stockDeducted,
      'stockRestored': stockRestored,
      'hasCancelledItems': hasCancelledItems,
    };
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
