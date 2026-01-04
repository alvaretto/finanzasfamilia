import 'package:intl/intl.dart';

/// Formateador de moneda para diferentes locales y monedas
class CurrencyFormatter {
  // Instancias cacheadas de NumberFormat
  static final Map<String, NumberFormat> _formatters = {};

  /// Formatea un monto como moneda
  ///
  /// [amount] - El monto a formatear
  /// [currency] - Codigo ISO de moneda (COP, USD, MXN, EUR)
  /// [locale] - Locale para formateo (es_CO, es_MX, en_US)
  /// [showSymbol] - Si mostrar simbolo de moneda
  /// [compact] - Si usar formato compacto (1.5K, 2M)
  static String format(
    double amount, {
    String currency = 'COP',
    String locale = 'es_CO',
    bool showSymbol = true,
    bool compact = false,
    int decimalDigits = 2,
  }) {
    final key = '${currency}_${locale}_${showSymbol}_$compact';

    if (!_formatters.containsKey(key)) {
      if (compact) {
        _formatters[key] = NumberFormat.compactCurrency(
          locale: locale,
          symbol: showSymbol ? _getSymbol(currency) : '',
          decimalDigits: 1,
        );
      } else {
        _formatters[key] = NumberFormat.currency(
          locale: locale,
          symbol: showSymbol ? _getSymbol(currency) : '',
          decimalDigits: decimalDigits,
        );
      }
    }

    return _formatters[key]!.format(amount);
  }

  /// Formatea para display (sin decimales si es entero)
  static String formatSmart(
    double amount, {
    String currency = 'COP',
    String locale = 'es_CO',
    bool showSymbol = true,
  }) {
    final hasDecimals = amount != amount.roundToDouble();
    return format(
      amount,
      currency: currency,
      locale: locale,
      showSymbol: showSymbol,
      decimalDigits: hasDecimals ? 2 : 0,
    );
  }

  /// Formatea monto con signo (+/-)
  static String formatWithSign(
    double amount, {
    String currency = 'COP',
    String locale = 'es_CO',
    bool showSymbol = true,
  }) {
    final sign = amount >= 0 ? '+' : '';
    return '$sign${format(amount, currency: currency, locale: locale, showSymbol: showSymbol)}';
  }

  /// Formatea como porcentaje
  static String formatPercent(
    double value, {
    int decimalDigits = 1,
    String locale = 'es_CO',
  }) {
    final formatter = NumberFormat.percentPattern(locale);
    return formatter.format(value / 100);
  }

  /// Parsea un string de moneda a double
  static double? parse(String value, {String locale = 'es_CO'}) {
    try {
      // Remover simbolos de moneda y espacios
      final cleanValue = value
          .replaceAll(RegExp(r'[^\d.,\-]'), '')
          .replaceAll(',', '.');
      return double.tryParse(cleanValue);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el simbolo de moneda
  static String _getSymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '\u20AC';
      case 'MXN':
        return '\$';
      case 'COP':
        return '\$';
      case 'ARS':
        return '\$';
      case 'CLP':
        return '\$';
      case 'PEN':
        return 'S/';
      case 'BRL':
        return 'R\$';
      default:
        return '\$';
    }
  }

  /// Lista de monedas soportadas (COP por defecto)
  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'COP', name: 'Peso Colombiano', symbol: '\$', locale: 'es_CO'),
    CurrencyInfo(code: 'MXN', name: 'Peso Mexicano', symbol: '\$', locale: 'es_MX'),
    CurrencyInfo(code: 'USD', name: 'Dolar Estadounidense', symbol: '\$', locale: 'en_US'),
    CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '\u20AC', locale: 'es_ES'),
    CurrencyInfo(code: 'ARS', name: 'Peso Argentino', symbol: '\$', locale: 'es_AR'),
    CurrencyInfo(code: 'CLP', name: 'Peso Chileno', symbol: '\$', locale: 'es_CL'),
    CurrencyInfo(code: 'PEN', name: 'Sol Peruano', symbol: 'S/', locale: 'es_PE'),
    CurrencyInfo(code: 'BRL', name: 'Real Brasileno', symbol: 'R\$', locale: 'pt_BR'),
  ];
}

/// Informacion de una moneda
class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String locale;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.locale,
  });
}
