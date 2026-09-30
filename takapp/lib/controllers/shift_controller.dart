import 'package:flutter/material.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/shift_service.dart';

/// Gestion des services (shifts) côté gérante. Le Floor Manager lit son
/// service via `FloorManagerShiftController`. Toute la logique métier est
/// dans `ShiftService` / `ShiftPolicy` ; ce contrôleur ne porte que l'état
/// d'UI.
class ShiftController extends ChangeNotifier {
  final ShiftService _service;

  ShiftController(this._service);

  bool _isSubmitting = false;

  /// Erreur courante : un `AppError` traduisible, ou une exception brute.
  Object? _error;

  bool get isSubmitting => _isSubmitting;
  bool get hasError => _error != null;

  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      _error = e;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> createShift({
    required String establishmentId,
    required UserModel? floorManager,
    required List<UserModel> servers,
    required DateTime startsAt,
    required DateTime endsAt,
    required String createdBy,
    String createdByName = '',
    String createdByRole = '',
  }) {
    return _run(
      () => _service.createShift(
        establishmentId: establishmentId,
        floorManager: floorManager,
        servers: servers,
        startsAt: startsAt,
        endsAt: endsAt,
        createdBy: createdBy,
        createdByName: createdByName,
        createdByRole: createdByRole,
      ),
    );
  }

  Future<bool> openShift({
    required String establishmentId,
    required String shiftId,
    required String userId,
  }) {
    return _run(
      () => _service.openShift(
        establishmentId: establishmentId,
        shiftId: shiftId,
        openedBy: userId,
      ),
    );
  }

  Future<bool> closeShift({
    required String establishmentId,
    required String shiftId,
    required String userId,
  }) {
    return _run(
      () => _service.closeShift(
        establishmentId: establishmentId,
        shiftId: shiftId,
        closedBy: userId,
      ),
    );
  }

  Future<bool> updateServers({
    required String establishmentId,
    required String shiftId,
    required List<UserModel> servers,
    required String userId,
  }) {
    return _run(
      () => _service.updateServers(
        establishmentId: establishmentId,
        shiftId: shiftId,
        servers: servers,
        updatedBy: userId,
      ),
    );
  }
}
