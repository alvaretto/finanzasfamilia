import 'package:drift/drift.dart';

/// Tabla de adjuntos de transacciones (recibos, facturas, fotos)
class TransactionAttachments extends Table {
  /// ID único del adjunto
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// ID de la transacción asociada
  TextColumn get transactionId => text()();

  /// Nombre del archivo
  TextColumn get fileName => text()();

  /// Tipo MIME del archivo (image/jpeg, image/png, application/pdf)
  TextColumn get mimeType => text()();

  /// Ruta local del archivo
  TextColumn get localPath => text()();

  /// URL remota en Supabase Storage (nullable hasta que se sincronice)
  TextColumn get remoteUrl => text().nullable()();

  /// Tamaño del archivo en bytes
  IntColumn get fileSize => integer()();

  /// Texto extraído por OCR (nullable)
  TextColumn get ocrText => text().nullable()();

  /// Monto detectado por OCR (nullable)
  RealColumn get ocrAmount => real().nullable()();

  /// Estado de sincronización - Nullable para compatibilidad con PowerSync
  BoolColumn get isSynced => boolean().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Fecha de creación
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
