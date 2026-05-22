package com.example.lioluna

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class VocWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val WIDGET_INSTALLED_KEY = "flutter.hasHomeWidgetInstalled"
    }

    private fun markWidgetInstalled(context: Context) {
        context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(WIDGET_INSTALLED_KEY, true)
            .apply()
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        markWidgetInstalled(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        markWidgetInstalled(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.voc_widget).apply {
                val icon = widgetData.getString("widget_icon", "✅")
                val titleText = widgetData.getString("widget_title_text", "🌙 Void of course")
                val timesText = widgetData.getString("widget_times_text", "Start : N/A\nEnd   : N/A")

                setTextViewText(R.id.widget_icon_text, icon)
                setTextViewText(R.id.widget_title_text, titleText)
                setTextViewText(R.id.widget_times_text, timesText)

                val intent = android.content.Intent(context, MainActivity::class.java)
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
