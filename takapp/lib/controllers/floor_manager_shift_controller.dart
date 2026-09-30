import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:takapp/core/constants/app_roles.dart';
import 'package:takapp/core/errors/error_localizer.dart';
import 'package:takapp/l10n/app_localizations.dart';
import 'package:takapp/modeles/user_model.dart';
import 'package:takapp/services/shift_service.dart';

/// Service courant du Floor Manager connecté, en temps réel.
///
/// Suit l'utilisateur connecté (comme `EstablishmentConfigController`) et
/// s'abonne à `ShiftService.watchFloorManagerShift`. Pour tout autre rôle,
/// l'état reste [FloorManagerShiftState.none] et rien n'est écouté.
class FloorManagerShiftController extends ChangeNotifier {
  final ShiftService _service;

  FloorManagerShiftController(this._service);

  String _userKey = '';
  StreamSubscription<FloorManagerShiftState>? _subscription;
  int _generation = 0;

  FloorManagerShiftState _state = FloorManagerShiftState.none;
  bool _isLoading = false;
  Object? _error;

  FloorManagerShiftState get state => _state;
  bool get isLoading => _isLoading;
  bool get hasError => _error != null;

  String? errorText(AppLocalizations l10n) {
    if (_error == null) return null;
    return localizedError(l10n, _error);
  }

  void setCurrentUser(UserModel? user) {
    final isFloorManager =
        user != null && user.role == AppRoles.floorManager && user.isActive;
    final key = isFloorManager ? '${user.uid}|${user.establishmentId}' : '';
    if (key == _userKey) return;

    _userKey = key;
    final generation = ++_generation;
    _subscription?.cancel();
    _subscription = null;
    _state = FloorManagerShiftState.none;
    _error = null;
    _isLoading = isFloorManager;
    notifyListeners();

    if (!isFloorManager) return;

    _subscription = _service
        .watchFloorManagerShift(
          establishmentId: user.establishmentId,
          currentUser: user,
        )
        .listen(
          (state) {
            if (generation != _generation) return;
            _state = state;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (generation != _generation) return;
            // En cas d'erreur, jamais de serveurs « fantômes » : état vide.
            _state = FloorManagerShiftState.none;
            _isLoading = false;
            _error = error;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }
}
