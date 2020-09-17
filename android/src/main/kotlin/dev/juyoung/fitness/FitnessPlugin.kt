package dev.juyoung.fitness

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.fitness.Fitness
import com.google.android.gms.fitness.FitnessOptions
import com.google.android.gms.fitness.data.DataPoint
import com.google.android.gms.fitness.data.DataType
import com.google.android.gms.fitness.request.DataReadRequest
import dev.juyoung.fitness.extensions.getInt
import dev.juyoung.fitness.extensions.getLong
import dev.juyoung.fitness.extensions.getString
import dev.juyoung.fitness.extensions.timeUnit

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import timber.log.Timber
import java.util.concurrent.TimeUnit

class FitnessPlugin : FlutterPlugin, ActivityAware, MethodCallHandler, ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var activityBinding: ActivityPluginBinding
    private var pendingResult: Result? = null

    companion object {
        const val TAG = "[Plugins] Fitness"
        const val CHANNEL = "plugins.juyoung.dev/fitness"

        // permission request code
        const val GOOGLE_FIT_REQUEST_CODE = 2172

        // method names
        const val METHOD_HAS_PERMISSION = "hasPermission"
        const val METHOD_REQUEST_PERMISSION = "requestPermission"
        const val METHOD_REVOKE_PERMISSION = "revokePermission"
        const val METHOD_READ = "read"

        // argument keys
        const val ARG_DATE_FROM = "date_from"
        const val ARG_DATE_TO = "date_to"
        const val ARG_BUCKET_BY_TIME = "bucket_by_time"
        const val ARG_TIME_UNIT = "time_unit"

        // errors
        const val UNAUTHORIZED = "You cannot data read. user has not been authenticated."
        const val MISSING_REQUIRED_ARGUMENTS = "Missing Required Arguments."
        const val REQUEST_CANCELED = "Request Canceled"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Timber.i("$TAG::onAttachedToEngine::${binding.applicationContext}")

        context = binding.applicationContext
        MethodChannel(binding.binaryMessenger, CHANNEL).apply {
            channel = this
            setMethodCallHandler(this@FitnessPlugin)
        }

        subscribe()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Timber.i("$TAG::onDetachedFromEngine::${binding.applicationContext}")
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Timber.i("$TAG::onAttachedToActivity::${binding.activity}")
        attachToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        Timber.i("$TAG::onDetachedFromActivity")
        disposeActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Timber.i("$TAG::onReattachedToActivityForConfigChanges::${binding.activity}")
        attachToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Timber.i("$TAG::onDetachedFromActivityForConfigChanges")
        disposeActivity()
    }

    private fun attachToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding.also {
            it.addActivityResultListener(this)
        }
    }

    private fun disposeActivity() {
        activityBinding.removeActivityResultListener(this)
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                METHOD_HAS_PERMISSION -> hasPermission(call, result)
                METHOD_REQUEST_PERMISSION -> requestPermission(call, result)
                METHOD_REVOKE_PERMISSION -> revokePermission(call, result)
                METHOD_READ -> read(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Throwable) {
            result.error(TAG, e.message, null)
        }
    }

    private fun subscribe() {
        if (!isAuthorized()) {
            Timber.w("$TAG::subscribe::You cannot subscribe. user has not been authenticated.")
            return
        }

        Fitness.getRecordingClient(context, getFitnessAccount())
                .subscribe(DataType.TYPE_STEP_COUNT_CUMULATIVE)
                .addOnCompleteListener {
                    if (it.isSuccessful) {
                        Timber.i("$TAG::subscribe::Successfully subscribed.")
                    } else {
                        Timber.w("$TAG::subscribe::There was a problem subscribing.${it.exception}")
                    }
                }
    }

    private fun hasPermission(call: MethodCall, result: Result) {
        result.success(isAuthorized())
    }

    private fun requestPermission(call: MethodCall, result: Result) {
        pendingResult = result

        if (isAuthorized()) {
            result.success(true)
            pendingResult = null
            return
        }

        GoogleSignIn.requestPermissions(
                activityBinding.activity,
                GOOGLE_FIT_REQUEST_CODE,
                getFitnessAccount(),
                getFitnessOptions()
        )
    }

    // Related: https://github.com/android/fit-samples/issues/28
    private fun revokePermission(call: MethodCall, result: Result) {
        Fitness.getConfigClient(context, getFitnessAccount())
                .disableFit()
                .continueWithTask {
                    val signInOptions = GoogleSignInOptions.Builder()
                            .addExtension(FitnessOptions.builder().build())
                            .build()

                    GoogleSignIn.getClient(context, signInOptions).revokeAccess()
                }
                .addOnSuccessListener { result.success(true) }
                .addOnFailureListener {
                    Timber.e("$TAG::revokePermission::$it")
                    if (!isAuthorized()) {
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
    }

    @Throws
    private fun read(call: MethodCall, result: Result) {
        if (!isAuthorized()) {
            result.error(TAG, UNAUTHORIZED, null)
            return
        }

        val dateFrom = call.getLong(ARG_DATE_FROM) ?: throw Exception(MISSING_REQUIRED_ARGUMENTS)
        val dateTo = call.getLong(ARG_DATE_TO) ?: throw Exception(MISSING_REQUIRED_ARGUMENTS)
        val bucketByTime = call.getInt(ARG_BUCKET_BY_TIME) ?: 1
        val timeUnit = call.getString(ARG_TIME_UNIT)?.timeUnit ?: TimeUnit.DAYS

        val request = DataReadRequest.Builder()
                .aggregate(DataType.TYPE_STEP_COUNT_DELTA)
                .bucketByTime(bucketByTime, timeUnit)
                .setTimeRange(dateFrom, dateTo, TimeUnit.MILLISECONDS)
                .enableServerQueries()
                .build()

        Fitness.getHistoryClient(context, getFitnessAccount())
                .readData(request)
                .addOnSuccessListener { response ->
                    (response.dataSets + response.buckets.flatMap { it.dataSets })
                            .filterNot { it.isEmpty }
                            .flatMap { it.dataPoints }
                            .map(::dataPointToMap)
                            .let(result::success)
                }
                .addOnFailureListener { result.error(TAG, it.message, null) }
                .addOnCanceledListener { result.error(TAG, REQUEST_CANCELED, null) }
    }

    private fun dataPointToMap(dataPoint: DataPoint): Map<String, Any> {
        val field = dataPoint.dataType.fields.first()
        val source = dataPoint.originalDataSource.streamName

        return mapOf<String, Any>(
                "value" to dataPoint.getValue(field).asInt(),
                "date_from" to dataPoint.getStartTime(TimeUnit.MILLISECONDS),
                "date_to" to dataPoint.getEndTime(TimeUnit.MILLISECONDS),
                "source" to source
        )
    }

    private fun getFitnessOptions(): FitnessOptions {
        return FitnessOptions.builder()
                .addDataType(DataType.TYPE_STEP_COUNT_DELTA)
                .build()
    }

    private fun getFitnessAccount(): GoogleSignInAccount {
        return GoogleSignIn.getAccountForExtension(context, getFitnessOptions())
    }

    private fun isAuthorized(): Boolean {
        return GoogleSignIn.hasPermissions(getFitnessAccount(), getFitnessOptions())
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != GOOGLE_FIT_REQUEST_CODE || resultCode != Activity.RESULT_OK) {
            pendingResult?.success(false)
            pendingResult = null
            return false
        }

        subscribe()
        pendingResult?.success(true)
        pendingResult = null
        return true
    }
}
