import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../daos/places_dao.dart';
import '../tables/places_table.dart';

const _uuid = Uuid();

/// Namespace UUID para generar IDs determinísticos de lugares del sistema.
const _systemPlaceNamespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

/// Genera un UUID determinístico para un lugar del sistema.
String _deterministicId(String placeName, PlaceType type) {
  return _uuid.v5(_systemPlaceNamespace, 'place:${type.name}:$placeName');
}

/// Siembra lugares predefinidos comunes en Colombia
/// Incluye supermercados, tiendas, restaurantes, farmacias, etc.
Future<void> seedPlaces(PlacesDao dao) async {
  final existingPlaces = await dao.getAllPlaces();
  if (existingPlaces.isNotEmpty) {
    return; // Ya sembrado
  }

  final places = <PlacesCompanion>[];

  // ==========================================
  // SUPERMERCADOS
  // ==========================================
  places.addAll([
    _place(
      name: 'D1',
      type: PlaceType.supermarket,
      notes: 'Tienda de descuentos',
      usageCount: 100,
    ),
    _place(
      name: 'Éxito',
      type: PlaceType.supermarket,
      notes: 'Supermercado tradicional',
      usageCount: 80,
    ),
    _place(
      name: 'Jumbo',
      type: PlaceType.supermarket,
      notes: 'Hipermercado',
      usageCount: 60,
    ),
    _place(
      name: 'Ara',
      type: PlaceType.supermarket,
      notes: 'Tienda de descuentos',
      usageCount: 90,
    ),
    _place(
      name: 'Olímpica',
      type: PlaceType.supermarket,
      notes: 'Supermercado regional',
      usageCount: 50,
    ),
    _place(
      name: 'Carulla',
      type: PlaceType.supermarket,
      notes: 'Supermercado premium',
      usageCount: 40,
    ),
    _place(
      name: 'Metro',
      type: PlaceType.supermarket,
      notes: 'Mayorista',
      usageCount: 30,
    ),
    _place(
      name: 'Mercaldas',
      type: PlaceType.supermarket,
      notes: 'Regional Eje Cafetero',
      usageCount: 20,
    ),
  ]);

  // ==========================================
  // TIENDAS
  // ==========================================
  places.addAll([
    _place(
      name: 'Tienda de Barrio',
      type: PlaceType.store,
      notes: 'Tienda local genérica',
      usageCount: 150,
    ),
    _place(
      name: 'Papelería',
      type: PlaceType.store,
      notes: 'Papelería local',
      usageCount: 25,
    ),
    _place(
      name: 'Ferretería',
      type: PlaceType.store,
      notes: 'Ferretería local',
      usageCount: 15,
    ),
    _place(
      name: 'Droguería',
      type: PlaceType.store,
      notes: 'Droguería de barrio',
      usageCount: 35,
    ),
  ]);

  // ==========================================
  // VENTA CALLEJERA
  // ==========================================
  places.addAll([
    _place(
      name: 'Plaza de Mercado',
      type: PlaceType.street,
      notes: 'Mercado tradicional',
      usageCount: 120,
    ),
    _place(
      name: 'Vendedor Ambulante',
      type: PlaceType.street,
      notes: 'Venta callejera',
      usageCount: 50,
    ),
    _place(
      name: 'Galería',
      type: PlaceType.street,
      notes: 'Mercado local tradicional',
      usageCount: 40,
    ),
  ]);

  // ==========================================
  // WEB / ONLINE
  // ==========================================
  places.addAll([
    _place(
      name: 'MercadoLibre',
      type: PlaceType.web,
      notes: 'E-commerce',
      usageCount: 30,
    ),
    _place(
      name: 'Amazon',
      type: PlaceType.web,
      notes: 'E-commerce internacional',
      usageCount: 20,
    ),
    _place(
      name: 'Rappi',
      type: PlaceType.web,
      notes: 'Delivery app',
      usageCount: 60,
    ),
    _place(
      name: 'Domicilios.com',
      type: PlaceType.web,
      notes: 'Delivery comida',
      usageCount: 25,
    ),
    _place(
      name: 'Éxito Online',
      type: PlaceType.web,
      notes: 'Supermercado online',
      usageCount: 15,
    ),
  ]);

  // ==========================================
  // RESTAURANTES
  // ==========================================
  places.addAll([
    _place(
      name: 'Restaurante Local',
      type: PlaceType.restaurant,
      notes: 'Restaurante genérico',
      usageCount: 70,
    ),
    _place(
      name: 'Corrientazo',
      type: PlaceType.restaurant,
      notes: 'Almuerzo económico',
      usageCount: 90,
    ),
    _place(
      name: 'Panadería',
      type: PlaceType.restaurant,
      notes: 'Panadería local',
      usageCount: 80,
    ),
    _place(
      name: 'Cafetería',
      type: PlaceType.restaurant,
      notes: 'Café y snacks',
      usageCount: 45,
    ),
    _place(
      name: 'Comidas Rápidas',
      type: PlaceType.restaurant,
      notes: 'Fast food genérico',
      usageCount: 35,
    ),
  ]);

  // ==========================================
  // FARMACIAS
  // ==========================================
  places.addAll([
    _place(
      name: 'Drogas La Rebaja',
      type: PlaceType.pharmacy,
      notes: 'Cadena de farmacias',
      usageCount: 40,
    ),
    _place(
      name: 'Cruz Verde',
      type: PlaceType.pharmacy,
      notes: 'Cadena de farmacias',
      usageCount: 35,
    ),
    _place(
      name: 'Colsubsidio',
      type: PlaceType.pharmacy,
      notes: 'Droguería de caja',
      usageCount: 30,
    ),
    _place(
      name: 'Locatel',
      type: PlaceType.pharmacy,
      notes: 'Farmacia y equipos médicos',
      usageCount: 15,
    ),
  ]);

  // ==========================================
  // ESTACIONES DE SERVICIO
  // ==========================================
  places.addAll([
    _place(
      name: 'Terpel',
      type: PlaceType.gasStation,
      notes: 'Estación de servicio',
      usageCount: 50,
    ),
    _place(
      name: 'Texaco',
      type: PlaceType.gasStation,
      notes: 'Estación de servicio',
      usageCount: 30,
    ),
    _place(
      name: 'Mobil',
      type: PlaceType.gasStation,
      notes: 'Estación de servicio',
      usageCount: 25,
    ),
    _place(
      name: 'Primax',
      type: PlaceType.gasStation,
      notes: 'Estación de servicio',
      usageCount: 20,
    ),
  ]);

  // ==========================================
  // CENTROS COMERCIALES
  // ==========================================
  places.addAll([
    _place(
      name: 'Centro Comercial',
      type: PlaceType.mall,
      notes: 'Centro comercial genérico',
      usageCount: 25,
    ),
    _place(
      name: 'Alkosto',
      type: PlaceType.mall,
      notes: 'Tienda por departamentos',
      usageCount: 20,
    ),
    _place(
      name: 'Homecenter',
      type: PlaceType.mall,
      notes: 'Mejoramiento del hogar',
      usageCount: 15,
    ),
  ]);

  // ==========================================
  // OTROS
  // ==========================================
  places.addAll([
    _place(
      name: 'Otro',
      type: PlaceType.other,
      notes: 'Lugar no especificado',
      usageCount: 10,
    ),
    _place(
      name: 'Cajero ATM',
      type: PlaceType.other,
      notes: 'Retiro de efectivo',
      usageCount: 40,
    ),
    _place(
      name: 'Banco',
      type: PlaceType.other,
      notes: 'Oficina bancaria',
      usageCount: 20,
    ),
  ]);

  await dao.insertPlaces(places);
}

/// Helper para crear un lugar con ID determinístico
PlacesCompanion _place({
  String? id,
  required String name,
  required PlaceType type,
  String? address,
  String? city,
  String? notes,
  int usageCount = 0,
}) {
  final now = DateTime.now();
  return PlacesCompanion(
    id: Value(id ?? _deterministicId(name, type)),
    name: Value(name),
    type: Value(type.name),
    address: Value(address),
    city: Value(city),
    notes: Value(notes),
    isActive: const Value(true),
    isSystem: const Value(true),
    usageCount: Value(usageCount),
    createdAt: Value(now),
    updatedAt: Value(now),
  );
}
