import '../../domain/entities/notifications/bank_notification.dart';

/// Parser base para notificaciones bancarias.
/// Cada banco tiene su propia implementación.
abstract class BankNotificationParser {
  ColombianBank get bank;

  /// Intenta parsear una notificación.
  /// Retorna null si no puede parsearla.
  ParsedBankTransaction? parse(RawBankNotification notification);

  /// Limpia el monto de caracteres no numéricos
  double? parseAmount(String text) {
    // Patrones comunes: $45.000, $45,000, 45000, $45.000,00
    final cleaned = text
        .replaceAll(RegExp(r'[^\d.,]'), '') // Solo números, puntos, comas
        .replaceAll('.', '') // Quitar separadores de miles
        .replaceAll(',', '.'); // Convertir coma decimal a punto

    if (cleaned.isEmpty) return null;

    return double.tryParse(cleaned);
  }

  /// Extrae últimos 4 dígitos de cuenta/tarjeta
  String? extractAccountDigits(String text) {
    // Patrones: *1234, ****1234, cuenta 1234, TC *1234
    final match = RegExp(r'\*+(\d{4})|\bcuenta[^\d]*(\d{4})').firstMatch(text);
    return match?.group(1) ?? match?.group(2);
  }
}

/// Parser para Bancolombia
class BancolombiaParser extends BankNotificationParser {
  @override
  ColombianBank get bank => ColombianBank.bancolombia;

  // Patrones de Bancolombia:
  // "Compra por $45.000 en EXITO COLOMBIA. Cuenta *1234. 15/01/26 10:30"
  // "Retiro por $200.000 en cajero. Cuenta *1234"
  // "Transferencia recibida por $500.000 de JUAN PEREZ"
  // "Transferencia enviada por $100.000 a MARIA GARCIA"
  // "Pago PSE por $89.900 en NETFLIX"

  static final _compraPattern = RegExp(
    r'(?:Compra|Pago|Retiro).*?\$\s*([\d.,]+).*?(?:en|a)\s+([A-Z0-9\s]+)',
    caseSensitive: false,
  );

  static final _transferenciaRecibidaPattern = RegExp(
    r'Transferencia\s+recibida.*?\$\s*([\d.,]+).*?de\s+([A-Z\s]+)',
    caseSensitive: false,
  );

  static final _transferenciaEnviadaPattern = RegExp(
    r'Transferencia\s+enviada.*?\$\s*([\d.,]+).*?a\s+([A-Z\s]+)',
    caseSensitive: false,
  );

  @override
  ParsedBankTransaction? parse(RawBankNotification notification) {
    final text = notification.bigText.isNotEmpty
        ? notification.bigText
        : notification.text;

    // Intentar cada patrón
    var match = _compraPattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.expense,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    match = _transferenciaRecibidaPattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.income,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    match = _transferenciaEnviadaPattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.transfer,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    return null;
  }

  ParsedBankTransaction? _buildTransaction(
    RawBankNotification notification,
    NotificationTransactionType type,
    String amountStr,
    String? merchant,
    String rawText,
  ) {
    final amount = parseAmount(amountStr);
    if (amount == null || amount <= 0) return null;

    return ParsedBankTransaction(
      notificationId: notification.id,
      bank: bank,
      type: type,
      amount: amount,
      timestamp: notification.timestamp,
      merchant: merchant,
      accountLastDigits: extractAccountDigits(rawText),
      rawText: rawText,
    );
  }
}

/// Parser para Nequi
class NequiParser extends BankNotificationParser {
  @override
  ColombianBank get bank => ColombianBank.nequi;

  // Patrones de Nequi:
  // "Pagaste $45.000 a RAPPI"
  // "Recibiste $100.000 de Juan Perez"
  // "Retiraste $50.000"
  // "Enviaste $30.000 a Maria Garcia"

  static final _pagastePattern = RegExp(
    r'Pagaste\s+\$\s*([\d.,]+)(?:\s+a\s+(.+))?',
    caseSensitive: false,
  );

  static final _recibistePattern = RegExp(
    r'Recibiste\s+\$\s*([\d.,]+)(?:\s+de\s+(.+))?',
    caseSensitive: false,
  );

  static final _retirastePattern = RegExp(
    r'Retiraste\s+\$\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _enviastePattern = RegExp(
    r'Enviaste\s+\$\s*([\d.,]+)(?:\s+a\s+(.+))?',
    caseSensitive: false,
  );

  @override
  ParsedBankTransaction? parse(RawBankNotification notification) {
    final text = notification.bigText.isNotEmpty
        ? notification.bigText
        : notification.text;

    var match = _pagastePattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.expense,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    match = _recibistePattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.income,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    match = _retirastePattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.expense,
        match.group(1)!,
        'Retiro Nequi',
        text,
      );
    }

    match = _enviastePattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.transfer,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    return null;
  }

  ParsedBankTransaction? _buildTransaction(
    RawBankNotification notification,
    NotificationTransactionType type,
    String amountStr,
    String? merchant,
    String rawText,
  ) {
    final amount = parseAmount(amountStr);
    if (amount == null || amount <= 0) return null;

    return ParsedBankTransaction(
      notificationId: notification.id,
      bank: bank,
      type: type,
      amount: amount,
      timestamp: notification.timestamp,
      merchant: merchant,
      rawText: rawText,
    );
  }
}

/// Parser para DaviPlata
class DaviPlataParser extends BankNotificationParser {
  @override
  ColombianBank get bank => ColombianBank.daviplata;

  // Patrones de DaviPlata:
  // "Pago exitoso por $35.000 en ALMACENES EXITO"
  // "Retiro por $100.000"
  // "Recibiste $200.000 de 3001234567"
  // "Enviaste $50.000 a 3009876543"

  static final _pagoPattern = RegExp(
    r'Pago.*?\$\s*([\d.,]+)(?:.*?en\s+(.+))?',
    caseSensitive: false,
  );

  static final _retiroPattern = RegExp(
    r'Retiro.*?\$\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _recibistePattern = RegExp(
    r'Recibiste\s+\$\s*([\d.,]+)(?:\s+de\s+(.+))?',
    caseSensitive: false,
  );

  static final _enviastePattern = RegExp(
    r'Enviaste\s+\$\s*([\d.,]+)(?:\s+a\s+(.+))?',
    caseSensitive: false,
  );

  @override
  ParsedBankTransaction? parse(RawBankNotification notification) {
    final text = notification.bigText.isNotEmpty
        ? notification.bigText
        : notification.text;

    var match = _pagoPattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.expense,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    match = _retiroPattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.expense,
        match.group(1)!,
        'Retiro DaviPlata',
        text,
      );
    }

    match = _recibistePattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.income,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    match = _enviastePattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.transfer,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    return null;
  }

  ParsedBankTransaction? _buildTransaction(
    RawBankNotification notification,
    NotificationTransactionType type,
    String amountStr,
    String? merchant,
    String rawText,
  ) {
    final amount = parseAmount(amountStr);
    if (amount == null || amount <= 0) return null;

    return ParsedBankTransaction(
      notificationId: notification.id,
      bank: bank,
      type: type,
      amount: amount,
      timestamp: notification.timestamp,
      merchant: merchant,
      rawText: rawText,
    );
  }
}

/// Parser para Davivienda
class DaviviendaParser extends BankNotificationParser {
  @override
  ColombianBank get bank => ColombianBank.davivienda;

  // Patrones de Davivienda:
  // "Compra aprobada $45.000 EXITO TC *1234"
  // "Retiro aprobado $200.000 cajero"
  // "Transferencia recibida $100.000"
  // "Transferencia enviada $50.000"

  static final _compraPattern = RegExp(
    r'Compra\s+aprobada\s+\$\s*([\d.,]+)\s+(.+?)(?:\s+TC|\s+\*|$)',
    caseSensitive: false,
  );

  static final _retiroPattern = RegExp(
    r'Retiro\s+aprobado\s+\$\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _transferenciaRecibidaPattern = RegExp(
    r'Transferencia\s+recibida\s+\$\s*([\d.,]+)',
    caseSensitive: false,
  );

  static final _transferenciaEnviadaPattern = RegExp(
    r'Transferencia\s+enviada\s+\$\s*([\d.,]+)',
    caseSensitive: false,
  );

  @override
  ParsedBankTransaction? parse(RawBankNotification notification) {
    final text = notification.bigText.isNotEmpty
        ? notification.bigText
        : notification.text;

    var match = _compraPattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.expense,
        match.group(1)!,
        match.group(2)?.trim(),
        text,
      );
    }

    match = _retiroPattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.expense,
        match.group(1)!,
        'Retiro Davivienda',
        text,
      );
    }

    match = _transferenciaRecibidaPattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.income,
        match.group(1)!,
        null,
        text,
      );
    }

    match = _transferenciaEnviadaPattern.firstMatch(text);
    if (match != null) {
      return _buildTransaction(
        notification,
        NotificationTransactionType.transfer,
        match.group(1)!,
        null,
        text,
      );
    }

    return null;
  }

  ParsedBankTransaction? _buildTransaction(
    RawBankNotification notification,
    NotificationTransactionType type,
    String amountStr,
    String? merchant,
    String rawText,
  ) {
    final amount = parseAmount(amountStr);
    if (amount == null || amount <= 0) return null;

    return ParsedBankTransaction(
      notificationId: notification.id,
      bank: bank,
      type: type,
      amount: amount,
      timestamp: notification.timestamp,
      merchant: merchant,
      accountLastDigits: extractAccountDigits(rawText),
      rawText: rawText,
    );
  }
}

/// Coordinador que usa todos los parsers
class BankNotificationParserCoordinator {
  final List<BankNotificationParser> _parsers = [
    BancolombiaParser(),
    NequiParser(),
    DaviPlataParser(),
    DaviviendaParser(),
  ];

  /// Parsea una notificación usando el parser apropiado
  ParsedBankTransaction? parse(RawBankNotification notification) {
    final bank = ColombianBank.fromPackage(notification.packageName);
    if (bank == ColombianBank.unknown) return null;

    final parser = _parsers.firstWhere(
      (p) => p.bank == bank,
      orElse: () => _parsers.first,
    );

    return parser.parse(notification);
  }

  /// Verifica si un package name es de un banco soportado
  bool isSupportedBank(String packageName) {
    return ColombianBank.fromPackage(packageName) != ColombianBank.unknown;
  }
}
