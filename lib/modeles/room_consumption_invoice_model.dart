import 'room_consumption_line_model.dart';

class RoomConsumptionInvoiceModel {
  final String roomNumber;
  final DateTime startDate;
  final DateTime endDate;
  final List<RoomConsumptionLineModel> lines;
  final double total;

  RoomConsumptionInvoiceModel({
    required this.roomNumber,
    required this.startDate,
    required this.endDate,
    required this.lines,
    required this.total,
  });
}
