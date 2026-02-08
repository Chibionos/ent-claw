package ai.openclaw.android.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.fragment.app.FragmentActivity
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch

@Composable
fun BiometricLockScreen(
  authManager: BiometricAuthManager,
  onAuthenticated: () -> Unit,
) {
  val context = LocalContext.current
  val activity = context as? FragmentActivity
  val authError by authManager.authError.collectAsState()
  val coroutineScope = rememberCoroutineScope()
  val biometricIcon = when (authManager.biometricType) {
    BiometricAuthManager.BiometricType.Available -> Icons.Default.Fingerprint
    else -> Icons.Default.Lock
  }

  LaunchedEffect(Unit) {
    if (activity != null) {
      val success = authManager.authenticate(activity)
      if (success) {
        onAuthenticated()
      }
    }
  }

  Box(
    modifier = Modifier
      .fillMaxSize()
      .background(Color.Black),
    contentAlignment = Alignment.Center,
  ) {
    Column(
      modifier = Modifier.fillMaxWidth().padding(horizontal = 40.dp),
      horizontalAlignment = Alignment.CenterHorizontally,
      verticalArrangement = Arrangement.spacedBy(32.dp),
    ) {
      Spacer(modifier = Modifier.weight(1f))

      Icon(
        imageVector = biometricIcon,
        contentDescription = "Biometric Icon",
        modifier = Modifier.size(80.dp),
        tint = Color.White,
      )

      Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
      ) {
        Text(
          text = "OpenClaw",
          style = MaterialTheme.typography.headlineMedium,
          color = Color.White,
        )

        Text(
          text = "Tap to unlock with ${authManager.biometricDisplayName}",
          style = MaterialTheme.typography.bodyMedium,
          color = Color.White.copy(alpha = 0.7f),
          textAlign = TextAlign.Center,
        )
      }

      if (authError != null) {
        Text(
          text = authError!!,
          style = MaterialTheme.typography.bodySmall,
          color = Color.Red,
          textAlign = TextAlign.Center,
          modifier = Modifier.padding(horizontal = 16.dp),
        )
      }

      Spacer(modifier = Modifier.weight(1f))

      Button(
        onClick = {
          if (activity != null) {
            coroutineScope.launch {
              val success = authManager.authenticate(activity)
              if (success) {
                onAuthenticated()
              }
            }
          }
        },
        modifier = Modifier.fillMaxWidth().padding(bottom = 60.dp),
        shape = RoundedCornerShape(12.dp),
        colors = ButtonDefaults.buttonColors(
          containerColor = Color.White,
          contentColor = Color.Black,
        ),
      ) {
        Icon(
          imageVector = biometricIcon,
          contentDescription = null,
          modifier = Modifier.size(20.dp),
        )
        Text(
          text = "Unlock",
          modifier = Modifier.padding(start = 8.dp),
          style = MaterialTheme.typography.titleMedium,
        )
      }
    }
  }
}
