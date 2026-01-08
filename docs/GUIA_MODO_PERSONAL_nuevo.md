# Guía de Finanzas Personales - Modo Personal (v1.1)

**Documento de Diseño para Usuarios No Empresariales**\
**Proyecto:** Finanzas Familiares AS\
**Basado en:** Estructura de cuentas "Finanzas Familiares" (Mermaid v2)\
**Fecha de Actualización:** 7 de enero de 2026

---

## Tabla de Contenido

1.  Filosofía del Modo Personal
2.  Principios Financieros Fundamentales
3.  Terminología Amigable
4.  Estructura de Información Personal (Adaptada)
5.  Categorías y Organización (Plan de Cuentas)
6.  Reportes y Visualizaciones
7.  Indicadores Financieros Personales
8.  Guía de Implementación Técnica
9.  Educación Financiera Integrada
10. Casos de Uso Prácticos

---

## 1. Filosofía del Modo Personal

### 1.1 Objetivo Principal
Hacer las finanzas familiares simples, comprensibles y adaptadas a la realidad colombiana.

* **NO es:** Un sistema contable rígido ni tributario.
* **SÍ es:** Un espejo de tu realidad financiera diaria (Nequi, efectivo, deudas reales).

### 1.2 Principios de Diseño
1.  **Simplicidad:** Usamos nombres reales (ej. "Nequi" en lugar de "Disponible Restringido").
2.  **Granularidad Educativa:** Desglosamos gastos como el mercado para entender hábitos de consumo (¿Compramos muchas verduras o mucho mecato?).
3.  **Contexto Local:** Incluye conceptos como el 4x1000 y servicios públicos locales (EDEQ, EPA).

---

## 2. Principios Financieros Fundamentales

Se mantienen los 5 principios originales (Causación, Negocio en Marcha, Comprensibilidad, Fiabilidad, Comparabilidad), pero con énfasis en:

* **Registro Inmediato:** Si pagas con Nequi, regístralo al instante.
* **Separación de Deudas e Impuestos:** Diferenciar el gasto del impuesto (el dinero que se pierde) de la deuda del impuesto (la obligación de pagarlo).

---

## 3. Terminología Amigable

| Término Contable | Término en App | Explicación Simple |
| :--- | :--- | :--- |
| Activos | **Lo que Tengo** | Efectivo, saldos en Nequi/Davivienda, inversiones. |
| Pasivos | **Lo que Debo** | Tarjetas, préstamos (Pichincha, Hipotecario), impuestos pendientes. |
| Patrimonio | **Mis Ahorros Netos** | Lo que realmente es tuyo si vendieras todo y pagaras todo. |
| Gastos | **Dinero que Sale** | Pagos de servicios, mercado, transporte, etc. |
| Ingresos | **Dinero que Entra** | Salario, ventas, rendimientos. |

---

## 4. Estructura de Información Personal ("El Balance")

Esta sección define cómo se organiza el dinero acumulado y las deudas vigentes.

### 4.1 "Lo que Tengo" (Activos)
Organización por disponibilidad:

* **💵 Efectivo:**
    * Billetera Personal.
    * Caja Menor Casa.
    * Alcancía / Ahorro Físico.
* **🏦 Bancos (Dinero Electrónico):**
    * **Cuentas de Ahorros:** Davivienda, Bancolombia.
    * **Billeteras Digitales:** Nequi, DaviPlata, DollarApp, PayPal.
* **📈 Inversiones:**
    * CDT / Fiducias.
    * Propiedades.

### 4.2 "Lo que Debo" (Pasivos)
Organización por tipo de acreedor:

* **💳 Tarjetas de Crédito:**
    * Visa / Master.
    * Tarjeta Almacenes.
* **📉 Préstamos:**
    * Hipotecario.
    * Vehículo.
    * Banco Pichincha (Libre inversión/Consumo).
    * Otros Préstamos.
* **📝 Cuentas por Pagar:**
    * Deudas Personales.
    * Servicios Vencidos.
    * **Impuestos por Pagar:** Vehicular, Predial, Renta (Obligaciones ya generadas pero no pagadas).

### 4.3 "Mis Ahorros Netos" (Patrimonio)
Cálculo automático: *Total Lo que Tengo - Total Lo que Debo*.

---

## 5. Categorías y Organización (Ingresos y Gastos)

Estructura detallada para registrar el flujo de dinero mensual.

### 5.1 "Dinero que Entra" (Ingresos)
* **Ingresos Fijos:** Salario / Nómina.
* **Ingresos Variables:** Ventas, Rendimientos Inversiones, Ganancias Ocasionales, Otros.

### 5.2 "Dinero que Sale" (Gastos)
Clasificación en 9 categorías maestras:

#### A. 🏛️ Impuestos
Gastos puros tributarios (no recuperables):

* Vehicular / Rodamiento.
* Predial / Vivienda.
* Renta / DIAN.
* 4x1000 / GMF.

#### B. 💡 Servicios Públicos/Privados
* **Domiciliarios:** EDEQ (Energía), EPA (Agua), EfiGas (Gas).
* **Conectividad:** Internet Hogar, Internet Móvil.
* **Vivienda:** Administración, Seguros Hogar.

#### C. 🥦 Alimentación
Desglose granular para mejor control:

* **Mercado:** Frutas, Verduras, Hortalizas, Legumbres, Granos, Especias, Lácteos, Cárnicos, Mecato, Panadería.
* **Comida preparada:** Restaurantes, Domicilios.
* **Suplementos:** OmniLife.

#### D. 🚌 Transporte
* Gasolina.
* Transporte Público.
* Mantenimiento Vehicular.
* Seguros (Ej. Seguros Chana).

#### E. 🎭 Entretenimiento
* Cine, Deporte, Viajes.

#### F. 🏥 Salud
* Medicamentos, Consultas Médicas, Seguros Salud.

#### G. 🎓 Educación
* Colegiatura, Cursos, Libros.

#### H. 🧹 Aseo
* Aseo Casa, Aseo Personal/Familia.

#### I. 🎁 Otros Gastos
* Regalos / Mesada.

---

## 6. Reportes y Visualizaciones

### 6.1 "Mi Resumen del Mes"
Vista simplificada que agrupa las subcategorías. Ejemplo:

* En lugar de mostrar "Frutas, Verduras, Carnes...", muestra un solo total de **Mercado**.
* Muestra **Impuestos** como un total (sumando 4x1000, Renta, etc.).

### 6.2 "¿Cómo Voy?" (Dashboard)
* **Saldo Disponible Real:** (Efectivo + Bancos) - (Cuentas por Pagar Inmediatas).
* **Semáforo de Presupuesto:** Alertas visuales si categorías como "Entretenimiento" superan el 80% del límite definido.

---

## 7. Indicadores Financieros Personales

### 7.1 Indicadores Básicos
* **Cobertura de Deuda:** ¿Tengo suficiente en Bancos/Efectivo para cubrir mis Tarjetas y Cuentas por Pagar inmediatas?
* **Peso del Mercado:** % de ingresos destinado a Alimentación (Categoría C).

### 7.2 Análisis de Hábitos (Nuevo)
* **Índice Saludable:** Comparación entre gasto en *Frutas/Verduras* vs. *Mecato/Domicilios*.
* **Costo Financiero:** Total gastado en *4x1000* + *Intereses TC*.

---

## 8. Guía de Implementación Técnica

### 8.1 Base de Datos (Drift)
Las tablas deben reflejar la jerarquía `Category -> Subcategory`.

* *Entidad:* `TransactionCategory`.
* *Atributos:* `id`, `name`, `icon` (emojis), `parent_id` (para la jerarquía), `type` (ingreso/gasto).

### 8.2 Lógica de "Impuestos"
El sistema debe permitir dos flujos:

1.  **Gasto Directo:** Pago el 4x1000 (Sale de Banco -> Gasto Impuesto).
2.  **Causación:** Me llega el recibo del Predial (Entra a Pasivo "Impuesto por Pagar" -> Gasto "Impuesto Predial"). Luego lo pago (Sale de Banco -> Disminuye Pasivo).

---

## 9. Educación Financiera Integrada

### 9.1 Tutoriales Interactivos
* **"Tu primera compra de Mercado":** Enseñar al usuario a no poner solo "Mercado $500.000", sino intentar desglosar al menos "Carnes" y "Granos" para mejor control.
* **"Cierres de Mes":** Recordatorio para conciliar saldos de Nequi/Davivienda con la App.

---

## 10. Casos de Uso Prácticos

### Caso: Control de Gastos Hormiga
El usuario nota que el saldo de **Nequi** baja rápido.

* **Acción:** Revisa la categoría **Gastos -> Impuestos -> 4x1000**.
* **Acción:** Revisa **Alimentación -> Mecato**.
* **Resultado:** Identifica fugas de dinero pequeñas pero frecuentes.

### Caso: Mantenimiento Vehicular

El usuario debe pagar el seguro del carro (Chana).
* **Registro:** Gasto -> Transporte -> Seguros Chana.
* **Pago:** Sale de -> Bancos -> Cuenta de Ahorros.

---
**Versión:** 1.1\
**Estado:** Aprobado para implementación en Flutter.