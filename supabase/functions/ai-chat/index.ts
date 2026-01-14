import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import Anthropic from "npm:@anthropic-ai/sdk@0.39.0";

const anthropic = new Anthropic();

// Sistema de prompts para Fina (asistente financiero)
const FINA_SYSTEM_PROMPT = `Eres Fina, una asistente financiera amigable y experta para una app de finanzas personales colombiana.

Tu personalidad:
- Amable y cercana, pero profesional
- Usas lenguaje claro y simple
- Evitas jerga financiera compleja
- Respondes en español colombiano
- Eres empática con los problemas financieros

Tu conocimiento:
- Finanzas personales y familiares
- Presupuestos y ahorro
- Deudas y créditos
- Inversiones básicas
- Impuestos en Colombia
- Contexto económico colombiano (inflación, tasas, etc.)

Reglas:
- NUNCA des consejos de inversión específicos
- NUNCA pidas información personal sensible
- Siempre recomienda consultar profesionales para decisiones importantes
- Usa el contexto financiero del usuario para personalizar respuestas
- Mantén respuestas concisas (máximo 3 párrafos)`;

// Prompt para parsing de facturas
const RECEIPT_PARSE_PROMPT = `Eres un asistente especializado en extraer información de facturas y recibos colombianos.

Del texto OCR proporcionado, extrae:
1. amount: El monto TOTAL de la factura (número decimal, sin símbolos)
2. merchant: Nombre del comercio/establecimiento
3. date: Fecha en formato ISO (YYYY-MM-DD) si está disponible
4. category: Categoría sugerida (Alimentación, Restaurantes, Transporte, Servicios, Hogar, Entretenimiento, Salud, Otros)
5. confidence: Tu confianza en la extracción (0.0 a 1.0)

IMPORTANTE:
- El monto debe ser el TOTAL, no subtotales ni IVA por separado
- En Colombia los miles se separan con punto (45.000 = 45000)
- Si no puedes extraer algo, usa null
- Responde SOLO con JSON válido, sin explicaciones`;

Deno.serve(async (req: Request) => {
  try {
    const body = await req.json();
    const mode = body.mode || 'chat';

    if (mode === 'receipt-parse') {
      // Modo parsing de facturas con Haiku (más barato)
      return await handleReceiptParse(body.ocr_text);
    } else {
      // Modo chat normal con Sonnet
      return await handleChat(body);
    }
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
});

async function handleChat(body: any) {
  const { message, financial_context, conversation_history } = body;

  if (!message) {
    return new Response(
      JSON.stringify({ error: 'Message is required' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }

  // Construir contexto financiero para el prompt
  let contextString = '';
  if (financial_context && Object.keys(financial_context).length > 0) {
    contextString = `\n\nContexto financiero del usuario (${financial_context.period || 'mes actual'}):
- Ingresos: $${financial_context.summary?.totalIncome?.toLocaleString() || 0}
- Gastos: $${financial_context.summary?.totalExpenses?.toLocaleString() || 0}
- Balance: $${financial_context.summary?.balance?.toLocaleString() || 0}
- Patrimonio neto: $${financial_context.summary?.netWorth?.toLocaleString() || 0}`;
  }

  // Construir mensajes para la API
  const messages: any[] = [];

  if (conversation_history && Array.isArray(conversation_history)) {
    for (const msg of conversation_history) {
      messages.push({
        role: msg.role === 'user' ? 'user' : 'assistant',
        content: msg.content,
      });
    }
  }

  messages.push({
    role: 'user',
    content: message,
  });

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 1024,
    system: FINA_SYSTEM_PROMPT + contextString,
    messages: messages,
  });

  const assistantMessage = response.content[0].type === 'text'
    ? response.content[0].text
    : '';

  return new Response(
    JSON.stringify({ response: assistantMessage }),
    { headers: { 'Content-Type': 'application/json' } }
  );
}

async function handleReceiptParse(ocrText: string) {
  if (!ocrText || ocrText.trim() === '') {
    return new Response(
      JSON.stringify({ success: false, error: 'OCR text is required' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }

  const response = await anthropic.messages.create({
    model: 'claude-3-5-haiku-20241022',  // Haiku para bajo costo
    max_tokens: 256,
    system: RECEIPT_PARSE_PROMPT,
    messages: [
      {
        role: 'user',
        content: `Extrae la información de esta factura:\n\n${ocrText}`,
      },
    ],
  });

  const responseText = response.content[0].type === 'text'
    ? response.content[0].text
    : '{}';

  try {
    // Intentar parsear JSON de la respuesta
    const parsed = JSON.parse(responseText);
    return new Response(
      JSON.stringify({
        success: true,
        amount: parsed.amount,
        merchant: parsed.merchant,
        date: parsed.date,
        category: parsed.category,
        confidence: parsed.confidence || 0.8,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch {
    // Si no es JSON válido, intentar extraer datos manualmente
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Could not parse AI response',
        raw: responseText
      }),
      { status: 422, headers: { 'Content-Type': 'application/json' } }
    );
  }
}
