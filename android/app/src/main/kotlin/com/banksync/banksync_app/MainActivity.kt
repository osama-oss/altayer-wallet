package com.banksync.banksync_app

import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.UserNotAuthenticatedException
import android.util.Base64
import android.view.WindowManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL = "com.banksync.banksync_app/device_signing"
        private const val FAILURE_EVENTS = "com.banksync.banksync_app/device_signing_failures"
        private const val KEY_ALIAS = "banksync_biometric_signing_key"
    }

    private var pendingSignResult: MethodChannel.Result? = null
    private var failureEventSink: EventChannel.EventSink? = null

    /**
     * SECURITY: never restore framework state (Flutter/fragment view
     * hierarchy, navigation stack) across process death. `FlutterFragmentActivity`
     * has no `shouldRestoreAndSaveState()` override (that's `FlutterActivity`-only);
     * the equivalent here is discarding the incoming bundle so `super.onCreate`
     * always cold-starts — the splash / auth guard rebuilds the nav stack from
     * scratch instead of resurrecting whatever screen was open when the OS
     * killed the process.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, true)
        super.onCreate(null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, FAILURE_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    failureEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    failureEventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "signNonce" -> {
                    val nonce = call.argument<String>("nonce")
                    if (nonce.isNullOrBlank()) {
                        result.error("invalid_args", "nonce is required", null)
                    } else {
                        signNonceWithBiometric(nonce, result)
                    }
                }
                else -> {
                    try {
                        when (call.method) {
                            "setSecureFlag" -> {
                                // Per-screen screenshot/recents protection — toggled by
                                // Flutter only while a sensitive screen (balances, cards,
                                // transfers) is visible. Handler runs on the UI thread.
                                if (call.argument<Boolean>("secure") == true) {
                                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                                } else {
                                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                                }
                                result.success(true)
                            }
                            "getAndroidId" -> result.success(getAndroidId())
                            "hasEnrollmentKey" -> result.success(hasEnrollmentKey())
                            "createEnrollmentKey" -> result.success(createEnrollmentKey())
                            "deleteEnrollmentKey" -> {
                                deleteEnrollmentKey()
                                result.success(true)
                            }
                            else -> result.notImplemented()
                        }
                    } catch (ex: Exception) {
                        result.error("device_signing_error", ex.message, null)
                    }
                }
            }
        }
    }

    private fun emitBiometricAttemptFailed() {
        failureEventSink?.success("failed")
    }

    /// Settings.Secure.ANDROID_ID — a per-(app-signing-key) identifier that
    /// survives clearing app data/cache and reinstalls; resets only on factory
    /// reset or signing-key change. No runtime permission required.
    private fun getAndroidId(): String? {
        return Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
    }

    private fun hasEnrollmentKey(): Boolean {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        return keyStore.containsAlias(KEY_ALIAS)
    }

    private fun createEnrollmentKey(): String {
        deleteEnrollmentKey()
        val keyPairGenerator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            "AndroidKeyStore",
        )
        val builder = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN,
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setUserAuthenticationRequired(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            builder.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
        } else {
            @Suppress("DEPRECATION")
            builder.setUserAuthenticationValidityDurationSeconds(-1)
        }
        keyPairGenerator.initialize(builder.build())
        keyPairGenerator.generateKeyPair()
        return exportPublicKeyBase64()
    }

    private fun exportPublicKeyBase64(): String {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        val certificate = keyStore.getCertificate(KEY_ALIAS)
            ?: throw IllegalStateException("Enrollment key certificate missing")
        return Base64.encodeToString(certificate.publicKey.encoded, Base64.NO_WRAP)
    }

    private fun signNonceWithBiometric(nonceBase64: String, result: MethodChannel.Result) {
        if (pendingSignResult != null) {
            result.error("device_signing_error", "Signing already in progress", null)
            return
        }
        pendingSignResult = result
        try {
            val nonceBytes = Base64.decode(nonceBase64, Base64.DEFAULT)
            val keyStore = KeyStore.getInstance("AndroidKeyStore")
            keyStore.load(null)
            val entry = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry
            if (entry == null) {
                finishSignWithError("Enrollment key missing")
                return
            }
            val signature = Signature.getInstance("SHA256withECDSA")
            try {
                signature.initSign(entry.privateKey)
            } catch (ex: UserNotAuthenticatedException) {
                // Expected until BiometricPrompt unlocks the key.
            } catch (ex: Exception) {
                if (!isUserNotAuthenticated(ex)) {
                    finishSignWithError(ex.message ?: "Failed to prepare signing key")
                    return
                }
            }
            val executor = ContextCompat.getMainExecutor(this)
            val prompt = BiometricPrompt(
                this,
                executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(
                        authResult: BiometricPrompt.AuthenticationResult,
                    ) {
                        try {
                            val sig = authResult.cryptoObject?.signature
                                ?: throw IllegalStateException("Biometric signature unavailable")
                            sig.update(nonceBytes)
                            val signed = Base64.encodeToString(sig.sign(), Base64.NO_WRAP)
                            finishSignWithSuccess(signed)
                        } catch (ex: Exception) {
                            finishSignWithError(ex.message ?: "Signing failed")
                        }
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        if (errorCode != BiometricPrompt.ERROR_LOCKOUT &&
                            errorCode != BiometricPrompt.ERROR_LOCKOUT_PERMANENT
                        ) {
                            emitBiometricAttemptFailed()
                        }
                        finishSignWithError(errString.toString())
                    }

                    override fun onAuthenticationFailed() {
                        emitBiometricAttemptFailed()
                    }
                },
            )
            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle("Biometric login")
                .setSubtitle("Confirm your identity to sign in")
                .setNegativeButtonText("Cancel")
                .build()
            prompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(signature))
        } catch (ex: Exception) {
            finishSignWithError(ex.message ?: "Signing setup failed")
        }
    }

    private fun isUserNotAuthenticated(ex: Exception): Boolean {
        return ex is UserNotAuthenticatedException ||
            ex.javaClass.simpleName == "UserNotAuthenticatedException"
    }

    private fun finishSignWithSuccess(signed: String) {
        pendingSignResult?.success(signed)
        pendingSignResult = null
    }

    private fun finishSignWithError(message: String) {
        pendingSignResult?.error("device_signing_error", message, null)
        pendingSignResult = null
    }

    private fun deleteEnrollmentKey() {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)
        if (keyStore.containsAlias(KEY_ALIAS)) {
            keyStore.deleteEntry(KEY_ALIAS)
        }
    }
}
