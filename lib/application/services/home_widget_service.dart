// Servicio para actualizar el widget de home screen.
// Sincroniza el saldo total con el widget nativo.

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

/// Servicio para gestionar el widget de saldo en la pantalla de inicio.
///
/// Responsabilidades:
/// - Guardar datos del saldo en SharedPreferences/UserDefaults
/// - Solicitar actualización del widget nativo
/// - Formatear valores para display
class HomeWidgetService {
  static const String _androidWidgetName = 'BalanceWidgetProvider';
  static const String _iOSWidgetName = 'BalanceWidget';

  // Keys para SharedPreferences
  static const String _keyBalance = 'balance';
  static const String _keyUpdated = 'updated';

  final NumberFormat _currencyFormat;
  final DateFormat _timeFormat;

  HomeWidgetService()
      : _currencyFormat = NumberFormat.currency(
          locale: 'es_CO',
          symbol: '\$',
          decimalDigits: 0,
        ),
        _timeFormat = DateFormat('HH:mm', 'es_CO');

  /// Actualiza el widget con el saldo actual.
  ///
  /// [totalBalance] - Saldo total a mostrar
  /// Retorna true si la actualización fue exitosa.
  Future<bool> updateBalance(double totalBalance) async {
    try {
      // Formatear saldo
      final formattedBalance = _currencyFormat.format(totalBalance);

      // Formatear hora de actualización
      final formattedTime = _timeFormat.format(DateTime.now());

      // Guardar datos para el widget
      await HomeWidget.saveWidgetData<String>(_keyBalance, formattedBalance);
      await HomeWidget.saveWidgetData<String>(_keyUpdated, formattedTime);

      // Solicitar actualización del widget
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );

      return true;
    } catch (e) {
      // Silenciar errores si el widget no está configurado
      return false;
    }
  }

  /// Limpia los datos del widget.
  ///
  /// Útil al cerrar sesión.
  Future<void> clearWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>(_keyBalance, '\$0');
      await HomeWidget.saveWidgetData<String>(_keyUpdated, 'Sin datos');

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );
    } catch (_) {
      // Ignorar errores
    }
  }

  /// Verifica si hay un widget instalado.
  ///
  /// Nota: No hay forma confiable de detectar esto en todas las plataformas.
  /// Este método intenta una actualización y retorna el resultado.
  Future<bool> isWidgetInstalled() async {
    try {
      final result = await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
