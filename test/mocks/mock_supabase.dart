// test/mocks/mock_supabase.dart

import 'dart:async';

/// Mock de User para tests
class MockSupabaseUser {
  final String id;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final Map<String, dynamic>? userMetadata;

  MockSupabaseUser({
    this.id = 'test-user-123',
    this.email = 'test@finanzasfamiliares.com',
    this.phone,
    DateTime? createdAt,
    this.userMetadata,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Mock de Session para tests
class MockSupabaseSession {
  final String accessToken;
  final String refreshToken;
  final MockSupabaseUser user;
  final DateTime expiresAt;

  MockSupabaseSession({
    this.accessToken = 'mock-access-token',
    this.refreshToken = 'mock-refresh-token',
    MockSupabaseUser? user,
    DateTime? expiresAt,
  })  : user = user ?? MockSupabaseUser(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 1));

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Mock de AuthState para tests
enum MockAuthChangeEvent {
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
  passwordRecovery,
}

class MockAuthState {
  final MockAuthChangeEvent event;
  final MockSupabaseSession? session;

  MockAuthState(this.event, this.session);
}

/// Controlador de Auth mock para tests
class MockSupabaseAuth {
  MockSupabaseUser? _currentUser;
  MockSupabaseSession? _currentSession;
  final _authStateController = StreamController<MockAuthState>.broadcast();

  MockSupabaseUser? get currentUser => _currentUser;
  MockSupabaseSession? get currentSession => _currentSession;
  Stream<MockAuthState> get onAuthStateChange => _authStateController.stream;

  /// Simular login exitoso
  Future<MockSupabaseSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    _currentUser = MockSupabaseUser(email: email);
    _currentSession = MockSupabaseSession(user: _currentUser);

    _authStateController.add(MockAuthState(
      MockAuthChangeEvent.signedIn,
      _currentSession,
    ));

    return _currentSession!;
  }

  /// Simular login con Google
  Future<MockSupabaseSession> signInWithOAuth(String provider) async {
    await Future.delayed(const Duration(milliseconds: 100));

    _currentUser = MockSupabaseUser(email: 'oauth@test.com');
    _currentSession = MockSupabaseSession(user: _currentUser);

    _authStateController.add(MockAuthState(
      MockAuthChangeEvent.signedIn,
      _currentSession,
    ));

    return _currentSession!;
  }

  /// Simular logout
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 50));

    _currentUser = null;
    _currentSession = null;

    _authStateController.add(MockAuthState(
      MockAuthChangeEvent.signedOut,
      null,
    ));
  }

  /// Simular registro
  Future<MockSupabaseSession> signUp({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    _currentUser = MockSupabaseUser(email: email);
    _currentSession = MockSupabaseSession(user: _currentUser);

    _authStateController.add(MockAuthState(
      MockAuthChangeEvent.signedIn,
      _currentSession,
    ));

    return _currentSession!;
  }

  /// Simular refresh token
  Future<MockSupabaseSession> refreshSession() async {
    if (_currentSession == null) {
      throw Exception('No session to refresh');
    }

    _currentSession = MockSupabaseSession(
      user: _currentUser,
      accessToken: 'refreshed-token-${DateTime.now().millisecondsSinceEpoch}',
    );

    _authStateController.add(MockAuthState(
      MockAuthChangeEvent.tokenRefreshed,
      _currentSession,
    ));

    return _currentSession!;
  }

  /// Establecer usuario mock directamente (para setup de tests)
  void setMockUser(MockSupabaseUser? user) {
    _currentUser = user;
    if (user != null) {
      _currentSession = MockSupabaseSession(user: user);
    } else {
      _currentSession = null;
    }
  }

  void dispose() {
    _authStateController.close();
  }
}

/// Mock de Realtime para tests
class MockSupabaseRealtime {
  final Map<String, StreamController<Map<String, dynamic>>> _channels = {};

  /// Suscribirse a un canal
  Stream<Map<String, dynamic>> channel(String name) {
    _channels.putIfAbsent(
      name,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );
    return _channels[name]!.stream;
  }

  /// Simular evento de realtime (para tests)
  void simulateEvent(String channel, Map<String, dynamic> payload) {
    if (_channels.containsKey(channel)) {
      _channels[channel]!.add(payload);
    }
  }

  /// Simular insert
  void simulateInsert(String table, Map<String, dynamic> record) {
    simulateEvent('public:$table', {
      'eventType': 'INSERT',
      'new': record,
      'old': null,
    });
  }

  /// Simular update
  void simulateUpdate(
      String table, Map<String, dynamic> oldRecord, Map<String, dynamic> newRecord) {
    simulateEvent('public:$table', {
      'eventType': 'UPDATE',
      'new': newRecord,
      'old': oldRecord,
    });
  }

  /// Simular delete
  void simulateDelete(String table, Map<String, dynamic> record) {
    simulateEvent('public:$table', {
      'eventType': 'DELETE',
      'new': null,
      'old': record,
    });
  }

  void dispose() {
    for (final controller in _channels.values) {
      controller.close();
    }
    _channels.clear();
  }
}

/// Singleton global para tests
class MockSupabase {
  static final MockSupabase _instance = MockSupabase._internal();
  factory MockSupabase() => _instance;
  MockSupabase._internal();

  final auth = MockSupabaseAuth();
  final realtime = MockSupabaseRealtime();

  /// Reset para limpiar entre tests
  void reset() {
    auth.setMockUser(null);
  }

  void dispose() {
    auth.dispose();
    realtime.dispose();
  }
}
