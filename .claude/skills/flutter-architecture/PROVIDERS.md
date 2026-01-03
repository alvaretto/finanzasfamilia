# Patrones de Providers (Riverpod)

## 1. StateNotifierProvider (Principal)

Usado para estado mutable complejo:

```dart
class AccountsState {
  final List<AccountModel> accounts;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;

  const AccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
  });

  AccountsState copyWith({
    List<AccountModel>? accounts,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage, // Permite null para limpiar
    );
  }

  // Computed properties
  double get totalBalance => accounts.fold(0, (sum, a) => sum + a.balance);
  List<AccountModel> get bankAccounts => accounts.where((a) => a.type == AccountType.bank).toList();
}

class AccountsNotifier extends StateNotifier<AccountsState> {
  final AccountRepository _repository;
  final String? _userId;
  StreamSubscription? _subscription;

  AccountsNotifier(this._repository, this._userId)
    : super(const AccountsState(isLoading: true)) {
    if (_userId != null) {
      _init();
    } else {
      state = const AccountsState(isLoading: false);
    }
  }

  void _init() {
    _subscription = _repository.watchAll(_userId!).listen(
      (accounts) {
        state = state.copyWith(accounts: accounts, isLoading: false);
      },
      onError: (e) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
      },
    );
  }

  Future<bool> create(AccountModel account) async {
    try {
      await _repository.create(account);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, AccountsState>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  final auth = ref.watch(authProvider);
  return AccountsNotifier(repo, auth.user?.id);
});
```

## 2. Provider (Valores derivados)

Para valores computados de otros providers:

```dart
// Total balance de todas las cuentas
final totalBalanceProvider = Provider<double>((ref) {
  return ref.watch(accountsProvider).totalBalance;
});

// Cuentas filtradas por tipo
final bankAccountsProvider = Provider<List<AccountModel>>((ref) {
  return ref.watch(accountsProvider).bankAccounts;
});

// Combinando multiples providers
final financialSummaryProvider = Provider<FinancialSummary>((ref) {
  final accounts = ref.watch(accountsProvider).accounts;
  final transactions = ref.watch(transactionsProvider).transactions;
  final budgets = ref.watch(budgetsProvider).budgets;

  return FinancialSummary(
    netWorth: calculateNetWorth(accounts),
    monthlyExpenses: calculateMonthlyExpenses(transactions),
    budgetStatus: analyzeBudgets(budgets),
  );
});
```

## 3. FutureProvider (Datos asincronos)

Para datos que se obtienen una vez:

```dart
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null) return null;

  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
    .from('profiles')
    .select()
    .eq('id', auth.user!.id)
    .single();

  return UserProfile.fromJson(data);
});

// Uso en widget
Widget build(BuildContext context, WidgetRef ref) {
  final profileAsync = ref.watch(userProfileProvider);

  return profileAsync.when(
    data: (profile) => ProfileCard(profile: profile),
    loading: () => const CircularProgressIndicator(),
    error: (e, _) => ErrorWidget(e.toString()),
  );
}
```

## 4. StreamProvider (Datos reactivos)

Para streams de datos:

```dart
final realtimeTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.user == null) return Stream.value([]);

  final supabase = ref.watch(supabaseProvider);
  return supabase
    .from('transactions')
    .stream(primaryKey: ['id'])
    .eq('user_id', auth.user!.id)
    .map((data) => data.map(Transaction.fromJson).toList());
});
```

## 5. Family Providers (Parametrizados)

Para providers que necesitan parametros:

```dart
// Provider por ID
final accountByIdProvider = Provider.family<AccountModel?, String>((ref, id) {
  return ref.watch(accountsProvider).accounts.firstWhereOrNull((a) => a.id == id);
});

// Provider por periodo
final transactionsByPeriodProvider = Provider.family<List<Transaction>, DateRange>((ref, range) {
  return ref.watch(transactionsProvider).transactions
    .where((t) => t.date.isAfter(range.start) && t.date.isBefore(range.end))
    .toList();
});

// Uso
final account = ref.watch(accountByIdProvider('abc-123'));
final monthTx = ref.watch(transactionsByPeriodProvider(thisMonth));
```

## Dependencias entre Providers

```dart
// Auth provider es la raiz
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// Otros providers dependen de auth
final accountsProvider = StateNotifierProvider<AccountsNotifier, AccountsState>((ref) {
  final auth = ref.watch(authProvider);  // Reacciona a cambios de auth
  final repo = ref.watch(accountRepositoryProvider);
  return AccountsNotifier(repo, auth.user?.id);
});

// Providers derivados
final dashboardProvider = Provider<DashboardData>((ref) {
  // Se reconstruye cuando cualquiera de estos cambia
  final accounts = ref.watch(accountsProvider);
  final transactions = ref.watch(transactionsProvider);
  final budgets = ref.watch(budgetsProvider);
  final goals = ref.watch(goalsProvider);

  return DashboardData(
    accounts: accounts.accounts,
    recentTransactions: transactions.transactions.take(5).toList(),
    overBudgets: budgets.overBudgets,
    nearGoals: goals.upcomingDeadlines,
  );
});
```

## Uso en Widgets

```dart
class AccountsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsProvider);

    // Escuchar errores para mostrar snackbar
    ref.listen<AccountsState>(accountsProvider, (prev, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(accountsProvider.notifier).clearError();
      }
    });

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: state.accounts.length,
      itemBuilder: (_, i) => AccountCard(account: state.accounts[i]),
    );
  }
}
```
