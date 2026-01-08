# AI Assistant Architecture

## Overview

El Asistente Financiero IA ("Fina") permite a los usuarios hacer preguntas conversacionales sobre sus finanzas usando Claude 3.5 Sonnet.

## Arquitectura: Supabase Edge Functions (Recomendado)

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────────┐  │
│  │   Chat UI   │───▶│ AI Provider  │───▶│ Supabase Client    │  │
│  │  (Online)   │    │  (Riverpod)  │    │                    │  │
│  └─────────────┘    └──────────────┘    └─────────┬──────────┘  │
└───────────────────────────────────────────────────┼─────────────┘
                                                    │
                                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Supabase Edge Functions                       │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  POST /functions/v1/ai-chat                                 │ │
│  │  ┌─────────────────┐    ┌─────────────────────────────────┐ │ │
│  │  │ Validate JWT    │───▶│ Call Anthropic API              │ │ │
│  │  │ (User Auth)     │    │ (API Key secure in env)         │ │ │
│  │  └─────────────────┘    └─────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                                    │
                                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Anthropic API                               │
│                   Claude 3.5 Sonnet                              │
└─────────────────────────────────────────────────────────────────┘
```

## Por qué Edge Functions (no API Key directa)

| Aspecto | API Key en App | Edge Functions |
|---------|----------------|----------------|
| Seguridad | API Key expuesta en APK | API Key segura en servidor |
| Rate Limiting | Difícil controlar | Control total |
| Logging | No hay visibilidad | Logs en Supabase |
| Costos | Sin control | Puedes limitar por usuario |
| Actualización | Requiere nueva versión | Cambios instantáneos |

## Contexto Financiero (Privacy-First)

El app prepara un JSON anónimo con el resumen financiero del usuario:

```json
{
  "period": "2026-01",
  "summary": {
    "total_income": 5200000,
    "total_expenses": 3800000,
    "balance": 1400000
  },
  "expenses_by_category": {
    "Alimentacion": {
      "total": 1200000,
      "subcategories": {
        "Mercado": 800000,
        "Restaurantes": 300000,
        "Domicilios": 100000
      }
    },
    "Transporte": {
      "total": 450000,
      "subcategories": {
        "Gasolina": 350000,
        "Mantenimiento": 100000
      }
    }
  },
  "accounts": [
    {"name": "Nequi", "type": "digital_wallet", "balance": 450000},
    {"name": "Efectivo", "type": "cash", "balance": 120000}
  ],
  "currency": "COP"
}
```

**Principios:**
- No se envían transacciones individuales
- No se envían fechas exactas ni descripciones
- Solo agregados por categoría
- El usuario controla qué período consultar

## Edge Function: ai-chat

```typescript
// supabase/functions/ai-chat/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Anthropic from "npm:@anthropic-ai/sdk"

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY")
})

serve(async (req) => {
  // 1. Verificar autenticación
  const authHeader = req.headers.get("Authorization")
  if (!authHeader) {
    return new Response("Unauthorized", { status: 401 })
  }

  // 2. Parsear request
  const { message, financial_context } = await req.json()

  // 3. Construir prompt con contexto
  const systemPrompt = `Eres Fina, asistente financiero personal.
Contexto financiero del usuario (en COP):
${JSON.stringify(financial_context, null, 2)}

Responde de forma concisa y útil. Usa formato markdown.
Si no tienes datos suficientes, indica qué información necesitas.`

  // 4. Llamar a Claude
  const response = await anthropic.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 1024,
    system: systemPrompt,
    messages: [{ role: "user", content: message }]
  })

  return new Response(
    JSON.stringify({ response: response.content[0].text }),
    { headers: { "Content-Type": "application/json" } }
  )
})
```

## Flutter Integration

```dart
// lib/src/features/ai_assistant/data/ai_repository.dart
class AIRepository {
  final SupabaseClient _client;

  Future<String> sendMessage(String message, FinancialContext context) async {
    final response = await _client.functions.invoke(
      'ai-chat',
      body: {
        'message': message,
        'financial_context': context.toJson(),
      },
    );

    if (response.status != 200) {
      throw AIException('Error: ${response.status}');
    }

    return response.data['response'] as String;
  }
}
```

## UI Flow

```
┌─────────────────────────────────────────┐
│  Dashboard                              │
│  ┌───────────────────────────────────┐  │
│  │  Balance: $1,400,000 COP          │  │
│  │  [Gráficos...]                    │  │
│  └───────────────────────────────────┘  │
│                                         │
│                              ┌────────┐ │
│                              │  💬   │ │  ◀── FAB para abrir chat
│                              └────────┘ │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│  Chat con Fina                    [X]   │
│  ───────────────────────────────────────│
│  👤 ¿Cuánto gasté en mercado?           │
│                                         │
│  🤖 En enero 2026 gastaste $800,000     │
│     en mercado, distribuido así:        │
│     • Frutas: $150,000                  │
│     • Cárnicos: $280,000                │
│     • Lácteos: $120,000                 │
│     • ...                               │
│  ───────────────────────────────────────│
│  [Escribe tu pregunta...        ] [➤]  │
└─────────────────────────────────────────┘
```

## Requisitos de Implementación

### Fase 1: Backend (Supabase)
1. Crear Edge Function `ai-chat`
2. Configurar `ANTHROPIC_API_KEY` en secrets
3. Probar con curl

### Fase 2: Flutter
1. `AIRepository` con Supabase Functions
2. `FinancialContextBuilder` para generar JSON anónimo
3. `AIChatProvider` (Riverpod)
4. `AIChatScreen` con `flutter_markdown`

### Fase 3: Optimizaciones
1. Cache de respuestas similares
2. Streaming de respuestas (SSE)
3. Historial de conversación (local)

## Dependencias Flutter

```yaml
dependencies:
  flutter_markdown: ^0.7.4    # Renderizar respuestas
  # No necesitamos anthropic_sdk - usamos Edge Functions
```

## Variables de Entorno (Supabase)

```bash
# En Supabase Dashboard > Edge Functions > Secrets
ANTHROPIC_API_KEY=sk-ant-...
```

## Consideraciones de Costos

| Modelo | Input (1M tokens) | Output (1M tokens) |
|--------|-------------------|---------------------|
| Claude 3.5 Sonnet | $3.00 | $15.00 |

Estimación por usuario/mes (uso moderado):
- ~50 preguntas/mes
- ~500 tokens promedio por interacción
- **~$0.02 USD/usuario/mes**
