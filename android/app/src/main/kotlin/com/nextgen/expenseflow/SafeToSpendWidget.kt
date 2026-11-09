package com.nextgen.expenseflowapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * "Safe to spend today" + "Spent today" with a quick-add button.
 *
 * Numbers are formatted by the Flutter side (`HomeWidgetSync`). When they're
 * from a previous day the widget asks the user to open the app instead of
 * showing stale figures, and when app lock is on it shows no amounts.
 */
class SafeToSpendWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val fresh = widgetData.getString("date", null) == today
        val hidden = widgetData.getBoolean("hidden", false)
        val safe = widgetData.getString("safe", "") ?: ""
        val spent = widgetData.getString("spent", "") ?: ""
        val over = widgetData.getBoolean("over", false)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_safe_to_spend)

            when {
                hidden -> {
                    views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_locked_title))
                    views.setTextViewText(R.id.widget_value, "🔒")
                    views.setViewVisibility(R.id.widget_spent, View.GONE)
                }
                !fresh -> {
                    views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_safe_title))
                    views.setTextViewText(R.id.widget_value, "—")
                    views.setTextViewText(R.id.widget_spent, context.getString(R.string.widget_open_app))
                    views.setViewVisibility(R.id.widget_spent, View.VISIBLE)
                }
                safe.isEmpty() -> {
                    views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_spent_title))
                    views.setTextViewText(R.id.widget_value, spent)
                    views.setTextViewText(R.id.widget_spent, context.getString(R.string.widget_no_budget))
                    views.setViewVisibility(R.id.widget_spent, View.VISIBLE)
                }
                else -> {
                    views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_safe_title))
                    views.setTextViewText(R.id.widget_value, safe)
                    views.setTextViewText(
                        R.id.widget_spent,
                        context.getString(R.string.widget_spent_today, spent),
                    )
                    views.setViewVisibility(R.id.widget_spent, View.VISIBLE)
                }
            }
            views.setTextColor(
                R.id.widget_value,
                if (over && fresh && !hidden) 0xFFD9534F.toInt() else 0xFF2B2F36.toInt(),
            )

            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("expenseflow://open"),
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_add,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("expenseflow://add-expense"),
                ),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
