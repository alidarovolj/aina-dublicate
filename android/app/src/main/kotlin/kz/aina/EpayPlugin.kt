package kz.aina

import android.app.Activity
import android.util.Log
import com.ss.halykepay.data.model.Invoice
import com.ss.halykepay.sdk.HalykEpaySdk
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class EpayPlugin(private val activity: Activity) : MethodCallHandler {
    private lateinit var halykEpaySdk: HalykEpaySdk
    private val TAG = "EpayPlugin"

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializePayment" -> {
                try {
                    Log.d(TAG, "Received initializePayment call with arguments: ${call.arguments}")
                    
                    val invoiceId = call.argument<String>("invoiceId")
                    val amount = call.argument<Int>("amount")
                    val postLink = call.argument<String>("postLink")
                    val failurePostLink = call.argument<String>("failurePostLink")
                    val backLink = call.argument<String>("backLink")
                    val failureBackLink = call.argument<String>("failureBackLink")
                    val description = call.argument<String>("description")
                    val terminal = call.argument<String>("terminal")
                    val auth = call.argument<Map<String, Any>>("auth")
                    val accessToken = auth?.get("access_token") as? String

                    if (invoiceId == null || amount == null || postLink == null ||
                        failurePostLink == null || backLink == null ||
                        failureBackLink == null || description == null ||
                        terminal == null || accessToken == null) {
                        val error = "Missing required parameters"
                        Log.e(TAG, error)
                        result.error("INVALID_ARGUMENTS", error, null)
                        return
                    }

                    Log.d(TAG, "Initializing HalykEpaySdk with terminal: $terminal")
                    halykEpaySdk = HalykEpaySdk.Builder()
                        .setMerchantId(terminal)
                        .setPassword(accessToken)
                        .setTestMode(true) // Set to false for production
                        .build()

                    val invoice = Invoice(
                        id = invoiceId,
                        amount = amount.toDouble(),
                        currency = "KZT",
                        accountID = call.argument<String>("accountId") ?: "1",
                        description = description,
                        postLink = postLink,
                        failurePostLink = failurePostLink,
                        backLink = backLink,
                        failureBackLink = failureBackLink,
                        isRecurrent = false
                    )

                    Log.d(TAG, "Created invoice: $invoice")

                    activity.runOnUiThread {
                        try {
                            Log.d(TAG, "Launching Epay payment screen")
                            halykEpaySdk.launchEpay(invoice)
                            result.success(mapOf("status" to "launched"))
                        } catch (e: Exception) {
                            val error = "Failed to launch payment screen: ${e.message}"
                            Log.e(TAG, error, e)
                            result.error("LAUNCH_ERROR", error, e.stackTraceToString())
                        }
                    }
                } catch (e: Exception) {
                    val error = "Payment initialization failed: ${e.message}"
                    Log.e(TAG, error, e)
                    result.error("PAYMENT_ERROR", error, e.stackTraceToString())
                }
            }
            else -> {
                Log.w(TAG, "Method not implemented: ${call.method}")
                result.notImplemented()
            }
        }
    }
} 