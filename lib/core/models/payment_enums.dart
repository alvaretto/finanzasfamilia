// Enums para formas y medios de pago
// Parte del sistema de transacciones detalladas v3

/// Forma de pago: Crédito o Contado
enum PaymentMethod {
  credit('credit', 'Crédito', 'A crédito o fiado'),
  cash('cash', 'Contado', 'Pago inmediato');

  final String value;
  final String displayName;
  final String description;

  const PaymentMethod(this.value, this.displayName, this.description);

  static PaymentMethod? fromValue(String? value) {
    if (value == null) return null;
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Medio de pago específico
enum PaymentMedium {
  // === Crédito ===
  creditCard('credit_card', 'Tarjeta de Crédito', PaymentMethod.credit, 'credit_card'),
  fiado('fiado', 'Promesa verbal (Fiado)', PaymentMethod.credit, 'handshake'),

  // === Contado ===
  cashMoney('cash', 'Efectivo', PaymentMethod.cash, 'payments'),
  bankTransfer('bank_transfer', 'Transferencia Bancaria', PaymentMethod.cash, 'account_balance'),
  appTransfer('app_transfer', 'Transferencia por App', PaymentMethod.cash, 'smartphone');

  final String value;
  final String displayName;
  final PaymentMethod method;
  final String icon;

  const PaymentMedium(this.value, this.displayName, this.method, this.icon);

  /// Filtra medios de pago por forma de pago
  static List<PaymentMedium> forMethod(PaymentMethod method) {
    return PaymentMedium.values.where((m) => m.method == method).toList();
  }

  static PaymentMedium? fromValue(String? value) {
    if (value == null) return null;
    return PaymentMedium.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMedium.cashMoney,
    );
  }

  /// Verifica si este medio requiere un submedio (banco o app)
  bool get requiresSubmedium =>
      this == PaymentMedium.bankTransfer || this == PaymentMedium.appTransfer;
}

/// Proveedores de transferencia bancaria
enum BankTransferProvider {
  davivienda('davivienda', 'Davivienda', 'account_balance'),
  bancolombia('bancolombia', 'Bancolombia', 'account_balance'),
  bbva('bbva', 'BBVA', 'account_balance'),
  bancoDeOccidente('banco_occidente', 'Banco de Occidente', 'account_balance'),
  bancoPopular('banco_popular', 'Banco Popular', 'account_balance'),
  aviVillas('avvillas', 'AV Villas', 'account_balance'),
  scotiabank('scotiabank', 'Scotiabank Colpatria', 'account_balance'),
  itau('itau', 'Itaú', 'account_balance'),
  otro('otro', 'Otro banco', 'account_balance');

  final String value;
  final String displayName;
  final String icon;

  const BankTransferProvider(this.value, this.displayName, this.icon);

  static BankTransferProvider? fromValue(String? value) {
    if (value == null) return null;
    return BankTransferProvider.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BankTransferProvider.otro,
    );
  }
}

/// Proveedores de transferencia por App
enum AppTransferProvider {
  nequi('nequi', 'Nequi', 'smartphone'),
  daviplata('daviplata', 'DaviPlata', 'smartphone'),
  dale('dale', 'Dale!', 'smartphone'),
  movii('movii', 'MOVii', 'smartphone'),
  rappipay('rappipay', 'RappiPay', 'smartphone'),
  tpaga('tpaga', 'Tpaga', 'smartphone'),
  dollarApp('dollarapp', 'DollarApp', 'attach_money'),
  paypal('paypal', 'PayPal', 'payment'),
  otro('otro', 'Otra app', 'smartphone');

  final String value;
  final String displayName;
  final String icon;

  const AppTransferProvider(this.value, this.displayName, this.icon);

  static AppTransferProvider? fromValue(String? value) {
    if (value == null) return null;
    return AppTransferProvider.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppTransferProvider.otro,
    );
  }
}

/// Categorías de establecimientos
enum EstablishmentCategory {
  supermercado('supermercado', 'Supermercado', 'shopping_cart'),
  tienda('tienda', 'Tienda de barrio', 'store'),
  restaurante('restaurante', 'Restaurante', 'restaurant'),
  farmacia('farmacia', 'Farmacia / Droguería', 'local_pharmacy'),
  gasolinera('gasolinera', 'Estación de servicio', 'local_gas_station'),
  ferreteria('ferreteria', 'Ferretería', 'hardware'),
  ropa('ropa', 'Tienda de ropa', 'checkroom'),
  tecnologia('tecnologia', 'Tienda de tecnología', 'devices'),
  mercado('mercado', 'Plaza de mercado', 'storefront'),
  panaderia('panaderia', 'Panadería', 'bakery_dining'),
  carniceria('carniceria', 'Carnicería', 'set_meal'),
  online('online', 'Compra en línea', 'shopping_bag'),
  otro('otro', 'Otro', 'place');

  final String value;
  final String displayName;
  final String icon;

  const EstablishmentCategory(this.value, this.displayName, this.icon);

  static EstablishmentCategory? fromValue(String? value) {
    if (value == null) return null;
    return EstablishmentCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstablishmentCategory.otro,
    );
  }
}

/// Helper para sugerir forma de pago basada en tipo de cuenta
class PaymentSuggestionHelper {
  /// Sugiere forma y medio de pago basado en el tipo de cuenta
  static ({PaymentMethod? method, PaymentMedium? medium, String? submedium})
      suggestFromAccountType(String accountType, String? accountName) {
    // Cuentas de crédito -> Tarjeta de crédito
    if (accountType == 'credit') {
      return (
        method: PaymentMethod.credit,
        medium: PaymentMedium.creditCard,
        submedium: null,
      );
    }

    // Efectivo -> Efectivo
    if (accountType == 'cash') {
      return (
        method: PaymentMethod.cash,
        medium: PaymentMedium.cashMoney,
        submedium: null,
      );
    }

    // Billeteras digitales -> Detectar por nombre
    if (accountType == 'wallet') {
      final nameLower = (accountName ?? '').toLowerCase();

      if (nameLower.contains('nequi')) {
        return (
          method: PaymentMethod.cash,
          medium: PaymentMedium.appTransfer,
          submedium: AppTransferProvider.nequi.value,
        );
      }
      if (nameLower.contains('daviplata')) {
        return (
          method: PaymentMethod.cash,
          medium: PaymentMedium.appTransfer,
          submedium: AppTransferProvider.daviplata.value,
        );
      }
      if (nameLower.contains('dale')) {
        return (
          method: PaymentMethod.cash,
          medium: PaymentMedium.appTransfer,
          submedium: AppTransferProvider.dale.value,
        );
      }
      if (nameLower.contains('rappi')) {
        return (
          method: PaymentMethod.cash,
          medium: PaymentMedium.appTransfer,
          submedium: AppTransferProvider.rappipay.value,
        );
      }
      if (nameLower.contains('paypal')) {
        return (
          method: PaymentMethod.cash,
          medium: PaymentMedium.appTransfer,
          submedium: AppTransferProvider.paypal.value,
        );
      }

      // Default para wallet
      return (
        method: PaymentMethod.cash,
        medium: PaymentMedium.appTransfer,
        submedium: null,
      );
    }

    // Cuentas bancarias -> Detectar banco por nombre
    if (accountType == 'bank' || accountType == 'savings') {
      final nameLower = (accountName ?? '').toLowerCase();

      String? bankSubmedium;
      if (nameLower.contains('davivienda')) {
        bankSubmedium = BankTransferProvider.davivienda.value;
      } else if (nameLower.contains('bancolombia')) {
        bankSubmedium = BankTransferProvider.bancolombia.value;
      } else if (nameLower.contains('bbva')) {
        bankSubmedium = BankTransferProvider.bbva.value;
      } else if (nameLower.contains('occidente')) {
        bankSubmedium = BankTransferProvider.bancoDeOccidente.value;
      } else if (nameLower.contains('popular')) {
        bankSubmedium = BankTransferProvider.bancoPopular.value;
      } else if (nameLower.contains('villas')) {
        bankSubmedium = BankTransferProvider.aviVillas.value;
      } else if (nameLower.contains('scotiabank') || nameLower.contains('colpatria')) {
        bankSubmedium = BankTransferProvider.scotiabank.value;
      } else if (nameLower.contains('itau') || nameLower.contains('itaú')) {
        bankSubmedium = BankTransferProvider.itau.value;
      }

      return (
        method: PaymentMethod.cash,
        medium: PaymentMedium.bankTransfer,
        submedium: bankSubmedium,
      );
    }

    // Default
    return (method: null, medium: null, submedium: null);
  }
}
