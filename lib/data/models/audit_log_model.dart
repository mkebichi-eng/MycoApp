class AuditLogModel {
  final String id;
  final String collectionName;
  final String documentId;
  final String action; // CREATE, UPDATE, DELETE
  final String performedByUid;
  final String performedByEmail;
  final String performedByRole;
  final Map<String, dynamic> changeSummary;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.collectionName,
    required this.documentId,
    required this.action,
    required this.performedByUid,
    required this.performedByEmail,
    required this.performedByRole,
    required this.changeSummary,
    required this.timestamp,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogModel(
      id: id,
      collectionName: map['collectionName'] as String? ?? '',
      documentId: map['documentId'] as String? ?? '',
      action: map['action'] as String? ?? 'UPDATE',
      performedByUid: map['performedByUid'] as String? ?? '',
      performedByEmail: map['performedByEmail'] as String? ?? '',
      performedByRole: map['performedByRole'] as String? ?? '',
      changeSummary: Map<String, dynamic>.from(map['changeSummary'] as Map? ?? {}),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collectionName': collectionName,
      'documentId': documentId,
      'action': action,
      'performedByUid': performedByUid,
      'performedByEmail': performedByEmail,
      'performedByRole': performedByRole,
      'changeSummary': changeSummary,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
