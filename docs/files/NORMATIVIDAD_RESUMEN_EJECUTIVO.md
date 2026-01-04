# Normatividad Contable Colombia - Resumen Ejecutivo

**Documento:** Guía Rápida de Referencia  
**Proyecto:** Finanzas Familiares AS  
**Fecha:** 4 de enero de 2026

---

## 1. Marco Legal Fundamental

### Leyes Base

- **Ley 1314 de 2009:** Marco general de contabilidad e información financiera
- **Decreto 2420 de 2015 (DUR):** Compilación de todas las normas contables

### Organismos Clave

- **CTCP:** Propone normas técnicas (www.ctcp.gov.co)
- **MinCIT + MinHacienda:** Aprueban y expiden normas
- **CGN:** Normas para sector público
- **JCC:** Vigilancia de contadores (no normalización)

---

## 2. Clasificación por Grupos

### Grupo 1: NIIF Plenas
**Quiénes:**

- Emisores de valores
- Entidades de interés público
- Empresas con >200 trabajadores O >30,000 SMMLV en activos

**Marco:** NIIF completas del IASB

### Grupo 2: NIIF para PYMES
**Quiénes:**

- Empresas que NO son Grupo 1 ni Grupo 3
- Típicamente: <200 trabajadores Y <30,000 SMMLV

**Marco:** NIIF para PYMES (35 secciones simplificadas)

### Grupo 3: Contabilidad Simplificada (NIF)
**Quiénes:**

- Microempresas que cumplan TODOS:
  - Sin inversiones en subsidiarias/asociadas
  - No obligadas a consolidar
  - Sin pagos basados en acciones
  - Ingresos anuales < topes por sector (ver tabla)

**Marco:** Anexo 3 DUR 2420/2015 (NO es NIIF)

**Topes 2025 (UVB 2024 = $10,951):**

| Sector | Tope UVB | Tope Pesos |
|--------|----------|------------|
| Manufactura | 23,563 | $258M |
| Servicios | 13,110 | $143M |
| Comercio | 44,769 | $490M |
| Agropecuario | 32,263 | $353M |
| Construcción | 32,263 | $353M |

---

## 3. Aplicación al Proyecto

### Usuarios Típicos
**Mayoría:** Personas naturales NO obligadas a contabilidad

- Sin requisitos normativos formales
- Pueden aplicar principios voluntariamente

**Minoría:** Microempresas Grupo 3

- Obligadas a llevar contabilidad
- Deben cumplir Anexo 3 DUR 2420/2015

### Principios Aplicables (Todos los Usuarios)

**Del Marco NIF Grupo 3:**

1. **Causación/Devengo:** Registrar cuando ocurre, no cuando se paga
2. **Negocio en Marcha:** Continuidad
3. **Comprensibilidad:** Información clara
4. **Relevancia:** Datos útiles para decisiones
5. **Fiabilidad:** Precisión y verificabilidad
6. **Comparabilidad:** Seguimiento temporal

---

## 4. Estructura de Reportes Sugerida

### Para Usuarios Personales (Terminología Amigable)

**"Mi Balance Personal"** (Estado de Situación Financiera)
```
LO QUE TENGO (Activos)
├── Efectivo y Bancos
├── Inversiones
└── Otros bienes

LO QUE DEBO (Pasivos)
├── Tarjetas de Crédito
├── Préstamos
└── Otras deudas

MIS AHORROS = Lo que tengo - Lo que debo
```

**"Mis Ingresos y Gastos"** (Estado de Resultados)
```
INGRESOS
├── Salario
├── Negocios
└── Otros

GASTOS
├── Vivienda
├── Alimentación
├── Transporte
└── Otros

AHORRO DEL MES = Ingresos - Gastos
```

### Para Microempresas Grupo 3 (Formal)

**Estados Obligatorios:**

1. Estado de Situación Financiera
2. Estado de Resultados
3. Notas a los Estados Financieros

**NO se requiere:**

- Estado de Flujos de Efectivo
- Estado de Cambios en Patrimonio

**Base de medición:** Costo Histórico

---

## 5. Categorías de Cuentas Recomendadas

### Activos (Lo que tienes)

1. Efectivo y Equivalentes
2. Cuentas Bancarias
3. Inversiones
4. Cuentas por Cobrar
5. Propiedades (opcional)

### Pasivos (Lo que debes)

1. Tarjetas de Crédito
2. Préstamos Bancarios
3. Créditos de Consumo
4. Cuentas por Pagar

### Ingresos

1. Salarios
2. Honorarios/Negocios
3. Rentas
4. Inversiones
5. Otros

### Gastos

1. Vivienda (arriendo/cuota)
2. Alimentación
3. Transporte
4. Servicios Públicos
5. Educación
6. Salud
7. Entretenimiento
8. Gastos Financieros
9. Otros

---

## 6. Indicadores Financieros Personales

### Liquidez
```
Liquidez = (Efectivo + Bancos + Inversiones Líquidas) / Pasivos Corto Plazo
Ideal: > 1.0
```

### Capacidad de Ahorro
```
Tasa de Ahorro = (Ingresos - Gastos) / Ingresos × 100
Recomendado: > 20%
```

### Endeudamiento
```
Nivel Deuda = Total Deudas / Total Activos × 100
Ideal: < 40%
```

### Fondo de Emergencia
```
Meses Cobertura = Ahorros / Gastos Fijos Mensuales
Recomendado: 6 meses
```

---

## 7. Implementación Técnica

### Configuración de Usuario
```dart
enum TipoUsuario {
  PERSONAL,           // Mayoría - sin obligación contable
  MICROEMPRESA_GRUPO3 // Obligado a contabilidad
}

class ConfigUsuario {
  TipoUsuario tipo;
  bool reportesFormales;
  bool terminologiaContable;
  
  // Si es MICROEMPRESA_GRUPO3:
  // - Reportes según Anexo 3 DUR 2420/2015
  // - Estados financieros formales
  // - Exportación para contador
}
```

### Base de Datos Sugerida
```sql
-- Cuentas (Activos/Pasivos)
CREATE TABLE cuentas (
  id UUID PRIMARY KEY,
  usuario_id UUID NOT NULL,
  tipo VARCHAR NOT NULL, -- 'efectivo', 'banco', 'inversion', 'credito'
  nombre VARCHAR NOT NULL,
  saldo DECIMAL(15,2) DEFAULT 0,
  moneda VARCHAR(3) DEFAULT 'COP'
);

-- Transacciones (Movimientos)
CREATE TABLE transacciones (
  id UUID PRIMARY KEY,
  cuenta_id UUID REFERENCES cuentas(id),
  tipo VARCHAR NOT NULL, -- 'ingreso', 'gasto', 'transferencia'
  categoria_id UUID REFERENCES categorias(id),
  monto DECIMAL(15,2) NOT NULL,
  fecha DATE NOT NULL,
  descripcion TEXT,
  fecha_registro TIMESTAMP DEFAULT NOW() -- Principio de causación
);

-- Categorías (Plan de Cuentas)
CREATE TABLE categorias (
  id UUID PRIMARY KEY,
  nombre VARCHAR NOT NULL,
  tipo VARCHAR NOT NULL, -- 'ingreso', 'gasto'
  padre_id UUID REFERENCES categorias(id) -- Jerarquía
);

-- Presupuestos
CREATE TABLE presupuestos (
  id UUID PRIMARY KEY,
  categoria_id UUID REFERENCES categorias(id),
  monto_planificado DECIMAL(15,2) NOT NULL,
  periodo_inicio DATE NOT NULL,
  periodo_fin DATE NOT NULL
);
```

---

## 8. Funcionalidades Clave

### Modo Personal (Default)

- ✅ Registro de ingresos y gastos
- ✅ Categorización automática
- ✅ Presupuestos mensuales
- ✅ Balance personal
- ✅ Indicadores financieros
- ✅ Educación financiera integrada
- ✅ Asistente IA (Fina)

### Modo Profesional (Microempresas)

- ✅ Todo lo anterior +
- ✅ Estados financieros formales (Grupo 3)
- ✅ Terminología contable técnica
- ✅ Exportación para contador
- ✅ Notas a estados financieros
- ✅ Cumplimiento Anexo 3 DUR 2420/2015

---

## 9. Educación Financiera

### Glosario Integrado
```dart
Map<String, String> glosario = {
  'Activo': 'Todo lo que posees con valor (dinero, inversiones)',
  'Pasivo': 'Todo lo que debes (préstamos, tarjetas)',
  'Patrimonio': 'Tu riqueza neta (Activos - Pasivos)',
  'Causación': 'Registrar cuando ocurre, no cuando se paga',
  'Liquidez': 'Capacidad de pagar deudas inmediatas',
};
```

### Consejos Contextuales
```dart
if (nivelEndeudamiento > 40%) {
  mostrarAlerta("""
  Tu nivel de deuda es alto (${nivelEndeudamiento}%).
  
  Recomendación:

  - Prioriza pagar deudas con mayor interés
  - Reduce gastos no esenciales
  - No adquieras nuevas deudas
  
  ¿Quieres un plan de reducción de deuda?
  """);
}
```

---

## 10. Actualizaciones Normativas 2024-2025

### Grupo 3 (NIF)

- **Sin cambios** (Concepto CTCP 0019/2025)
- Marco vigente: Anexo 3 DUR 2420/2015
- Topes vigentes: Decreto 1670/2021

### Grupo 1 y 2 (NIIF)

- Enmiendas en trámite (proyecto decreto julio 2025)
- Vigencia esperada: enero 2026
- Cambios menores: NIC 1, NIC 7, NIC 12, NIIF 16

### CGN (Sector Público)

- Resolución 450/2024 (vigente desde enero 2025)
- No aplica al proyecto (sector privado)

---

## 11. Contactos Útiles

**CTCP (Consultas Técnicas):**

- Web: www.ctcp.gov.co
- Email: consultasctcp@mincit.gov.co
- Tel: (601) 6072530
- Línea gratuita: 01 8000 958283

**Normatividad Online:**

- Decretos: www.funcionpublica.gov.co/eva/gestornormativo
- SUIN: www.suin-juriscol.gov.co
- MinCIT: www.mincit.gov.co

---

## 12. Checklist de Implementación

### Fase 1: Base

- [ ] Definir estructura de cuentas (activos, pasivos)
- [ ] Crear categorías de ingresos y gastos
- [ ] Implementar registro de transacciones
- [ ] Aplicar principio de causación

### Fase 2: Reportes

- [ ] Balance personal (Situación Financiera)
- [ ] Resumen ingresos/gastos (Resultados)
- [ ] Indicadores financieros básicos
- [ ] Gráficos y visualizaciones

### Fase 3: Funcionalidades Avanzadas

- [ ] Presupuestos por categoría
- [ ] Metas de ahorro
- [ ] Alertas y notificaciones
- [ ] Asistente IA con contexto contable

### Fase 4: Modo Profesional (Opcional)

- [ ] Configuración tipo usuario (Personal/Microempresa)
- [ ] Estados financieros formales Grupo 3
- [ ] Exportación para contador
- [ ] Cumplimiento normativo Anexo 3

---

## 13. Decisiones de Diseño Clave

### Terminología
**Personal (Default):** "Balance Personal", "Mis Ahorros", "Lo que tengo"  
**Profesional:** "Estado de Situación Financiera", "Patrimonio", "Activos"

### Frecuencia de Reportes
**Personal:** Diario, semanal, mensual (flexible)  
**Microempresa:** Mínimo anual (requisito Grupo 3)

### Base de Medición
**Todos:** Costo Histórico (valores de adquisición)  
No se requiere valor razonable ni técnicas complejas

### Validaciones

- ✅ Saldo no negativo en cuentas de ahorro
- ✅ Fecha de transacción ≤ hoy
- ✅ Monto > 0
- ✅ Categoría obligatoria
- ✅ Coherencia en transferencias (partida doble)

---

## 14. Próximos Pasos

1. **Validar** interpretación normativa con contador público
2. **Diseñar** prototipos de reportes
3. **Probar** con usuarios reales (personal y microempresas)
4. **Iterar** según feedback
5. **Documentar** casos de uso específicos

---

## Referencias Rápidas

**Ley principal:** 1314/2009  
**Decreto base:** 2420/2015  
**Grupo 3:** Anexo 3 + Decreto 1670/2021  
**Consultas:** CTCP - www.ctcp.gov.co

---

**Última actualización:** 4 enero 2026  
**Versión:** 1.0  
**Próxima revisión:** Julio 2026

---

## Notas Importantes

⚠️ **Disclaimer:** Este documento es informativo. Para interpretaciones legales vinculantes, consultar con contador público titulado.

✅ **Principio clave:** Aunque la mayoría de usuarios NO están obligados a contabilidad formal, aplicar principios contables mejora organización y control financiero.

📊 **Enfoque dual:** La app debe servir tanto a usuarios personales (mayoría) como a microempresas obligadas (minoría).
