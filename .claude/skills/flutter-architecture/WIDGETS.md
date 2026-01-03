# Widgets Reutilizables

## Estructura de Widgets

```
lib/shared/widgets/
├── buttons/
│   ├── primary_button.dart
│   └── icon_button.dart
├── cards/
│   ├── info_card.dart
│   └── stat_card.dart
├── inputs/
│   ├── currency_input.dart
│   └── date_picker.dart
└── feedback/
    ├── loading_overlay.dart
    └── empty_state.dart
```

## Widgets Principales

### 1. CurrencyInput

```dart
class CurrencyInput extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final String? label;
  final String? Function(String?)? validator;

  const CurrencyInput({
    required this.controller,
    this.currency = 'MXN',
    this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label ?? 'Monto',
        prefixText: '\$ ',
        suffixText: currency,
      ),
      validator: validator ?? (v) {
        if (v == null || v.isEmpty) return 'Ingresa un monto';
        final amount = double.tryParse(v);
        if (amount == null || amount < 0) return 'Monto invalido';
        return null;
      },
    );
  }
}
```

### 2. StatCard

```dart
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color ?? theme.primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 3. EmptyState

```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 4. LoadingOverlay

```dart
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

### 5. AccountCard

```dart
class AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback? onTap;

  const AccountCard({required this.account, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(account.color.replaceFirst('#', '0xFF'))),
          child: Icon(
            _getIconData(account.icon),
            color: Colors.white,
          ),
        ),
        title: Text(account.name),
        subtitle: Text(account.type.displayName),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(account.balance, account.currency),
              style: theme.textTheme.titleMedium?.copyWith(
                color: account.balance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (account.type == AccountType.credit && account.creditLimit != null)
              Text(
                'Disponible: ${formatCurrency(account.availableBalance, account.currency)}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
```

## Patrones de Composicion

### ConsumerWidget vs StatelessWidget

```dart
// Usar ConsumerWidget cuando necesitas ref
class AccountsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsProvider);
    // ...
  }
}

// Usar StatelessWidget para widgets puros
class AccountCard extends StatelessWidget {
  final AccountModel account;
  // ...
}
```

### Separacion de Responsabilidades

```dart
// Screen: Layout y navegacion
class TransactionsScreen extends ConsumerWidget {
  Widget build(context, ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Movimientos')),
      body: TransactionsList(),
      floatingActionButton: AddTransactionFAB(),
    );
  }
}

// Widget: Logica de UI
class TransactionsList extends ConsumerWidget {
  Widget build(context, ref) {
    final transactions = ref.watch(transactionsProvider).transactions;
    if (transactions.isEmpty) return EmptyState(...);
    return ListView.builder(...);
  }
}

// Widget puro: Solo presentacion
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  // ...
}
```
