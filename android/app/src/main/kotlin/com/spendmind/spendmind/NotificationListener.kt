package com.spendmind.spendmind

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.HashSet

class NotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: ""
        val extras = sbn.notification.extras ?: return
        
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        
        if (text.isEmpty()) return

        // Filters: focus on payment apps or notifications containing transaction amounts
        val isPaymentApp = packageName.contains("paisa.user") || // Google Pay
                           packageName.contains("phonepe") ||     // PhonePe
                           packageName.contains("paytm") ||       // Paytm
                           packageName.contains("amazon.mpay") ||  // Amazon Pay
                           packageName.contains("fampay")          // FamPay

        val textLower = text.toLowerCase()
        val hasTransactionKeywords = textLower.contains("rs") || 
                                     textLower.contains("inr") || 
                                     textLower.contains("₹") || 
                                     textLower.contains("debited") || 
                                     textLower.contains("credited") || 
                                     textLower.contains("paid") || 
                                     textLower.contains("sent") || 
                                     textLower.contains("received")

        if (isPaymentApp || hasTransactionKeywords) {
            val prefs = getSharedPreferences("SpendMindPrefs", Context.MODE_PRIVATE)
            val timestamp = sbn.postTime
            val sender = if (title.isNotEmpty()) "$title ($packageName)" else packageName

            val jsonEntry = "{\"body\":\"" + escapeJson(text) + 
                            "\",\"sender\":\"" + escapeJson(sender) + 
                            "\",\"timestamp\":" + timestamp + 
                            ",\"source\":\"Notification\"}"

            val pendingSet = prefs.getStringSet("pending_transactions", HashSet<String>()) ?: HashSet<String>()
            val newSet = HashSet<String>(pendingSet)
            newSet.add(jsonEntry)
            prefs.edit().putStringSet("pending_transactions", newSet).apply()
        }
    }

    private fun escapeJson(str: String): String {
        return str.replace("\\", "\\\\")
                  .replace("\"", "\\\"")
                  .replace("\n", "\\n")
                  .replace("\r", "\\r")
    }
}
