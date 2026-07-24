import 'package:cloud_firestore/cloud_firestore.dart';

class RoomInvoiceModel {
  final String id;
  final String clientName;
  final String roomNumber;
  final int nights;
  final double pricePerNight;
  final double roomTotal;
  final double extrasTotal;
  final double servicesTotal;
  final double total;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  const RoomInvoiceModel({
    required this.id,
    required this.clientName,
    required this.roomNumber,
    required this.nights,
    required this.pricePerNight,
    required this.roomTotal,
    required this.extrasTotal,
    required this.servicesTotal,
    required this.total,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory RoomInvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomInvoiceModel(
      id: id,
      clientName: map['clientName'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      nights: map['nights'] ?? 0,
      pricePerNight: (map['pricePerNight'] ?? 0).toDouble(),
      roomTotal: (map['roomTotal'] ?? 0).toDouble(),
      extrasTotal: (map['extrasTotal'] ?? 0).toDouble(),
      servicesTotal: (map['servicesTotal'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      status: map['status'] ?? 'unpaid',
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'roomNumber': roomNumber,
      'nights': nights,
      'pricePerNight': pricePerNight,
      'roomTotal': roomTotal,
      'extrasTotal': extrasTotal,
      'servicesTotal': servicesTotal,
      'total': total,
      'status': status,
      'startDate': Timestamp.fromDate(startDate!),
      'endDate': Timestamp.fromDate(endDate!),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
