package com.spendmind.spendmind

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import java.util.HashSet

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            val prefs = context.getSharedPreferences("SpendMindPrefs", Context.MODE_PRIVATE)
            
            for (sms in messages) {
                val body = sms.messageBody ?: continue
                val sender = sms.originatingAddress ?: "Unknown"
                val timestamp = sms.timestampMillis

                // Simple validation to check if the message looks like a transaction (UPI/Debit/Credit/Rs/INR)
                val bodyLower = body.toLowerCase()
                if (bodyLower.contains("rs") || bodyLower.contains("inr") || bodyLower.contains("debited") || bodyLower.contains("credited") || bodyLower.contains("spent") || bodyLower.contains("sent")) {
                    val jsonEntry = "{\"body\":\"" + escapeJson(body) + 
                                    "\",\"sender\":\"" + escapeJson(sender) + 
                                    "\",\"timestamp\":" + timestamp + 
                                    ",\"source\":\"SMS\"}"
                    
                    val pendingSet = prefs.getStringSet("pending_transactions", HashSet<String>()) ?: HashSet<String>()
                    val newSet = HashSet<String>(pendingSet)
                    newSet.add(jsonEntry)
                    prefs.edit().putStringSet("pending_transactions", newSet).apply()
                }
            }
        }
    }

    private fun escapeJson(str: String): String {
        return str.replace("\\", "\\\\")
                  .replace("\"", "\\\"")
                  .replace("\n", "\\n")
                  .replace("\r", "\\r")
    }
}
