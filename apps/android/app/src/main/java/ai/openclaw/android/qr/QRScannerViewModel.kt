package ai.openclaw.android.qr

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import ai.openclaw.android.NodeApp
import ai.openclaw.android.NodeForegroundService
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class GatewayQRConfig(
  val url: String,
  val token: String? = null,
  val displayName: String? = null,
)

class QRScannerViewModel(app: Application) : AndroidViewModel(app) {
  private val runtime = (app as NodeApp).runtime
  private val context = app.applicationContext
  private val json = Json { ignoreUnknownKeys = true }

  private val _scanError = MutableStateFlow<String?>(null)
  val scanError: StateFlow<String?> = _scanError

  private val _isConnecting = MutableStateFlow(false)
  val isConnecting: StateFlow<Boolean> = _isConnecting

  private val _hasCameraPermission = MutableStateFlow(false)
  val hasCameraPermission: StateFlow<Boolean> = _hasCameraPermission

  private val _isScanning = MutableStateFlow(false)
  val isScanning: StateFlow<Boolean> = _isScanning

  private val _shouldDismiss = MutableStateFlow(false)
  val shouldDismiss: StateFlow<Boolean> = _shouldDismiss

  fun setCameraPermission(granted: Boolean) {
    _hasCameraPermission.value = granted
    if (!granted) {
      _scanError.value = "Camera permission denied"
    }
  }

  fun setScanning(scanning: Boolean) {
    _isScanning.value = scanning
  }

  fun setScanError(error: String?) {
    _scanError.value = error
  }

  fun handleScannedCode(code: String) {
    viewModelScope.launch {
      _scanError.value = null

      try {
        val config = json.decodeFromString<GatewayQRConfig>(code)
        connectToGateway(config)
      } catch (e: Exception) {
        _scanError.value = "Invalid gateway configuration: ${e.message}"
        delay(2000)
        _scanError.value = null
      }
    }
  }

  private suspend fun connectToGateway(config: GatewayQRConfig) {
    _isConnecting.value = true

    try {
      val url = parseUrl(config.url)
      if (url == null) {
        _scanError.value = "Invalid gateway URL"
        _isConnecting.value = false
        return
      }

      val (host, port, useTLS) = url

      runtime.setManualEnabled(true)
      runtime.setManualHost(host)
      runtime.setManualPort(port)
      runtime.setManualTls(useTLS)

      if (config.token != null) {
        runtime.prefs.saveGatewayToken(config.token)
      }

      NodeForegroundService.start(context)
      runtime.connectManual()

      delay(1000)
      _shouldDismiss.value = true
    } catch (e: Exception) {
      _scanError.value = "Connection failed: ${e.message}"
    } finally {
      _isConnecting.value = false
    }
  }

  private fun parseUrl(urlString: String): Triple<String, Int, Boolean>? {
    return try {
      val regex = Regex("^(ws|wss)://([^:]+):(\\d+)")
      val match = regex.find(urlString) ?: return null

      val scheme = match.groupValues[1]
      val host = match.groupValues[2]
      val port = match.groupValues[3].toIntOrNull() ?: return null
      val useTLS = scheme == "wss"

      Triple(host, port, useTLS)
    } catch (e: Exception) {
      null
    }
  }
}
