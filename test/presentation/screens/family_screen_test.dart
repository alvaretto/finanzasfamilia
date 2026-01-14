import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:finanzas_familiares/presentation/screens/family_screen.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/domain/services/family_service.dart';
import 'package:finanzas_familiares/application/providers/family_provider.dart';

void main() {
  group('FamilyScreen Widget', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestWidget({String? userId}) {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          currentUserIdProvider.overrideWithValue('test-user-id'),
          watchUserFamiliesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('es', 'CO')],
          home: FamilyScreen(),
        ),
      );
    }

    testWidgets('muestra título Mis Familias', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mis Familias'), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay familias', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sin familias'), findsOneWidget);
      expect(
        find.text(
            'Crea una familia para compartir finanzas con tus seres queridos'),
        findsOneWidget,
      );
    });

    testWidgets('muestra botón Crear Familia en estado vacío', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Crear Familia'), findsOneWidget);
    });

    testWidgets('muestra botón Unirse con código en estado vacío',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Unirse con código'), findsOneWidget);
    });

    testWidgets('FAB muestra Nueva Familia', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nueva Familia'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('icono de unirse con código en AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.group_add), findsOneWidget);
    });

    testWidgets('tap en Crear Familia abre bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear Familia'));
      await tester.pumpAndSettle();

      expect(find.text('Nombre de la familia'), findsOneWidget);
      expect(find.text('Descripción (opcional)'), findsOneWidget);
    });

    testWidgets('bottom sheet de crear familia tiene campos correctos',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear Familia'));
      await tester.pumpAndSettle();

      expect(find.text('Icono'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Crear Familia'), findsOneWidget);
    });

    testWidgets('tap en unirse con código abre diálogo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.group_add));
      await tester.pumpAndSettle();

      expect(find.text('Unirse a Familia'), findsOneWidget);
      expect(find.text('Código'), findsOneWidget);
    });

    testWidgets('diálogo de unirse tiene campo de código', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.group_add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.key), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Unirse'), findsOneWidget);
    });

    testWidgets('muestra icono de familia en estado vacío', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.family_restroom), findsOneWidget);
    });
  });

  group('FamilyScreen - CreateFamilySheet', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          currentUserIdProvider.overrideWithValue('test-user-id'),
          watchUserFamiliesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('es', 'CO')],
          home: FamilyScreen(),
        ),
      );
    }

    testWidgets('validación de nombre vacío', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear Familia'));
      await tester.pumpAndSettle();

      // Intentar crear sin nombre
      await tester.tap(find.widgetWithText(FilledButton, 'Crear Familia'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un nombre'), findsOneWidget);
    });

    testWidgets('selector de iconos está presente', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear Familia'));
      await tester.pumpAndSettle();

      // Verificar que hay opciones de iconos (emojis de familia)
      expect(find.text('👨‍👩‍👧‍👦'), findsOneWidget);
      expect(find.text('🏠'), findsOneWidget);
    });

    testWidgets('selector de colores está presente', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear Familia'));
      await tester.pumpAndSettle();

      expect(find.text('Color'), findsOneWidget);
      // Los colores se muestran como círculos, no como texto
    });
  });

  group('FamilyWithMembersData Model', () {
    test('isOwner retorna true para role owner', () {
      final familyData = FamilyWithMembersData(
        family: _createMockFamily(),
        members: [],
        currentUserMember: _createMockMember(role: 'owner'),
      );

      expect(familyData.isOwner, isTrue);
    });

    test('isOwner retorna false para role member', () {
      final familyData = FamilyWithMembersData(
        family: _createMockFamily(),
        members: [],
        currentUserMember: _createMockMember(role: 'member'),
      );

      expect(familyData.isOwner, isFalse);
    });

    test('isAdmin retorna true para owner y admin', () {
      final ownerData = FamilyWithMembersData(
        family: _createMockFamily(),
        members: [],
        currentUserMember: _createMockMember(role: 'owner'),
      );

      final adminData = FamilyWithMembersData(
        family: _createMockFamily(),
        members: [],
        currentUserMember: _createMockMember(role: 'admin'),
      );

      expect(ownerData.isAdmin, isTrue);
      expect(adminData.isAdmin, isTrue);
    });

    test('isAdmin retorna false para member y viewer', () {
      final memberData = FamilyWithMembersData(
        family: _createMockFamily(),
        members: [],
        currentUserMember: _createMockMember(role: 'member'),
      );

      final viewerData = FamilyWithMembersData(
        family: _createMockFamily(),
        members: [],
        currentUserMember: _createMockMember(role: 'viewer'),
      );

      expect(memberData.isAdmin, isFalse);
      expect(viewerData.isAdmin, isFalse);
    });

    test('memberCount retorna cantidad correcta', () {
      final familyData = FamilyWithMembersData(
        family: _createMockFamily(),
        members: [
          _createMockMember(role: 'owner'),
          _createMockMember(role: 'admin'),
          _createMockMember(role: 'member'),
        ],
        currentUserMember: _createMockMember(role: 'owner'),
      );

      expect(familyData.memberCount, equals(3));
    });

    test('canInvite es igual a isAdmin', () {
      final adminData = FamilyWithMembersData(
        family: _createMockFamily(),
        members: [],
        currentUserMember: _createMockMember(role: 'admin'),
      );

      final memberData = FamilyWithMembersData(
        family: _createMockFamily(),
        members: [],
        currentUserMember: _createMockMember(role: 'member'),
      );

      expect(adminData.canInvite, isTrue);
      expect(memberData.canInvite, isFalse);
    });
  });
}

// Helpers para crear datos mock usando tipos de dominio
FamilyData _createMockFamily({
  String? id,
  String name = 'Test Family',
}) {
  return FamilyData(
    id: id ?? 'family-id',
    name: name,
    description: null,
    icon: '👨‍👩‍👧‍👦',
    color: '#4CAF50',
    ownerId: 'owner-id',
    inviteCode: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

FamilyMemberData _createMockMember({
  String? id,
  String role = 'member',
}) {
  return FamilyMemberData(
    id: id ?? 'member-id',
    familyId: 'family-id',
    userId: 'user-id',
    role: role,
    isActive: true,
    joinedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
