import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/mappers/financial_context_mappers.dart';
import '../../domain/entities/financial_context.dart';
import '../../domain/services/ai_assistant_service.dart';
import '../../domain/services/financial_context_builder.dart';
import 'database_provider.dart';

part 'ai_assistant_provider.g.dart';

/// Provider del servicio de asistente IA
@Riverpod(keepAlive: true)
AIAssistantService aiAssistantService(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return AIAssistantService(client);
}

/// Provider del constructor de contexto financiero
@riverpod
FinancialContextBuilder financialContextBuilder(Ref ref) {
  return const FinancialContextBuilder();
}

/// Provider del contexto financiero actual
@riverpod
Future<FinancialContext> currentFinancialContext(Ref ref) async {
  final builder = ref.watch(financialContextBuilderProvider);
  final transactionsDao = ref.watch(transactionsDaoProvider);
  final categoriesDao = ref.watch(categoriesDaoProvider);
  final accountsDao = ref.watch(accountsDaoProvider);

  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // Obtener datos en paralelo
  final transactionsFuture = transactionsDao.getTransactionsInPeriod(startDate, endDate);
  final categoriesFuture = categoriesDao.getAllCategories();
  final accountsFuture = accountsDao.getActiveAccounts();

  final transactions = await transactionsFuture;
  final categories = await categoriesFuture;
  final accounts = await accountsFuture;

  // Convertir a DTOs y construir contexto
  return builder.buildContext(
    year: now.year,
    month: now.month,
    transactions: FinancialContextMappers.transactionsToDtoList(transactions),
    categories: FinancialContextMappers.categoriesToDtoList(categories),
    accounts: FinancialContextMappers.accountsToDtoList(accounts),
  );
}

/// Estado del chat con el asistente
@riverpod
class AIChatNotifier extends _$AIChatNotifier {
  @override
  AIChatState build() {
    return const AIChatState();
  }

  /// Envía un mensaje al asistente
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: message,
      role: ChatRole.user,
      timestamp: DateTime.now(),
    );

    // Agregar mensaje del usuario y placeholder de respuesta
    final assistantPlaceholder = ChatMessage(
      id: const Uuid().v4(),
      content: '',
      role: ChatRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, assistantPlaceholder],
      isLoading: true,
      error: null,
    );

    try {
      final service = ref.read(aiAssistantServiceProvider);
      final context = await ref.read(currentFinancialContextProvider.future);

      final response = await service.sendMessage(
        message: message,
        context: context,
        conversationHistory: state.messages
            .where((m) => !m.isLoading)
            .toList(),
      );

      // Actualizar con respuesta real
      final updatedMessages = state.messages.map((m) {
        if (m.id == assistantPlaceholder.id) {
          return m.copyWith(
            content: response,
            isLoading: false,
          );
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
      );
    } on AIAssistantException catch (e) {
      // Actualizar placeholder con error
      final updatedMessages = state.messages.map((m) {
        if (m.id == assistantPlaceholder.id) {
          return m.copyWith(
            content: _getErrorMessage(e),
            isLoading: false,
            error: e.message,
          );
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      // Actualizar placeholder con error genérico
      final updatedMessages = state.messages.map((m) {
        if (m.id == assistantPlaceholder.id) {
          return m.copyWith(
            content: 'Lo siento, ocurrió un error inesperado. Por favor, intenta de nuevo.',
            isLoading: false,
            error: e.toString(),
          );
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  String _getErrorMessage(AIAssistantException e) {
    if (e.isNetworkError) {
      return 'No puedo conectarme al servidor. Verifica tu conexión a internet.';
    }
    if (e.isAuthError) {
      return 'No tienes autorización para usar el asistente. Por favor, inicia sesión.';
    }
    if (e.isRateLimitError) {
      return 'Has realizado muchas consultas. Por favor, espera un momento.';
    }
    return 'Lo siento, ocurrió un error: ${e.message}';
  }

  /// Limpia el historial de chat
  void clearChat() {
    state = const AIChatState();
  }

  /// Reintenta el último mensaje
  Future<void> retryLastMessage() async {
    if (state.messages.isEmpty) return;

    // Encontrar el último mensaje del usuario
    final lastUserMessage = state.messages
        .lastWhere((m) => m.role == ChatRole.user, orElse: () => state.messages.last);

    // Eliminar la respuesta con error
    final messagesWithoutError = state.messages
        .where((m) => m.role == ChatRole.user || m.error == null)
        .toList();

    if (messagesWithoutError.isNotEmpty && messagesWithoutError.last.role == ChatRole.user) {
      messagesWithoutError.removeLast();
    }

    state = state.copyWith(
      messages: messagesWithoutError,
      error: null,
    );

    await sendMessage(lastUserMessage.content);
  }
}

/// Estado del chat con el asistente IA
class AIChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
