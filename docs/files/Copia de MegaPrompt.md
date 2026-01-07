Actúa como un Ingeniero de Software Principal experto en Flutter 3.24+, Riverpod 2.6, 
Drift y Arquitectura Limpia. Tu objetivo es implementar el núcleo de la aplicación 
'Finanzas Familiares AS' siguiendo estrictamente las siguientes directrices, contexto 
de negocio y requerimientos técnicos.

#### 1. Filosofía y Reglas de Oro (Strict Mode)

1. **Offline-First es Ley:** Toda escritura va primero a la base de datos local (Drift/SQLite). La sincronización con Supabase ocurre en segundo plano. Nunca bloquees la UI esperando a la red.
2. **Contexto Colombiano:** La moneda por defecto es COP. Los formatos de fecha y decimales deben seguir el estándar `es_CO`.
3. **Doble Modo de UI:** La lógica de negocio es única, pero la presentación varía:
* *Modo Personal:* Usa términos como "Lo que tengo", "Lo que debo".
* *Modo Profesional:* Usa términos NIIF/NIF como "Activos", "Pasivos", "Patrimonio" (Basado en Ley 1314 de 2009).


4. **Testing Obsesivo:** Cada funcionalidad nueva debe incluir su test correspondiente (Unit, Widget o Integration).

#### 2. Stack Tecnológico (No negociable)

* **Frontend:** Flutter 3.24+ (Dart 3.5+).
* **State Management:** Riverpod 2.6 (Generator syntax preferida).
* **Local DB:** Drift + SQLite (Encriptada).
* **Backend:** Supabase (Auth, DB, Storage).
* **Router:** go_router.
* **Forms:** flutter_form_builder (recomendado para formularios complejos) o manejo nativo con validaciones estrictas.

#### 3. Requerimiento Crítico: Modelo de Datos y Formulario Transaccional

Debes implementar una refactorización profunda del modelo de `Transaction` y `Category` según el archivo `items.md`:

**A. Jerarquía de Categorías (Nested Categories)**

* La tabla `Categories` debe soportar recursividad (campo `parent_id`).
* **Comportamiento de UI:** Selectores en cascada.
* Selección Nivel 1 (ej. "Gastos") -> Filtra Nivel 2.
* Selección Nivel 2 (ej. "Alimentación") -> Filtra Nivel 3 (ej. "Mercado").
* *Restricción:* Si el tipo de transacción es "Gasto", NO mostrar categorías de "Ingreso".



**B. Formulario de Detalle de Transacción (The Item Form)**
La entidad `TransactionItem` o la expansión de `Transaction` debe capturar:

1. **Descripción:** (String, Obligatorio) Detalle del artículo.
2. **Marca:** (String, Opcional) Ej: Roa.
3. **Cantidad:** (Double, Obligatorio) Ej: 10.
4. **Unidad de Medida:** (Enum/String) Ej: Libra, Kilo, Unidad, Litro.
5. **Precio:** (Currency) Moneda local.
6. **Lugar/Establecimiento:** (String) Ej: Supermercado Mercamos.
7. **Dirección:** (String, Geo opcional).
8. **Teléfono:** (String, Opcional).
9. **Fecha Causación:** (DateTime) Cuándo ocurrió el hecho económico (Principio de Devengo/Causación NIIF).

**C. Lógica de Medios de Pago (Payment Methods)**
Implementar una estructura jerárquica para la selección del pago:

* **Crédito**
* Tarjeta de Crédito (Requiere seleccionar la TC asociada).
* Fiado (Promesa verbal - Pasivo corriente).


* **Contado**
* Efectivo (Caja general).
* Transferencia Bancaria (Bancolombia, Davivienda, etc.).
* Billeteras Digitales (Nequi, DaviPlata, DollarApp).



#### 4. Definición de Tablas Drift (Esquema Sugerido)

Genera o actualiza el archivo de definición de tablas (`database.dart` o `tables.drift`) con esta estructura lógica:

```dart
// En Drift
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'income', 'expense'
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  // ... timestamps y sync flags
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Campos base
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()(); // Fecha de causación
  
  // Detalle extendido (items.md)
  TextColumn get description => text()();
  TextColumn get brand => text().nullable()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unitOfMeasure => text().withDefault(const Constant('Unidad'))();
  TextColumn get placeName => text().nullable()();
  TextColumn get placeAddress => text().nullable()();
  TextColumn get placePhone => text().nullable()();
  
  // Relaciones
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)(); // Origen de fondos
  
  // Lógica de Pago
  TextColumn get paymentType => text()(); // 'credit', 'cash'
  TextColumn get paymentMethod => text()(); // 'credit_card', 'fiado', 'transfer', 'app', 'cash'
  TextColumn get paymentSourceDetails => text().nullable()(); // 'Nequi', 'Bancolombia', etc.
}

```

#### 5. Tareas de Implementación Inmediata

1. **Actualizar Esquema de Base de Datos:** Modificar las tablas Drift para incluir los nuevos campos de `items.md`.
2. **Crear Seed Data:** Generar un script que pueble la BD con las categorías anidadas por defecto (ej. Gastos > Vivienda > Arriendo).
3. **UI de Nueva Transacción:**
* Diseñar una pantalla con `Form` validado.
* Implementar los `DropdownButtonFormField` (o widgets equivalentes) anidados para Categorías.
* Implementar la lógica condicional de "Medio de Pago" (Si elijo "App", mostrar selector de "Nequi/Daviplata").


4. **Integrar Terminología:** Usar un `LocalizationProvider` o clase de utilidades que cambie los labels del formulario según si el usuario está en "Modo Personal" o "Modo Profesional" (Guía `GUIA_MODO_PERSONAL.md`).

---

### ¿Cómo proceder ahora?

1. Copia el bloque anterior y pásaselo a `autocoder`.
2. Si `autocoder` tiene acceso de lectura a tus archivos locales, asegúrate de que indexe la carpeta `docs/` para que pueda leer la `GUIA_MODO_PERSONAL.md` cuando necesite los literales de texto exactos.

**Próximo paso que puedo hacer por ti:**
¿Deseas que genere el **código Dart específico para la migración de la base de datos Drift** (el schema version upgrade) para asegurar que no pierdas datos al agregar estos nuevos campos?