package com.ammarkhatib.veggie

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.util.TimeZone

/**
 * Daily quote widget. Reads the date-indexed queue written by
 * HomeWidgetService (Dart) and renders today's entry. updatePeriodMillis in
 * the provider XML re-renders roughly daily; because entries are keyed by
 * epoch-day, even a late trigger shows the correct quote.
 */
class VeggieWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val (text, category) = todaysQuote(context)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_quote).apply {
                setTextViewText(R.id.widget_quote_text, text)
                setTextViewText(R.id.widget_category, category)
                setOnClickPendingIntent(R.id.widget_root, launchIntent(context))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun todaysQuote(context: Context): Pair<String, String> {
        val fallback = Pair("Every plant-based meal plants a little hope.", "🌱 Veggie")
        val raw = HomeWidgetPlugin.getData(context)
            .getString("quote_queue", null) ?: return fallback

        return try {
            val now = System.currentTimeMillis()
            val localDay = (now + TimeZone.getDefault().getOffset(now)) / 86_400_000L
            val queue = JSONArray(raw)
            var best: Pair<String, String>? = null
            for (i in 0 until queue.length()) {
                val entry = queue.getJSONObject(i)
                if (entry.getLong("day") == localDay) {
                    best = Pair(
                        entry.getString("text"),
                        "${entry.getString("emoji")} ${entry.getString("category")}"
                    )
                    break
                }
            }
            // Queue exhausted (app not opened for 14+ days): show the last entry.
            best ?: queue.getJSONObject(queue.length() - 1).let {
                Pair(it.getString("text"), "${it.getString("emoji")} ${it.getString("category")}")
            }
        } catch (e: Exception) {
            fallback
        }
    }

    private fun launchIntent(context: Context): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent()
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
