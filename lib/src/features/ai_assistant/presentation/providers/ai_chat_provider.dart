import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_repository.dart';
import '../../domain/chat_message.dart';
import '../../domain/financial_context.dart';

/// Provider del repositorio de AI
final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepository();
});

/// Provider del contexto financiero actual
/// TODO: Conectar con datos reales de PowerSync
final financialContextProvider = Provider<FinancialContext>((ref) {
  // Por ahora usamos datos demo
  return FinancialContext.demo();
});

/// Estado del chat
class AIChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isOnline;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isOnline = true,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isOnline,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Notifier del chat
class AIChatNotifier extends StateNotifier<AIChatState> {
  final AIRepository _repository;
  final FinancialContext _context;

  AIChatNotifier(this._repository, this._context)
      : super(AIChatState(messages: [ChatMessage.welcome()])) {
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final isOnline = !result.contains(ConnectivityResult.none);
    state = state.copyWith(isOnline: isOnline);

    // Escuchar cambios de conectividad
    Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      state = state.copyWith(isOnline: online);
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Agregar mensaje del usuario
    final userMessage = ChatMessage.user(text);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      String response;

      if (state.isOnline) {
        // Intentar con el servicio real
        try {
          response = await _repository.sendMessage(
            message: text,
            context: _context,
            conversationHistory: state.messages,
          );
        } catch (e) {
          // Si falla, usar respuesta demo
          response = _repository.getDemoResponse(text);
        }
      } else {
        // Sin conexión, usar respuesta demo
        response = _repository.getDemoResponse(text);
      }

      final assistantMessage = ChatMessage.assistant(response);
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      final errorMessage = ChatMessage.error(
        'No pude procesar tu mensaje. Por favor, intenta de nuevo.',
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  void clearChat() {
    state = AIChatState(
      messages: [ChatMessage.welcome()],
      isOnline: state.isOnline,
    );
  }
}

/// Provider del chat
final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  final repository = ref.watch(aiRepositoryProvider);
  final context = ref.watch(financialContextProvider);
  return AIChatNotifier(repository, context);
});

/// Provider de mensajes (convenience)
final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(aiChatProvider).messages;
});

/// Provider de estado de carga
final isChatLoadingProvider = Provider<bool>((ref) {
  return ref.watch(aiChatProvider).isLoading;
});

/// Provider de conectividad
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(aiChatProvider).isOnline;
});
