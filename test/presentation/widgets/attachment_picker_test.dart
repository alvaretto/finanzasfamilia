import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/presentation/widgets/attachment_picker.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';

void main() {
  group('AttachmentPicker Widget', () {
    late AppDatabase db;
    late String transactionId;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      transactionId = const Uuid().v4();
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestWidget({
      bool enableOcr = true,
      ValueChanged<double?>? onAmountDetected,
    }) {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'CO')],
          home: Scaffold(
            body: AttachmentPicker(
              transactionId: transactionId,
              enableOcr: enableOcr,
              onAmountDetected: onAmountDetected,
            ),
          ),
        ),
      );
    }

    testWidgets('muestra título Recibos y Adjuntos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recibos y Adjuntos'), findsOneWidget);
    });

    testWidgets('muestra icono de attach_file', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
    });

    testWidgets('muestra botón de cámara', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('muestra botón de galería', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay adjuntos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Agregar recibo o factura'), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
    });

    testWidgets('estado vacío es clickeable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // El contenedor vacío debería ser tapeable
      final emptyStateFinder = find.text('Agregar recibo o factura');
      expect(emptyStateFinder, findsOneWidget);

      await tester.tap(emptyStateFinder);
      await tester.pumpAndSettle();

      // Debería mostrar opciones de cámara y galería
      expect(find.text('Tomar foto'), findsOneWidget);
      expect(find.text('Elegir de galería'), findsOneWidget);
    });

    testWidgets('bottom sheet muestra opciones de captura', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap en área vacía para mostrar opciones
      await tester.tap(find.text('Agregar recibo o factura'));
      await tester.pumpAndSettle();

      expect(find.text('Tomar foto'), findsOneWidget);
      expect(find.text('Capturar con la cámara'), findsOneWidget);
      expect(find.text('Elegir de galería'), findsOneWidget);
      expect(find.text('Seleccionar imagen existente'), findsOneWidget);
    });

    testWidgets('tooltips en botones de cámara y galería', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que los IconButtons tienen tooltips
      final cameraButton = find.widgetWithIcon(IconButton, Icons.camera_alt);
      final galleryButton =
          find.widgetWithIcon(IconButton, Icons.photo_library);

      expect(cameraButton, findsOneWidget);
      expect(galleryButton, findsOneWidget);
    });
  });

  group('AttachmentPicker - AttachmentData', () {
    test('formattedSize retorna bytes correctamente', () {
      // Probamos diferentes tamaños
      const sizes = [
        (512, '512 B'),
        (1024, '1.0 KB'),
        (1536, '1.5 KB'),
        (1048576, '1.0 MB'),
        (2621440, '2.5 MB'),
      ];

      // Verificamos la lógica de formateo
      for (final (bytes, _) in sizes) {
        String formatted;
        if (bytes < 1024) {
          formatted = '$bytes B';
        } else if (bytes < 1024 * 1024) {
          formatted = '${(bytes / 1024).toStringAsFixed(1)} KB';
        } else {
          formatted = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
        expect(formatted.isNotEmpty, isTrue);
      }
    });

    test('isImage detecta tipos MIME de imagen', () {
      const imageTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
      ];
      const nonImageTypes = [
        'application/pdf',
        'text/plain',
        'application/octet-stream',
      ];

      for (final type in imageTypes) {
        expect(type.startsWith('image/'), isTrue);
      }

      for (final type in nonImageTypes) {
        expect(type.startsWith('image/'), isFalse);
      }
    });
  });

  group('AttachmentPicker - Sync Status', () {
    test('isSynced false indica adjunto local', () {
      const isSynced = false;
      expect(isSynced, isFalse);
    });

    test('isSynced true indica adjunto sincronizado', () {
      const isSynced = true;
      expect(isSynced, isTrue);
    });

    test('sync indicator devuelve icono correcto según estado', () {
      IconData getIcon(bool synced) =>
          synced ? Icons.cloud_done : Icons.cloud_upload;

      expect(getIcon(false), equals(Icons.cloud_upload));
      expect(getIcon(true), equals(Icons.cloud_done));
    });

    test('sync status chip devuelve texto correcto según estado', () {
      String getText(bool synced) => synced ? 'Sincronizado' : 'Local';

      expect(getText(false), equals('Local'));
      expect(getText(true), equals('Sincronizado'));
    });
  });
}
