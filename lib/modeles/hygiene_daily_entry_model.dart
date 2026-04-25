import 'package:cloud_firestore/cloud_firestore.dart';

class HygieneDailyEntryModel {
  final String id;
  final String roomNumber;
  final String preparedBy;
  final String preparedByName;
  final String note;
  final DateTime? preparedAt;

  HygieneDailyEntryModel({
    required this.id,
    required this.roomNumber,
    required this.preparedBy,
    required this.preparedByName,
    required this.note,
    required this.preparedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomNumber': roomNumber,
      'preparedBy': preparedBy,
      'preparedByName': preparedByName,
      'note': note,
      'preparedAt': preparedAt == null ? null : Timestamp.fromDate(preparedAt!),
    };
  }

  factory HygieneDailyEntryModel.fromMap(String id, Map<String, dynamic> map) {
    return HygieneDailyEntryModel(
      id: id,
      roomNumber: map['roomNumber']?.toString() ?? '',
      preparedBy: map['preparedBy']?.toString() ?? '',
      preparedByName: map['preparedByName']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      preparedAt: map['preparedAt'] is Timestamp
          ? (map['preparedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
