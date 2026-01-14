package app.finanzasfamiliares

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.balance_widget).apply {
                // Obtener datos del SharedPreferences (guardados desde Flutter)
                val balance = widgetData.getString("balance", "$0") ?: "$0"
                val updated = widgetData.getString("updated", "Sin datos") ?: "Sin datos"

                // Actualizar textos del widget
                setTextViewText(R.id.widget_balance, balance)
                setTextViewText(R.id.widget_updated, "Actualizado: $updated")
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
