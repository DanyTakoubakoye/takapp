import 'package:flutter_test/flutter_test.dart';
import 'package:takapp/modeles/shift_model.dart';
import 'package:takapp/services/shift_handover_service.dart';

ShiftModel _shift(Map<String, dynamic> extra) => ShiftModel.fromMap({
  'floorManagerId': 'paul',
  'createdBy': 'awa',
  'createdByName': 'Awa',
  'createdByRole': 'gerante',
  ...extra,
}, 'sh1');

void main() {
  test('service créé par la gérante : les remises vont à la gérante', () {
    final shift = _shift(const {});
    expect(ShiftHandoverService.receiverIdOf(shift), 'awa');
    expect(ShiftHandoverService.receiverNameOf(shift), 'Awa');
    expect(ShiftHandoverService.hasReceiver(shift), isTrue);
  });

  test('service créé par le Floor Manager : destinataire désigné', () {
    final shift = _shift(const {
      'createdBy': 'paul',
      'createdByName': 'Paul',
      'createdByRole': 'floor_manager',
      'cashReceiverId': 'awa',
      'cashReceiverName': 'Awa',
      'cashReceiverRole': 'gerante',
    });
    expect(shift.cashReceiverId, 'awa');
    expect(ShiftHandoverService.receiverIdOf(shift), 'awa');
    expect(ShiftHandoverService.receiverRoleOf(shift), 'gerante');
    expect(ShiftHandoverService.hasReceiver(shift), isTrue);
  });

  test('créé par le Floor Manager sans destinataire : jamais lui-même', () {
    final shift = _shift(const {
      'createdBy': 'paul',
      'createdByRole': 'floor_manager',
    });
    expect(ShiftHandoverService.hasReceiver(shift), isFalse);
  });
}
