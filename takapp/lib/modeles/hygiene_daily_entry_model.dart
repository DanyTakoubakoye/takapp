import 'package:cloud_firestore/cloud_firestore.dart';

class HygieneDailyEntryModel {
  final String id;
  final String establishmentId;
  final String roomNumber;
  final String preparedBy;
  final String preparedByName;
  final String note;
  final DateTime? preparedAt;

  const HygieneDailyEntryModel({
    required this.id,
    required this.establishmentId,
    required this.roomNumber,
    required this.preparedBy,
    required this.preparedByName,
    required this.note,
    required this.preparedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'establishmentId': establishmentId,
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
      establishmentId: map['establishmentId']?.toString() ?? '',
      roomNumber: map['roomNumber']?.toString() ?? '',
      preparedBy: map['preparedBy']?.toString() ?? '',
      preparedByName: map['preparedByName']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      preparedAt: map['preparedAt'] is Timestamp
          ? (map['preparedAt'] as Timestamp).toDate()
          : null,
    );
  }

  HygieneDailyEntryModel copyWith({
    String? id,
    String? establishmentId,
    String? roomNumber,
    String? preparedBy,
    String? preparedByName,
    String? note,
    DateTime? preparedAt,
  }) {
    return HygieneDailyEntryModel(
      id: id ?? this.id,
      establishmentId: establishmentId ?? this.establishmentId,
      roomNumber: roomNumber ?? this.roomNumber,
      preparedBy: preparedBy ?? this.preparedBy,
      preparedByName: preparedByName ?? this.preparedByName,
      note: note ?? this.note,
      preparedAt: preparedAt ?? this.preparedAt,
    );
  }
}
