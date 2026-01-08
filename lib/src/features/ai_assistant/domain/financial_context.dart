/// Contexto financiero anónimo para enviar al AI
/// Solo contiene datos agregados, nunca transacciones individuales
class FinancialContext {
  final String period;
  final FinancialSummary summary;
  final Map<String, CategoryExpense> expensesByCategory;
  final List<AccountSummary> accounts;
  final String currency;

  FinancialContext({
    required this.period,
    required this.summary,
    required this.expensesByCategory,
    required this.accounts,
    this.currency = 'COP',
  });

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'summary': summary.toJson(),
      'expenses_by_category': expensesByCategory.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'accounts': accounts.map((a) => a.toJson()).toList(),
      'currency': currency,
    };
  }

  /// Crea un contexto vacío/demo
  factory FinancialContext.empty() {
    return FinancialContext(
      period: _currentPeriod(),
      summary: FinancialSummary(
        totalIncome: 0,
        totalExpenses: 0,
        balance: 0,
      ),
      expensesByCategory: {},
      accounts: [],
    );
  }

  /// Crea un contexto demo para pruebas
  factory FinancialContext.demo() {
    return FinancialContext(
      period: _currentPeriod(),
      summary: FinancialSummary(
        totalIncome: 5200000,
        totalExpenses: 3800000,
        balance: 1400000,
      ),
      expensesByCategory: {
        'Alimentación': CategoryExpense(
          total: 1200000,
          subcategories: {
            'Mercado': 800000,
            'Restaurantes': 300000,
            'Domicilios': 100000,
          },
        ),
        'Transporte': CategoryExpense(
          total: 450000,
          subcategories: {
            'Gasolina': 350000,
            'Mantenimiento': 100000,
          },
        ),
        'Servicios': CategoryExpense(
          total: 380000,
          subcategories: {
            'EDEQ': 150000,
            'Internet': 120000,
            'EPA': 60000,
            'EfiGas': 50000,
          },
        ),
        'Entretenimiento': CategoryExpense(
          total: 250000,
          subcategories: {
            'Cine': 80000,
            'Streaming': 70000,
            'Otros': 100000,
          },
        ),
      },
      accounts: [
        AccountSummary(name: 'Nequi', type: 'digital_wallet', balance: 450000),
        AccountSummary(name: 'Efectivo', type: 'cash', balance: 120000),
        AccountSummary(name: 'Bancolombia', type: 'bank', balance: 830000),
      ],
    );
  }

  static String _currentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}

class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double balance;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_income': totalIncome,
      'total_expenses': totalExpenses,
      'balance': balance,
    };
  }
}

class CategoryExpense {
  final double total;
  final Map<String, double>? subcategories;

  CategoryExpense({
    required this.total,
    this.subcategories,
  });

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      if (subcategories != null) 'subcategories': subcategories,
    };
  }
}

class AccountSummary {
  final String name;
  final String type;
  final double balance;

  AccountSummary({
    required this.name,
    required this.type,
    required this.balance,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
    };
  }
}
