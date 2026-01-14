import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/data/parsers/bank_notification_parser.dart';
import 'package:finanzas_familiares/domain/entities/notifications/bank_notification.dart';

void main() {
  group('ColombianBank', () {
    test('detecta Bancolombia desde package name', () {
      expect(
        ColombianBank.fromPackage('com.bancolombia.personas'),
        ColombianBank.bancolombia,
      );
      expect(
        ColombianBank.fromPackage('co.com.bancolombia.personas'),
        ColombianBank.bancolombia,
      );
    });

    test('detecta Nequi desde package name', () {
      expect(
        ColombianBank.fromPackage('com.nequi.MobileApp'),
        ColombianBank.nequi,
      );
      expect(
        ColombianBank.fromPackage('com.nequi'),
        ColombianBank.nequi,
      );
    });

    test('detecta DaviPlata desde package name', () {
      expect(
        ColombianBank.fromPackage('com.davivienda.daviplataapp'),
        ColombianBank.daviplata,
      );
      expect(
        ColombianBank.fromPackage('co.com.davivienda.daviplata'),
        ColombianBank.daviplata,
      );
    });

    test('detecta Davivienda desde package name', () {
      expect(
        ColombianBank.fromPackage('com.davivienda.personas'),
        ColombianBank.davivienda,
      );
    });

    test('retorna unknown para package desconocido', () {
      expect(
        ColombianBank.fromPackage('com.otro.banco'),
        ColombianBank.unknown,
      );
    });
  });

  group('BancolombiaParser', () {
    late BancolombiaParser parser;

    setUp(() {
      parser = BancolombiaParser();
    });

    RawBankNotification createNotification(String text) {
      return RawBankNotification(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        packageName: 'com.bancolombia.personas',
        title: 'Bancolombia',
        text: text,
        bigText: text,
        timestamp: DateTime.now(),
      );
    }

    test('parsea compra exitosamente', () {
      final notification = createNotification(
        'Compra por \$45.000 en EXITO COLOMBIA. Cuenta *1234. 15/01/26 10:30',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 45000);
      expect(result.merchant, 'EXITO COLOMBIA');
      expect(result.accountLastDigits, '1234');
    });

    test('parsea compra con monto con decimales', () {
      final notification = createNotification(
        'Compra por \$123.456 en ALMACENES EXITO',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.amount, 123456);
    });

    test('parsea pago PSE', () {
      final notification = createNotification(
        'Pago PSE por \$89.900 en NETFLIX',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 89900);
      expect(result.merchant, 'NETFLIX');
    });

    test('parsea retiro', () {
      final notification = createNotification(
        'Retiro por \$200.000 en cajero. Cuenta *5678',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 200000);
    });

    test('parsea transferencia recibida', () {
      final notification = createNotification(
        'Transferencia recibida por \$500.000 de JUAN PEREZ',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.income);
      expect(result.amount, 500000);
      expect(result.merchant, 'JUAN PEREZ');
    });

    test('parsea transferencia enviada', () {
      final notification = createNotification(
        'Transferencia enviada por \$100.000 a MARIA GARCIA',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.transfer);
      expect(result.amount, 100000);
      expect(result.merchant, 'MARIA GARCIA');
    });

    test('retorna null para notificación no reconocida', () {
      final notification = createNotification(
        'Tu saldo disponible es \$1.000.000',
      );

      final result = parser.parse(notification);

      expect(result, isNull);
    });
  });

  group('NequiParser', () {
    late NequiParser parser;

    setUp(() {
      parser = NequiParser();
    });

    RawBankNotification createNotification(String text) {
      return RawBankNotification(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        packageName: 'com.nequi.MobileApp',
        title: 'Nequi',
        text: text,
        bigText: text,
        timestamp: DateTime.now(),
      );
    }

    test('parsea pago exitosamente', () {
      final notification = createNotification('Pagaste \$45.000 a RAPPI');

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 45000);
      expect(result.merchant, 'RAPPI');
    });

    test('parsea recepción de dinero', () {
      final notification = createNotification(
        'Recibiste \$100.000 de Juan Perez',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.income);
      expect(result.amount, 100000);
      expect(result.merchant, 'Juan Perez');
    });

    test('parsea retiro', () {
      final notification = createNotification('Retiraste \$50.000');

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 50000);
      expect(result.merchant, 'Retiro Nequi');
    });

    test('parsea envío de dinero', () {
      final notification = createNotification(
        'Enviaste \$30.000 a Maria Garcia',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.transfer);
      expect(result.amount, 30000);
      expect(result.merchant, 'Maria Garcia');
    });

    test('parsea pago sin destinatario', () {
      final notification = createNotification('Pagaste \$15.000');

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 15000);
      expect(result.merchant, isNull);
    });
  });

  group('DaviPlataParser', () {
    late DaviPlataParser parser;

    setUp(() {
      parser = DaviPlataParser();
    });

    RawBankNotification createNotification(String text) {
      return RawBankNotification(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        packageName: 'com.davivienda.daviplataapp',
        title: 'DaviPlata',
        text: text,
        bigText: text,
        timestamp: DateTime.now(),
      );
    }

    test('parsea pago exitoso', () {
      final notification = createNotification(
        'Pago exitoso por \$35.000 en ALMACENES EXITO',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 35000);
      expect(result.merchant, 'ALMACENES EXITO');
    });

    test('parsea retiro', () {
      final notification = createNotification('Retiro por \$100.000');

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 100000);
    });

    test('parsea recepción', () {
      final notification = createNotification(
        'Recibiste \$200.000 de 3001234567',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.income);
      expect(result.amount, 200000);
    });

    test('parsea envío', () {
      final notification = createNotification(
        'Enviaste \$50.000 a 3009876543',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.transfer);
      expect(result.amount, 50000);
    });
  });

  group('DaviviendaParser', () {
    late DaviviendaParser parser;

    setUp(() {
      parser = DaviviendaParser();
    });

    RawBankNotification createNotification(String text) {
      return RawBankNotification(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        packageName: 'com.davivienda.personas',
        title: 'Davivienda',
        text: text,
        bigText: text,
        timestamp: DateTime.now(),
      );
    }

    test('parsea compra aprobada', () {
      final notification = createNotification(
        'Compra aprobada \$45.000 EXITO TC *1234',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 45000);
      expect(result.merchant, 'EXITO');
      expect(result.accountLastDigits, '1234');
    });

    test('parsea retiro aprobado', () {
      final notification = createNotification(
        'Retiro aprobado \$200.000 cajero',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.expense);
      expect(result.amount, 200000);
    });

    test('parsea transferencia recibida', () {
      final notification = createNotification(
        'Transferencia recibida \$100.000',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.income);
      expect(result.amount, 100000);
    });

    test('parsea transferencia enviada', () {
      final notification = createNotification(
        'Transferencia enviada \$50.000',
      );

      final result = parser.parse(notification);

      expect(result, isNotNull);
      expect(result!.type, NotificationTransactionType.transfer);
      expect(result.amount, 50000);
    });
  });

  group('BankNotificationParserCoordinator', () {
    late BankNotificationParserCoordinator coordinator;

    setUp(() {
      coordinator = BankNotificationParserCoordinator();
    });

    test('usa parser correcto según package name', () {
      final bancolombiaNotification = RawBankNotification(
        id: 'test_1',
        packageName: 'com.bancolombia.personas',
        title: 'Bancolombia',
        text: 'Compra por \$50.000 en EXITO',
        bigText: 'Compra por \$50.000 en EXITO',
        timestamp: DateTime.now(),
      );

      final result = coordinator.parse(bancolombiaNotification);

      expect(result, isNotNull);
      expect(result!.bank, ColombianBank.bancolombia);
    });

    test('retorna null para banco no soportado', () {
      final unknownNotification = RawBankNotification(
        id: 'test_2',
        packageName: 'com.otro.banco',
        title: 'Otro Banco',
        text: 'Compra por \$50.000',
        bigText: 'Compra por \$50.000',
        timestamp: DateTime.now(),
      );

      final result = coordinator.parse(unknownNotification);

      expect(result, isNull);
    });

    test('isSupportedBank detecta bancos conocidos', () {
      expect(coordinator.isSupportedBank('com.bancolombia.personas'), isTrue);
      expect(coordinator.isSupportedBank('com.nequi.MobileApp'), isTrue);
      expect(coordinator.isSupportedBank('com.davivienda.daviplataapp'), isTrue);
      expect(coordinator.isSupportedBank('com.davivienda.personas'), isTrue);
      expect(coordinator.isSupportedBank('com.otro.app'), isFalse);
    });
  });

  group('BankNotificationParser - parseAmount', () {
    late BancolombiaParser parser;

    setUp(() {
      parser = BancolombiaParser();
    });

    test('parsea monto con separador de miles', () {
      expect(parser.parseAmount('\$45.000'), 45000);
      expect(parser.parseAmount('\$1.234.567'), 1234567);
    });

    test('parsea monto sin separador', () {
      expect(parser.parseAmount('\$45000'), 45000);
      expect(parser.parseAmount('45000'), 45000);
    });

    test('parsea monto con decimales', () {
      expect(parser.parseAmount('\$45.000,50'), 45000.50);
    });

    test('retorna null para texto sin números', () {
      expect(parser.parseAmount('sin monto'), isNull);
      expect(parser.parseAmount(''), isNull);
    });
  });

  group('BankNotificationParser - extractAccountDigits', () {
    late BancolombiaParser parser;

    setUp(() {
      parser = BancolombiaParser();
    });

    test('extrae dígitos con asterisco', () {
      expect(parser.extractAccountDigits('Cuenta *1234'), '1234');
      expect(parser.extractAccountDigits('TC ****5678'), '5678');
    });

    test('extrae dígitos con palabra cuenta', () {
      expect(parser.extractAccountDigits('cuenta 9012'), '9012');
    });

    test('retorna null si no encuentra patrón', () {
      expect(parser.extractAccountDigits('Sin cuenta'), isNull);
    });
  });
}
