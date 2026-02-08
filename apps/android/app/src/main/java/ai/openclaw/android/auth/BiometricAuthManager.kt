package ai.openclaw.android.auth

import android.content.Context
import android.content.SharedPreferences
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class BiometricAuthManager(private val context: Context) {
  private val prefs: SharedPreferences =
    context.getSharedPreferences("openclaw.biometric", Context.MODE_PRIVATE)

  private val _isAuthenticated = MutableStateFlow(false)
  val isAuthenticated: StateFlow<Boolean> = _isAuthenticated

  private val _authError = MutableStateFlow<String?>(null)
  val authError: StateFlow<String?> = _authError

  private val biometricManager = BiometricManager.from(context)

  var isBiometricEnabled: Boolean
    get() = prefs.getBoolean("biometric.enabled", false)
    set(value) {
      prefs.edit().putBoolean("biometric.enabled", value).apply()
    }

  val biometricType: BiometricType
    get() {
      return when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
        BiometricManager.BIOMETRIC_SUCCESS -> BiometricType.Available
        BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> BiometricType.NoHardware
        BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> BiometricType.Unavailable
        BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> BiometricType.NotEnrolled
        else -> BiometricType.Unknown
      }
    }

  val biometricDisplayName: String
    get() = when (biometricType) {
      BiometricType.Available -> "Biometric"
      BiometricType.NoHardware -> "Not Available"
      BiometricType.Unavailable -> "Unavailable"
      BiometricType.NotEnrolled -> "Not Enrolled"
      BiometricType.Unknown -> "Unknown"
    }

  fun resetAuthentication() {
    _isAuthenticated.value = false
    _authError.value = null
  }

  suspend fun authenticate(activity: FragmentActivity): Boolean = suspendCoroutine { continuation ->
    _authError.value = null

    if (!isBiometricEnabled) {
      _isAuthenticated.value = true
      continuation.resume(true)
      return@suspendCoroutine
    }

    val canAuthenticateBiometric = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
    val canAuthenticateDevice = biometricManager.canAuthenticate(BiometricManager.Authenticators.DEVICE_CREDENTIAL)

    val authenticators = when {
      canAuthenticateBiometric == BiometricManager.BIOMETRIC_SUCCESS ->
        BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL
      canAuthenticateDevice == BiometricManager.BIOMETRIC_SUCCESS ->
        BiometricManager.Authenticators.DEVICE_CREDENTIAL
      else -> {
        _authError.value = "No authentication method available"
        _isAuthenticated.value = false
        continuation.resume(false)
        return@suspendCoroutine
      }
    }

    val executor = ContextCompat.getMainExecutor(context)
    val promptInfo = BiometricPrompt.PromptInfo.Builder()
      .setTitle("Unlock OpenClaw")
      .setSubtitle("Authenticate to continue")
      .setAllowedAuthenticators(authenticators)
      .build()

    val biometricPrompt = BiometricPrompt(
      activity,
      executor,
      object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
          super.onAuthenticationError(errorCode, errString)
          when (errorCode) {
            BiometricPrompt.ERROR_USER_CANCELED,
            BiometricPrompt.ERROR_NEGATIVE_BUTTON,
            BiometricPrompt.ERROR_CANCELED -> {
              _authError.value = "Authentication cancelled"
            }
            else -> {
              _authError.value = errString.toString()
            }
          }
          _isAuthenticated.value = false
          continuation.resume(false)
        }

        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
          super.onAuthenticationSucceeded(result)
          _isAuthenticated.value = true
          _authError.value = null
          continuation.resume(true)
        }

        override fun onAuthenticationFailed() {
          super.onAuthenticationFailed()
          // Don't set error here, allow retry
        }
      },
    )

    biometricPrompt.authenticate(promptInfo)
  }

  enum class BiometricType {
    Available,
    NoHardware,
    Unavailable,
    NotEnrolled,
    Unknown,
  }
}
