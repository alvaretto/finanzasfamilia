// Supabase Edge Function: ai-chat
// Conecta con Claude 3.5 Sonnet via Anthropic API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FinancialContext {
  period: string
  summary: {
    total_income: number
    total_expenses: number
    balance: number
  }
  expenses_by_category: Record<string, {
    total: number
    subcategories?: Record<string, number>
  }>
  accounts: Array<{
    name: string
    type: string
    balance: number
  }>
  currency: string
}

interface ChatRequest {
  message: string
  financial_context: FinancialContext
  conversation_history?: Array<{
    role: 'user' | 'assistant'
    content: string
  }>
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Verificar autenticación
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verificar token con Supabase
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Parsear request
    const { message, financial_context, conversation_history = [] }: ChatRequest = await req.json()

    if (!message) {
      return new Response(
        JSON.stringify({ error: 'Message is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 3. Construir prompt del sistema
    const systemPrompt = `Eres Fina, una asistente financiera personal amigable y experta.

CONTEXTO FINANCIERO DEL USUARIO (en ${financial_context?.currency || 'COP'}):
${JSON.stringify(financial_context, null, 2)}

INSTRUCCIONES:
- Responde de forma concisa, útil y amigable
- Usa formato Markdown para estructurar tus respuestas
- Cuando muestres montos, usa formato de moneda colombiana ($ con separadores de miles)
- Si no tienes datos suficientes, indica qué información necesitas
- Ofrece consejos prácticos basados en los datos cuando sea relevante
- Mantén un tono positivo y motivador
- Si te preguntan por algo fuera de finanzas, redirígelos amablemente

CAPACIDADES:
- Análisis de gastos por categoría
- Comparaciones mensuales
- Sugerencias de ahorro
- Alertas de presupuesto
- Proyecciones simples`

    // 4. Preparar mensajes para Claude
    const messages = [
      ...conversation_history.slice(-10), // Últimos 10 mensajes de contexto
      { role: 'user' as const, content: message }
    ]

    // 5. Llamar a Anthropic API
    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: 'AI service not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        system: systemPrompt,
        messages: messages
      })
    })

    if (!anthropicResponse.ok) {
      const errorText = await anthropicResponse.text()
      console.error('Anthropic API error:', errorText)
      return new Response(
        JSON.stringify({ error: 'AI service error', details: errorText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const anthropicData = await anthropicResponse.json()
    const assistantMessage = anthropicData.content[0]?.text || 'No pude generar una respuesta.'

    // 6. Retornar respuesta
    return new Response(
      JSON.stringify({
        response: assistantMessage,
        usage: {
          input_tokens: anthropicData.usage?.input_tokens,
          output_tokens: anthropicData.usage?.output_tokens
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in ai-chat function:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
