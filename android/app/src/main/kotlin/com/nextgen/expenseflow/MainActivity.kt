package com.nextgen.expenseflowapp

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

// FlutterFragmentActivity is required by local_auth (BiometricPrompt).
class MainActivity : FlutterFragmentActivity() {
    private val smsExecutor = Executors.newSingleThreadExecutor()

    /** Result waiting on the system SMS permission dialog. */
    private var pendingPermissionResult: MethodChannel.Result? = null

    private fun hasSmsPermission() =
        checkSelfPermission(Manifest.permission.READ_SMS) ==
            PackageManager.PERMISSION_GRANTED

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasSmsPermission())
                    "requestPermission" -> {
                        if (hasSmsPermission()) {
                            result.success(true)
                        } else if (pendingPermissionResult != null) {
                            result.error("IN_PROGRESS", "Permission request already running", null)
                        } else {
                            pendingPermissionResult = result
                            requestPermissions(
                                arrayOf(Manifest.permission.READ_SMS),
                                SMS_PERMISSION_REQUEST
                            )
                        }
                    }
                    "readInbox" -> {
                        if (!hasSmsPermission()) {
                            result.error("PERMISSION_DENIED", "READ_SMS not granted", null)
                            return@setMethodCallHandler
                        }
                        val since = call.argument<Number>("sinceMillis")?.toLong() ?: 0L
                        val limit = call.argument<Int>("limit") ?: 500
                        // Content-provider queries can be slow; keep them off
                        // the UI thread.
                        smsExecutor.execute {
                            try {
                                val messages = readInbox(since, limit)
                                runOnUiThread { result.success(messages) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("READ_FAILED", e.message, null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Inbox messages received after [sinceMillis], newest first. */
    private fun readInbox(sinceMillis: Long, limit: Int): List<Map<String, Any?>> {
        val messages = mutableListOf<Map<String, Any?>>()
        val cursor = contentResolver.query(
            Uri.parse("content://sms/inbox"),
            arrayOf("_id", "address", "body", "date"),
            "date > ?",
            arrayOf(sinceMillis.toString()),
            "date DESC"
        ) ?: return messages

        cursor.use {
            val idCol = it.getColumnIndexOrThrow("_id")
            val addressCol = it.getColumnIndexOrThrow("address")
            val bodyCol = it.getColumnIndexOrThrow("body")
            val dateCol = it.getColumnIndexOrThrow("date")
            while (it.moveToNext() && messages.size < limit) {
                messages.add(
                    mapOf(
                        "id" to it.getLong(idCol).toString(),
                        "address" to it.getString(addressCol),
                        "body" to it.getString(bodyCol),
                        "date" to it.getLong(dateCol)
                    )
                )
            }
        }
        return messages
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != SMS_PERMISSION_REQUEST) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    override fun onDestroy() {
        smsExecutor.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val SMS_CHANNEL = "com.nextgen.expenseflow/sms"
        private const val SMS_PERMISSION_REQUEST = 4201
    }
}
