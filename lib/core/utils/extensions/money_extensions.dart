import '../formatters/currency_formatter.dart';

/// Extension para formateo facil de montos en double
extension MoneyDouble on double {
  /// Formatea como moneda con configuracion por defecto
  String toMoney({
    String currency = 'MXN',
    String locale = 'es_MX',
    bool showSymbol = true,
  }) {
    return CurrencyFormatter.format(
      this,
      currency: currency,
      locale: locale,
      showSymbol: showSymbol,
    );
  }

  /// Formatea de forma inteligente (sin decimales si es entero)
  String toMoneySmart({
    String currency = 'MXN',
    String locale = 'es_MX',
    bool showSymbol = true,
  }) {
    return CurrencyFormatter.formatSmart(
      this,
      currency: currency,
      locale: locale,
      showSymbol: showSymbol,
    );
  }

  /// Formatea en formato compacto (1.5K, 2M)
  String toMoneyCompact({
    String currency = 'MXN',
    String locale = 'es_MX',
    bool showSymbol = true,
  }) {
    return CurrencyFormatter.format(
      this,
      currency: currency,
      locale: locale,
      showSymbol: showSymbol,
      compact: true,
    );
  }

  /// Formatea con signo (+/-)
  String toMoneyWithSign({
    String currency = 'MXN',
    String locale = 'es_MX',
    bool showSymbol = true,
  }) {
    return CurrencyFormatter.formatWithSign(
      this,
      currency: currency,
      locale: locale,
      showSymbol: showSymbol,
    );
  }

  /// Formatea como porcentaje
  String toPercent({int decimalDigits = 1, String locale = 'es_MX'}) {
    return CurrencyFormatter.formatPercent(
      this,
      decimalDigits: decimalDigits,
      locale: locale,
    );
  }
}

/// Extension para formateo facil de montos en int
extension MoneyInt on int {
  /// Formatea como moneda con configuracion por defecto
  String toMoney({
    String currency = 'MXN',
    String locale = 'es_MX',
    bool showSymbol = true,
  }) {
    return toDouble().toMoney(
      currency: currency,
      locale: locale,
      showSymbol: showSymbol,
    );
  }

  /// Formatea de forma inteligente (sin decimales si es entero)
  String toMoneySmart({
    String currency = 'MXN',
    String locale = 'es_MX',
    bool showSymbol = true,
  }) {
    return toDouble().toMoneySmart(
      currency: currency,
      locale: locale,
      showSymbol: showSymbol,
    );
  }

  /// Formatea en formato compacto (1.5K, 2M)
  String toMoneyCompact({
    String currency = 'MXN',
    String locale = 'es_MX',
    bool showSymbol = true,
  }) {
    return toDouble().toMoneyCompact(
      currency: currency,
      locale: locale,
      showSymbol: showSymbol,
    );
  }

  /// Formatea con signo (+/-)
  String toMoneyWithSign({
    String currency = 'MXN',
    String locale = 'es_MX',
    bool showSymbol = true,
  }) {
    return toDouble().toMoneyWithSign(
      currency: currency,
      locale: locale,
      showSymbol: showSymbol,
    );
  }

  /// Formatea como porcentaje
  String toPercent({int decimalDigits = 1, String locale = 'es_MX'}) {
    return toDouble().toPercent(
      decimalDigits: decimalDigits,
      locale: locale,
    );
  }
}

/// Extension para parsear strings a montos
extension MoneyString on String {
  /// Parsea string de moneda a double
  double? toMoneyValue({String locale = 'es_MX'}) {
    return CurrencyFormatter.parse(this, locale: locale);
  }

  /// Parsea string de moneda a double, retorna 0 si falla
  double toMoneyValueOrZero({String locale = 'es_MX'}) {
    return CurrencyFormatter.parse(this, locale: locale) ?? 0.0;
  }
}
