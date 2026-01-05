import 'package:flutter/material.dart';

/// Utilidad para convertir nombres de iconos Material a IconData
///
/// Resuelve el problema de mostrar nombres de iconos como texto
/// en lugar de renderizar el icono real.
class IconUtils {
  IconUtils._();

  /// Mapa de nombres de iconos Material a IconData
  /// Incluye todos los iconos usados en la aplicación
  static const Map<String, IconData> _iconMap = {
    // Iconos de cuentas (AccountType)
    'payments': Icons.payments,
    'account_balance': Icons.account_balance,
    'account_balance_wallet': Icons.account_balance_wallet,
    'savings': Icons.savings,
    'trending_up': Icons.trending_up,
    'credit_card': Icons.credit_card,
    'real_estate_agent': Icons.real_estate_agent,
    'arrow_circle_down': Icons.arrow_circle_down,
    'arrow_circle_up': Icons.arrow_circle_up,

    // Iconos de categorías de transacciones
    'restaurant': Icons.restaurant,
    'local_grocery_store': Icons.local_grocery_store,
    'directions_car': Icons.directions_car,
    'local_gas_station': Icons.local_gas_station,
    'home': Icons.home,
    'flash_on': Icons.flash_on,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone_android': Icons.phone_android,
    'school': Icons.school,
    'local_hospital': Icons.local_hospital,
    'sports_esports': Icons.sports_esports,
    'movie': Icons.movie,
    'shopping_bag': Icons.shopping_bag,
    'checkroom': Icons.checkroom,
    'flight': Icons.flight,
    'hotel': Icons.hotel,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'card_giftcard': Icons.card_giftcard,
    'volunteer_activism': Icons.volunteer_activism,
    'attach_money': Icons.attach_money,
    'work': Icons.work,
    'business': Icons.business,
    'sell': Icons.sell,
    'receipt_long': Icons.receipt_long,
    'sports': Icons.sports,
    'fitness_center': Icons.fitness_center,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'music_note': Icons.music_note,
    'book': Icons.book,
    'build': Icons.build,
    'cleaning_services': Icons.cleaning_services,
    'security': Icons.security,
    'subscriptions': Icons.subscriptions,
    'more_horiz': Icons.more_horiz,
    'category': Icons.category,

    // Iconos adicionales de UI
    'arrow_upward': Icons.arrow_upward,
    'arrow_downward': Icons.arrow_downward,
    'check_circle_outline': Icons.check_circle_outline,
    'warning_amber_outlined': Icons.warning_amber_outlined,
    'lightbulb_outline': Icons.lightbulb_outline,
    'settings_outlined': Icons.settings_outlined,
    'notifications_outlined': Icons.notifications_outlined,
    'notifications_active': Icons.notifications_active,
    'smart_toy': Icons.smart_toy,
    'info_outline': Icons.info_outline,
    'error_outline': Icons.error_outline,
  };

  /// Obtiene IconData desde el nombre del icono Material
  ///
  /// [name] - Nombre del icono (ej: 'account_balance', 'payments')
  /// [fallback] - IconData a retornar si no se encuentra (default: Icons.category)
  ///
  /// Ejemplo:
  /// ```dart
  /// Icon(IconUtils.fromName('payments'))
  /// Icon(IconUtils.fromName(account.icon, fallback: Icons.account_balance))
  /// ```
  static IconData fromName(String? name, {IconData fallback = Icons.category}) {
    if (name == null || name.isEmpty) {
      return fallback;
    }
    return _iconMap[name] ?? fallback;
  }

  /// Verifica si un nombre de icono está disponible
  static bool hasIcon(String name) {
    return _iconMap.containsKey(name);
  }

  /// Lista de todos los nombres de iconos disponibles
  static List<String> get availableIcons => _iconMap.keys.toList();

  /// Obtiene IconData para un tipo de cuenta
  /// Usa el icono definido en AccountType o el icono personalizado
  static IconData forAccountType(String? customIcon, String typeIcon) {
    // Primero intenta el icono personalizado
    if (customIcon != null && customIcon.isNotEmpty) {
      final icon = _iconMap[customIcon];
      if (icon != null) return icon;
    }
    // Si no, usa el icono del tipo
    return _iconMap[typeIcon] ?? Icons.account_balance;
  }
}
