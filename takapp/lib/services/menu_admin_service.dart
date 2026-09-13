import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takapp/core/errors/app_error.dart';
import 'package:takapp/modeles/menu_item_model.dart';

class MenuAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? establishmentId;

  MenuAdminService({this.establishmentId});

  String _resolveEstablishmentId(String? id) {
    return (id ?? establishmentId ?? '').trim();
  }

  CollectionReference<Map<String, dynamic>> _menuCol({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('menuItems');
  }

  Future<void> addMenuItem({
    required String establishmentId,
    required MenuItemModel item,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    if (resolvedEstablishmentId.isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    final docRef = _menuCol(establishmentId: resolvedEstablishmentId).doc();

    await docRef.set({
      ...item.toMap(),
      'id': docRef.id,
      'establishmentId': resolvedEstablishmentId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });
  }

  Stream<List<MenuItemModel>> streamMenuItems({String? establishmentId}) {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    if (resolvedEstablishmentId.isEmpty) {
      return Stream.value([]);
    }

    return _menuCol(
      establishmentId: resolvedEstablishmentId,
    ).orderBy('name').snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
          .toList();

      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return items;
    });
  }

  Stream<List<MenuItemModel>> streamAvailableMenuItems({
    String? establishmentId,
  }) {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    if (resolvedEstablishmentId.isEmpty) {
      return Stream.value([]);
    }

    return _menuCol(
      establishmentId: resolvedEstablishmentId,
    ).where('isAvailable', isEqualTo: true).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
          .toList();

      items.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return items;
    });
  }

  Future<void> deleteMenuItem({
    required String establishmentId,
    required String id,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);
    final menuItemId = id.trim();

    if (resolvedEstablishmentId.isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    if (menuItemId.isEmpty) {
      throw const AppError(AppErrorCode.invalidMenuId);
    }

    await _menuCol(
      establishmentId: resolvedEstablishmentId,
    ).doc(menuItemId).delete();
  }

  Future<void> updateAvailability({
    String? establishmentId,
    required String id,
    required bool isAvailable,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    if (resolvedEstablishmentId.isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    if (id.trim().isEmpty) {
      throw const AppError(AppErrorCode.invalidMenuId);
    }

    await _menuCol(establishmentId: resolvedEstablishmentId).doc(id).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });
  }

  Future<void> updateMenuItem({
    String? establishmentId,
    required MenuItemModel item,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    if (resolvedEstablishmentId.isEmpty) {
      throw const AppError(AppErrorCode.establishmentNotFound);
    }

    if (item.id.trim().isEmpty) {
      throw const AppError(AppErrorCode.invalidMenuId);
    }

    await _menuCol(
      establishmentId: resolvedEstablishmentId,
    ).doc(item.id).update({
      ...item.toMap(),
      'id': item.id,
      'establishmentId': resolvedEstablishmentId,
      'updatedAt': FieldValue.serverTimestamp(),
      'pendingSync': false,
      'syncError': false,
    });
  }
}
