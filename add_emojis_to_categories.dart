/// Script temporal para generar código con emojis para categorías
/// Este script genera el código Dart con emojis basado en la guía GUIA_MODO_PERSONAL.md

void main() {
  // GASTOS
  print('// 1. Alimentacion');
  print("final alimentacionId = await _insertCategory('Alimentacion', 'expense', 'restaurant', '🍔', '#ef4444');");
  print("parentIds['alimentacion'] = alimentacionId;");
  print("await _insertSubcategories(alimentacionId, 'expense', '#ef4444', [");
  print("  ('Supermercado', 'shopping_cart', '🛒'),");
  print("  ('Restaurantes', 'restaurant', '🍽️'),");
  print("  ('Delivery', 'delivery_dining', '🚚'),");
  print("  ('Cafeteria / Snacks', 'local_cafe', '☕'),");
  print("  ('Licores y bebidas', 'liquor', '🍺'),");
  print("]);");
  print("");

  print('// 2. Vivienda');
  print("final viviendaId = await _insertCategory('Vivienda', 'expense', 'home', '🏠', '#3b82f6');");
  print("parentIds['vivienda'] = viviendaId;");
  print("await _insertSubcategories(viviendaId, 'expense', '#3b82f6', [");
  print("  ('Renta / Hipoteca', 'house', '🏡'),");
  print("  ('Administracion', 'apartment', '🏢'),");
  print("  ('Agua', 'water_drop', '💧'),");
  print("  ('Energia electrica', 'bolt', '⚡'),");
  print("  ('Gas', 'local_fire_department', '🔥'),");
  print("  ('Internet / TV / Telefono', 'wifi', '📡'),");
  print("  ('Mantenimiento hogar', 'handyman', '🔧'),");
  print("  ('Seguro hogar', 'security', '🛡️'),");
  print("]);");
  print("");

  print('// 3. Transporte');
  print("final transporteId = await _insertCategory('Transporte', 'expense', 'directions_car', '🚗', '#22c55e');");
  print("parentIds['transporte'] = transporteId;");
  print("await _insertSubcategories(transporteId, 'expense', '#22c55e', [");
  print("  ('Combustible', 'local_gas_station', '⛽'),");
  print("  ('Transporte publico', 'directions_bus', '🚌'),");
  print("  ('Taxi / Uber', 'local_taxi', '🚕'),");
  print("  ('Mantenimiento vehiculo', 'car_repair', '🔧'),");
  print("  ('Seguro vehiculo', 'verified_user', '🛡️'),");
  print("  ('Parqueadero', 'local_parking', '🅿️'),");
  print("  ('Peajes', 'toll', '🚧'),");
  print("]);");
  print("");

  print('// 4. Salud');
  print("final saludId = await _insertCategory('Salud', 'expense', 'favorite', '❤️', '#ec4899');");
  print("parentIds['salud'] = saludId;");
  print("await _insertSubcategories(saludId, 'expense', '#ec4899', [");
  print("  ('Medicina prepagada / EPS', 'health_and_safety', '🏥'),");
  print("  ('Consultas medicas', 'medical_services', '👨‍⚕️'),");
  print("  ('Medicamentos', 'medication', '💊'),");
  print("  ('Examenes / Laboratorio', 'biotech', '🔬'),");
  print("  ('Odontologia', 'dentistry', '🦷'),");
  print("  ('Optica', 'visibility', '👓'),");
  print("  ('Terapias', 'psychology', '🧠'),");
  print("]);");
  print("");

  print('// 5. Bienestar');
  print("final bienestarId = await _insertCategory('Bienestar', 'expense', 'spa', '💆', '#a855f7');");
  print("parentIds['bienestar'] = bienestarId;");
  print("await _insertSubcategories(bienestarId, 'expense', '#a855f7', [");
  print("  ('Gimnasio / Deportes', 'fitness_center', '💪'),");
  print("  ('Cuidado personal', 'face', '✨'),");
  print("  ('Productos de aseo', 'soap', '🧼'),");
  print("  ('Cosmeticos', 'brush', '💄'),");
  print("  ('Salud mental', 'self_improvement', '🧘'),");
  print("]);");
  print("");

  print('// 6. Educacion');
  print("final educacionId = await _insertCategory('Educacion', 'expense', 'school', '🎓', '#f59e0b');");
  print("parentIds['educacion'] = educacionId;");
  print("await _insertSubcategories(educacionId, 'expense', '#f59e0b', [");
  print("  ('Matricula / Pension', 'school', '🏫'),");
  print("  ('Cursos / Capacitaciones', 'cast_for_education', '📚'),");
  print("  ('Libros / Material', 'menu_book', '📖'),");
  print("  ('Utiles escolares', 'edit', '✏️'),");
  print("  ('Uniformes', 'checkroom', '👔'),");
  print("]);");
  print("");

  print('// 7. Ropa y Calzado');
  print("final ropaId = await _insertCategory('Ropa y Calzado', 'expense', 'shopping_bag', '👗', '#06b6d4');");
  print("parentIds['ropa'] = ropaId;");
  print("await _insertSubcategories(ropaId, 'expense', '#06b6d4', [");
  print("  ('Ropa', 'dry_cleaning', '👕'),");
  print("  ('Calzado', 'ice_skating', '👟'),");
  print("  ('Accesorios', 'watch', '⌚'),");
  print("  ('Ropa deportiva', 'sports', '🏃'),");
  print("]);");
  print("");

  print('// 8. Entretenimiento');
  print("final entretenimientoId = await _insertCategory('Entretenimiento', 'expense', 'movie', '🎬', '#8b5cf6');");
  print("parentIds['entretenimiento'] = entretenimientoId;");
  print("await _insertSubcategories(entretenimientoId, 'expense', '#8b5cf6', [");
  print("  ('Streaming', 'play_circle', '📺'),");
  print("  ('Cine / Teatro', 'theaters', '🎭'),");
  print("  ('Eventos / Conciertos', 'celebration', '🎉'),");
  print("  ('Videojuegos', 'sports_esports', '🎮'),");
  print("  ('Hobbies', 'palette', '🎨'),");
  print("  ('Libros / Revistas', 'menu_book', '📚'),");
  print("  ('Salidas / Vida social', 'nightlife', '🌟'),");
  print("  ('Vacaciones / Viajes', 'flight', '✈️'),");
  print("]);");
  print("");

  print('// 9. Tecnologia');
  print("final tecnologiaId = await _insertCategory('Tecnologia', 'expense', 'devices', '💻', '#64748b');");
  print("parentIds['tecnologia'] = tecnologiaId;");
  print("await _insertSubcategories(tecnologiaId, 'expense', '#64748b', [");
  print("  ('Celular / Telefonia', 'smartphone', '📱'),");
  print("  ('Equipos / Hardware', 'computer', '🖥️'),");
  print("  ('Accesorios tecnologicos', 'headphones', '🎧'),");
  print("  ('Software / Apps', 'apps', '📲'),");
  print("  ('Reparaciones', 'build', '🔧'),");
  print("]);");
  print("");

  print('// 10. Mascotas');
  print("final mascotasId = await _insertCategory('Mascotas', 'expense', 'pets', '🐾', '#f97316');");
  print("parentIds['mascotas'] = mascotasId;");
  print("await _insertSubcategories(mascotasId, 'expense', '#f97316', [");
  print("  ('Alimento', 'set_meal', '🍖'),");
  print("  ('Veterinario', 'local_hospital', '🏥'),");
  print("  ('Accesorios', 'shopping_bag', '🎾'),");
  print("  ('Peluqueria / Grooming', 'cut', '✂️'),");
  print("]);");
  print("");

  print('// 11. Servicios Financieros');
  print("final serviciosFinId = await _insertCategory('Servicios Financieros', 'expense', 'account_balance', '🏦', '#0891b2');");
  print("parentIds['servicios_financieros'] = serviciosFinId;");
  print("await _insertSubcategories(serviciosFinId, 'expense', '#0891b2', [");
  print("  ('Cuota manejo', 'credit_card', '💳'),");
  print("  ('Comisiones bancarias', 'receipt', '🧾'),");
  print("  ('Seguros de vida', 'shield', '🛡️'),");
  print("  ('Intereses', 'trending_down', '📉'),");
  print("]);");
  print("");

  print('// 12. Impuestos');
  print("final impuestosId = await _insertCategory('Impuestos', 'expense', 'receipt_long', '📋', '#dc2626');");
  print("parentIds['impuestos'] = impuestosId;");
  print("await _insertSubcategories(impuestosId, 'expense', '#dc2626', [");
  print("  ('Declaracion de renta', 'description', '📄'),");
  print("  ('IVA', 'percent', '💸'),");
  print("  ('Otros impuestos', 'gavel', '⚖️'),");
  print("]);");
  print("");

  print('// 13. Regalos y Donaciones');
  print("final regalosId = await _insertCategory('Regalos y Donaciones', 'expense', 'card_giftcard', '🎁', '#e11d48');");
  print("parentIds['regalos'] = regalosId;");
  print("await _insertSubcategories(regalosId, 'expense', '#e11d48', [");
  print("  ('Regalos', 'redeem', '🎀'),");
  print("  ('Donaciones', 'volunteer_activism', '🤝'),");
  print("  ('Propinas', 'payments', '💵'),");
  print("]);");
  print("");

  print('// 14. Suscripciones');
  print("final suscripcionesId = await _insertCategory('Suscripciones', 'expense', 'subscriptions', '📱', '#7c3aed');");
  print("parentIds['suscripciones'] = suscripcionesId;");
  print("await _insertSubcategories(suscripcionesId, 'expense', '#7c3aed', [");
  print("  ('Membresias', 'card_membership', '💳'),");
  print("  ('Suscripciones digitales', 'subscriptions', '📲'),");
  print("  ('Clubes', 'groups', '👥'),");
  print("]);");
  print("");

  print('// 15. Otros Gastos');
  print("await _insertCategory('Otros Gastos', 'expense', 'more_horiz', '📦', '#6b7280');");
  print("");

  // INGRESOS
  print('// ============================================================');
  print('// CATEGORIAS DE INGRESOS');
  print('// ============================================================');
  print("");

  print('// 1. Salario / Empleo');
  print("final salarioId = await _insertCategory('Salario / Empleo', 'income', 'work', '💼', '#22c55e');");
  print("parentIds['salario'] = salarioId;");
  print("await _insertSubcategories(salarioId, 'income', '#22c55e', [");
  print("  ('Salario mensual', 'attach_money', '💰'),");
  print("  ('Bonificaciones', 'star', '⭐'),");
  print("  ('Comisiones', 'trending_up', '📈'),");
  print("  ('Horas extras', 'schedule', '⏰'),");
  print("  ('Prima', 'card_giftcard', '🎁'),");
  print("]);");
  print("");

  print('// 2. Negocio / Freelance');
  print("final negocioId = await _insertCategory('Negocio / Freelance', 'income', 'laptop', '💻', '#3b82f6');");
  print("parentIds['negocio'] = negocioId;");
  print("await _insertSubcategories(negocioId, 'income', '#3b82f6', [");
  print("  ('Ventas', 'storefront', '🏪'),");
  print("  ('Servicios', 'handshake', '🤝'),");
  print("  ('Consultoria', 'lightbulb', '💡'),");
  print("  ('Proyectos', 'folder', '📁'),");
  print("]);");
  print("");

  print('// 3. Inversiones');
  print("final inversionesId = await _insertCategory('Inversiones', 'income', 'trending_up', '📈', '#8b5cf6');");
  print("parentIds['inversiones'] = inversionesId;");
  print("await _insertSubcategories(inversionesId, 'income', '#8b5cf6', [");
  print("  ('Dividendos', 'pie_chart', '📊'),");
  print("  ('Intereses', 'savings', '💵'),");
  print("  ('Ganancias de capital', 'show_chart', '📉'),");
  print("  ('Rendimientos', 'account_balance', '🏦'),");
  print("]);");
  print("");

  print('// 4. Arriendos');
  print("final arriendosId = await _insertCategory('Arriendos', 'income', 'home_work', '🏘️', '#f97316');");
  print("parentIds['arriendos'] = arriendosId;");
  print("await _insertSubcategories(arriendosId, 'income', '#f97316', [");
  print("  ('Arriendo de inmueble', 'apartment', '🏢'),");
  print("  ('Arriendo de vehiculo', 'directions_car', '🚗'),");
  print("  ('Arriendo de equipos', 'devices', '🖥️'),");
  print("]);");
  print("");

  print('// 5. Otros Ingresos');
  print("final otrosIngresosId = await _insertCategory('Otros Ingresos', 'income', 'add_circle', '➕', '#6b7280');");
  print("parentIds['otros_ingresos'] = otrosIngresosId;");
  print("await _insertSubcategories(otrosIngresosId, 'income', '#6b7280', [");
  print("  ('Reembolsos', 'receipt_long', '🧾'),");
  print("  ('Regalos recibidos', 'redeem', '🎁'),");
  print("  ('Venta articulos', 'sell', '💸'),");
  print("  ('Subsidios', 'account_balance', '💰'),");
  print("  ('Pension', 'elderly', '👴'),");
  print("]);");
  print("");

  print('// 6. Ingresos Extraordinarios');
  print("await _insertCategory('Ingresos Extraordinarios', 'income', 'stars', '⭐', '#eab308');");
}
