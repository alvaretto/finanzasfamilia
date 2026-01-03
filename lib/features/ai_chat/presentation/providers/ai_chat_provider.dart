import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/chat_message.dart';
import '../../data/services/ai_chat_service.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart' show budgetsProvider;

/// Provider del servicio de IA
final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AiChatService();
});

/// Estado del chat
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier del chat
class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiChatService _service;
  final Ref _ref;

  AiChatNotifier(this._service, this._ref) : super(const AiChatState());

  /// Enviar mensaje
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Agregar mensaje del usuario
    final userMessage = ChatMessage.user(content);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Obtener datos financieros
      final transactions = _ref.read(transactionsProvider).transactions;
      final accounts = _ref.read(activeAccountsProvider);
      final budgets = _ref.read(budgetsProvider).budgets;

      // Obtener respuesta de la IA
      final response = await _service.sendMessage(
        userMessage: content,
        transactions: transactions,
        accounts: accounts,
        budgets: budgets,
      );

      // Agregar respuesta
      final assistantMessage = ChatMessage.assistant(response);
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Limpiar chat
  void clearChat() {
    state = const AiChatState();
  }

  /// Obtener sugerencias
  List<String> getSuggestions() {
    return _service.getSuggestions();
  }
}

/// Provider del chat
final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final service = ref.watch(aiChatServiceProvider);
  return AiChatNotifier(service, ref);
});
