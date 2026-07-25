import 'package:cloud_firestore/cloud_firestore.dart';

import '../modeles/client_model.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String? establishmentId;

  ClientService({this.establishmentId});

  /// Valeurs techniques du type de client (traduites à l'affichage)
  static const List<String> clientTypes = ['particulier', 'entreprise'];

  /// =========================
  /// HELPERS SAAS
  /// =========================

  String _resolveEstablishmentId(String? id) {
    final resolved = (id ?? establishmentId ?? '').trim();

    if (resolved.isEmpty) {
      throw Exception('Établissement introuvable.');
    }

    return resolved;
  }

  CollectionReference<Map<String, dynamic>> _col({
    required String establishmentId,
  }) {
    return _firestore
        .collection('establishments')
        .doc(establishmentId)
        .collection('clients');
  }

  List<ClientModel> _sortClients(List<ClientModel> clients) {
    clients.sort((a, b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return clients;
  }

  /// Lecture ponctuelle des clients actifs.
  /// Tri côté client : aucun index Firestore requis.
  Future<List<ClientModel>> _fetchActiveClients(String establishmentId) async {
    final snapshot = await _col(establishmentId: establishmentId).get();

    final clients = snapshot.docs
        .map((doc) => ClientModel.fromMap(doc.id, doc.data()))
        .where((client) => client.isActive)
        .toList();

    return _sortClients(clients);
  }

  /// =========================
  /// STREAM ALL CLIENTS
  /// =========================

  Stream<List<ClientModel>> streamClients({String? establishmentId}) {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    return _col(establishmentId: resolvedEstablishmentId).snapshots().map((
      snapshot,
    ) {
      final clients = snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.id, doc.data()))
          .where((client) => client.isActive)
          .toList();

      return _sortClients(clients);
    });
  }

  /// =========================
  /// SEARCH CLIENTS
  /// =========================

  /// Recherche par nom OU téléphone.
  /// Firestore ne sait pas faire de "contains" : le filtre est fait
  /// côté client sur les clients actifs.
  Future<List<ClientModel>> searchClients({
    String? establishmentId,
    required String query,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return <ClientModel>[];
    }

    final lowerQuery = cleanQuery.toLowerCase();

    final clients = await _fetchActiveClients(resolvedEstablishmentId);

    return clients.where((client) {
      return client.name.toLowerCase().contains(lowerQuery) ||
          client.phone.contains(cleanQuery);
    }).toList();
  }

  /// =========================
  /// FIND POTENTIAL DUPLICATES
  /// =========================

  /// Clients actifs dont le nom correspond exactement (trim + lowercase)
  /// OU dont le téléphone correspond exactement (trim).
  /// Les clients sans téléphone sont ignorés sur le critère téléphone.
  /// Sert à alerter l'UI AVANT création : ne bloque rien.
  Future<List<ClientModel>> findPotentialDuplicates({
    String? establishmentId,
    required String name,
    required String phone,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    final cleanName = name.trim().toLowerCase();

    final cleanPhone = phone.trim();

    if (cleanName.isEmpty && cleanPhone.isEmpty) {
      return <ClientModel>[];
    }

    final clients = await _fetchActiveClients(resolvedEstablishmentId);

    return clients.where((client) {
      final sameName =
          cleanName.isNotEmpty && client.name.trim().toLowerCase() == cleanName;

      final samePhone =
          cleanPhone.isNotEmpty &&
          client.phone.trim().isNotEmpty &&
          client.phone.trim() == cleanPhone;

      return sameName || samePhone;
    }).toList();
  }

  /// =========================
  /// CREATE CLIENT
  /// =========================

  /// Ne bloque PAS sur les doublons : l'UI appelle findPotentialDuplicates
  /// et décide de créer ou non.
  Future<String> createClient({
    String? establishmentId,
    required String name,
    required String phone,
    required String ifu,
    required String address,
    required String email,
    required String note,
    required String clientType,
    required String createdBy,
    required String createdByName,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Nom du client obligatoire.');
    }

    final cleanClientType = clientType.trim();

    if (!clientTypes.contains(cleanClientType)) {
      throw Exception('Type de client invalide.');
    }

    /// =========================
    /// CREATE
    /// =========================

    final docRef = _col(establishmentId: resolvedEstablishmentId).doc();

    await docRef.set({
      'establishmentId': resolvedEstablishmentId,
      'name': cleanName,
      'phone': phone.trim(),
      'ifu': ifu.trim(),
      'address': address.trim(),
      'email': email.trim(),
      'note': note.trim(),
      'clientType': cleanClientType,
      'isActive': true,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// =========================
  /// UPDATE CLIENT
  /// =========================

  Future<void> updateClient({
    String? establishmentId,
    required String clientId,
    required String name,
    required String phone,
    required String ifu,
    required String address,
    required String email,
    required String note,
    required String clientType,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolvedEstablishmentId).doc(clientId).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'ifu': ifu.trim(),
      'address': address.trim(),
      'email': email.trim(),
      'note': note.trim(),
      'clientType': clientType.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// DISABLE CLIENT
  /// =========================

  Future<void> disableClient({
    String? establishmentId,
    required String clientId,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    await _col(establishmentId: resolvedEstablishmentId).doc(clientId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// =========================
  /// GET CLIENT BY ID
  /// =========================

  /// Renvoie null si le client n'existe pas ou s'il est désactivé.
  Future<ClientModel?> getClientById({
    String? establishmentId,
    required String clientId,
  }) async {
    final resolvedEstablishmentId = _resolveEstablishmentId(establishmentId);

    final doc = await _col(
      establishmentId: resolvedEstablishmentId,
    ).doc(clientId).get();

    final data = doc.data();

    if (!doc.exists || data == null) {
      return null;
    }

    final client = ClientModel.fromMap(doc.id, data);

    if (!client.isActive) {
      return null;
    }

    return client;
  }
}
