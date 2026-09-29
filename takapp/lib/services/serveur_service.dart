import 'package:cloud_functions/cloud_functions.dart';
import 'package:takapp/core/errors/app_error.dart';

class ServeurService {
  final FirebaseFunctions _functions;

  ServeurService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  void _validateEstablishmentId(String establishmentId) {
    if (establishmentId.trim().isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }
  }

  /// =========================
  /// CREATE SERVER USER
  /// =========================

  Future<void> enregistrerServeur({
    required String establishmentId,
    required String nomComplet,
    required String telephone,
    required String email,
    required String password,
  }) async {
    _validateEstablishmentId(establishmentId);

    final cleanName = nomComplet.trim();

    final cleanPhone = telephone.trim();

    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanName.isEmpty) {
      throw const AppError(AppErrorCode.invalidServerName);
    }

    if (cleanEmail.isEmpty) {
      throw const AppError(AppErrorCode.invalidEmail);
    }

    if (cleanPassword.isEmpty) {
      throw const AppError(AppErrorCode.serverRegistrationFailed);
    }

    await _functions.httpsCallable('createTenantUser').call({
      'name': cleanName,
      'email': cleanEmail,
      'password': cleanPassword,
      'phone': cleanPhone,
      'role': 'serveur',
    });
  }
}
