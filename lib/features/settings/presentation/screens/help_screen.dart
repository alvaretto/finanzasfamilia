import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.blue.shade700, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Centro de Ayuda',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Encuentra respuestas a las preguntas más frecuentes',
                          style: TextStyle(color: Colors.blue.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Primeros pasos
          _buildSection(
            context,
            title: 'Primeros Pasos',
            icon: Icons.rocket_launch,
            items: [
              _HelpItem(
                question: '¿Cómo crear mi primera cuenta?',
                answer: '1. Ve a la pestaña "Cuentas"\n'
                    '2. Toca el botón "+" flotante\n'
                    '3. Completa el formulario:\n'
                    '   • Nombre (ej: "Banco Davivienda")\n'
                    '   • Tipo (Banco, Efectivo, etc.)\n'
                    '   • Saldo inicial\n'
                    '4. Toca "Crear"\n\n'
                    'Tu cuenta estará lista para usar.',
              ),
              _HelpItem(
                question: '¿Cómo registrar un gasto?',
                answer: '1. Ve a la pestaña "Movimientos"\n'
                    '2. Toca el botón "Nuevo Movimiento"\n'
                    '3. Selecciona tipo "Gasto"\n'
                    '4. Ingresa el monto (sin signo -)\n'
                    '5. Selecciona categoría (ej: Comida)\n'
                    '6. Agrega descripción opcional\n'
                    '7. Toca "Guardar"\n\n'
                    'El gasto se restará automáticamente del saldo.',
              ),
              _HelpItem(
                question: '¿Cómo funciona la sincronización?',
                answer: 'Finanzas Familiares usa sincronización automática:\n\n'
                    '• Offline-First: Puedes trabajar sin conexión\n'
                    '• Sync Automático: Se sincroniza en segundo plano\n'
                    '• Sync Manual: En Configuración → Sincronización\n'
                    '• Multi-dispositivo: Accede desde cualquier lugar\n\n'
                    'Tus datos están seguros en Supabase.',
              ),
            ],
          ),

          // Presupuestos y Metas
          _buildSection(
            context,
            title: 'Presupuestos y Metas',
            icon: Icons.pie_chart,
            items: [
              _HelpItem(
                question: '¿Cómo crear un presupuesto?',
                answer: '1. Ve a la pestaña "Presupuestos"\n'
                    '2. Toca el botón "+"\n'
                    '3. Selecciona una categoría\n'
                    '4. Establece el límite mensual\n'
                    '5. Selecciona el periodo (Semanal/Mensual/Anual)\n'
                    '6. Toca "Crear"\n\n'
                    'Verás el progreso en tiempo real y alertas si te excedes.',
              ),
              _HelpItem(
                question: '¿Qué es una meta de ahorro?',
                answer: 'Las metas te ayudan a ahorrar para objetivos específicos:\n\n'
                    '• Vacaciones\n'
                    '• Comprar un auto\n'
                    '• Fondo de emergencia\n\n'
                    'Puedes hacer aportes cuando quieras y ver tu progreso en %.',
              ),
              _HelpItem(
                question: '¿Cómo funcionan los recurrentes?',
                answer: 'Los recurrentes automatizan pagos e ingresos repetitivos:\n\n'
                    '1. Ve a Configuración → Recurrentes\n'
                    r'2. Crea un recurrente (ej: Netflix $26,900/mes)' '\n'
                    '3. Selecciona frecuencia (Diaria, Semanal, Mensual, etc.)\n'
                    '4. La app te recordará cuando llegue la fecha\n'
                    '5. Toca "Registrar transacción" para crear el movimiento real\n\n'
                    'Ahorra tiempo y nunca olvides un pago.',
              ),
            ],
          ),

          // Analítica y Reportes
          _buildSection(
            context,
            title: 'Analítica y Reportes',
            icon: Icons.analytics,
            items: [
              _HelpItem(
                question: '¿Qué es el análisis de gastos hormiga?',
                answer: 'Los gastos hormiga son compras pequeñas y frecuentes que '
                    'se suman con el tiempo:\n\n'
                    '• Cafés diarios\n'
                    '• Snacks\n'
                    '• Aplicaciones\n\n'
                    'La app identifica automáticamente estos gastos y te muestra '
                    'cuánto representan de tu presupuesto total.',
              ),
              _HelpItem(
                question: '¿Cómo exportar mis datos?',
                answer: '1. Ve a Configuración → Exportar Datos\n'
                    '2. Selecciona tipo (Transacciones o Cuentas)\n'
                    '3. Selecciona formato (PDF o CSV)\n'
                    '4. Elige el periodo\n'
                    '5. Toca "Exportar y Compartir"\n\n'
                    'Podrás enviar el archivo por WhatsApp, email, etc.',
              ),
              _HelpItem(
                question: '¿Qué es Fina, el asistente AI?',
                answer: 'Fina es tu asistente financiero con inteligencia artificial:\n\n'
                    '• Analiza tus hábitos de gasto\n'
                    '• Te da consejos personalizados\n'
                    '• Responde preguntas sobre tus finanzas\n'
                    '• Identifica oportunidades de ahorro\n\n'
                    'Habla con Fina desde el ícono de chat en el Dashboard.',
              ),
            ],
          ),

          // Seguridad y Privacidad
          _buildSection(
            context,
            title: 'Seguridad y Privacidad',
            icon: Icons.security,
            items: [
              _HelpItem(
                question: '¿Mis datos están seguros?',
                answer: 'Sí, usamos múltiples capas de seguridad:\n\n'
                    '• Encriptación end-to-end\n'
                    '• Autenticación con Supabase\n'
                    '• Biometría (huella/Face ID)\n'
                    '• Bloqueo automático\n'
                    '• Row Level Security (RLS)\n\n'
                    'Solo tú puedes ver tus datos financieros.',
              ),
              _HelpItem(
                question: '¿Puedo usar biometría?',
                answer: '1. Ve a Configuración → Seguridad\n'
                    '2. Activa "Biometría"\n'
                    '3. Configura el bloqueo automático (1-30 min)\n\n'
                    'La app pedirá tu huella/Face ID al abrir.',
              ),
              _HelpItem(
                question: '¿Cómo cambio mi contraseña?',
                answer: '1. Ve a Configuración → Cambiar Contraseña\n'
                    '2. Ingresa tu nueva contraseña (mín. 8 caracteres)\n'
                    '3. Debe contener letras y números\n'
                    '4. Confirma la contraseña\n'
                    '5. Toca "Guardar"\n\n'
                    'Nota: Deberás iniciar sesión nuevamente.',
              ),
            ],
          ),

          // Respaldos y Datos
          _buildSection(
            context,
            title: 'Respaldos y Datos',
            icon: Icons.backup,
            items: [
              _HelpItem(
                question: '¿Cómo crear un respaldo?',
                answer: '1. Ve a Configuración → Respaldo\n'
                    '2. Toca "Crear Respaldo"\n'
                    '3. Se genera un archivo JSON\n'
                    '4. Compártelo y guárdalo en lugar seguro\n\n'
                    'El respaldo incluye cuentas, transacciones, presupuestos, '
                    'metas y recurrentes.',
              ),
              _HelpItem(
                question: '¿Cómo restaurar un respaldo?',
                answer: '1. Ve a Configuración → Respaldo\n'
                    '2. Toca "Restaurar desde Archivo"\n'
                    '3. Selecciona el archivo .json\n'
                    '4. Confirma (REEMPLAZARÁ datos actuales)\n'
                    '5. Espera la sincronización\n\n'
                    '¡IMPORTANTE! Crea un respaldo antes de restaurar.',
              ),
            ],
          ),

          // Familia
          _buildSection(
            context,
            title: 'Mi Familia',
            icon: Icons.family_restroom,
            items: [
              _HelpItem(
                question: '¿Cómo compartir finanzas con mi familia?',
                answer: '1. Ve a Configuración → Mi Familia\n'
                    '2. Toca "+" para crear una familia\n'
                    '3. Ingresa el nombre (ej: "Familia García")\n'
                    '4. Se genera un código de 6 dígitos\n'
                    '5. Comparte el código con tus familiares\n'
                    '6. Ellos pueden unirse en la misma pantalla\n\n'
                    'Todos verán las mismas cuentas y transacciones.',
              ),
              _HelpItem(
                question: '¿Qué son los roles en la familia?',
                answer: 'Hay 4 roles con diferentes permisos:\n\n'
                    '• Propietario: Control total, puede eliminar familia\n'
                    '• Admin: Gestionar miembros\n'
                    '• Miembro: Editar datos\n'
                    '• Visor: Solo lectura\n\n'
                    'El creador de la familia es siempre Propietario.',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Contacto
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const Icon(Icons.contact_support, size: 48, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '¿No encontraste lo que buscabas?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Envíanos tus comentarios o reporta un problema',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navegar a feedback screen (se implementará después)
                    },
                    icon: const Icon(Icons.feedback),
                    label: const Text('Enviar Comentarios'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_HelpItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...items,
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _HelpItem extends StatefulWidget {
  final String question;
  final String answer;

  const _HelpItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_HelpItem> createState() => _HelpItemState();
}

class _HelpItemState extends State<_HelpItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
