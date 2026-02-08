package ai.openclaw.android.qr

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
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
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.Executors

@Composable
fun QRScannerScreen(
  viewModel: QRScannerViewModel = viewModel(),
  onDismiss: () -> Unit,
) {
  val context = LocalContext.current
  val lifecycleOwner = LocalLifecycleOwner.current
  val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
  val executor = remember { Executors.newSingleThreadExecutor() }

  val scanError by viewModel.scanError.collectAsState()
  val isConnecting by viewModel.isConnecting.collectAsState()
  val hasPermission by viewModel.hasCameraPermission.collectAsState()

  val permissionLauncher = rememberLauncherForActivityResult(
    contract = ActivityResultContracts.RequestPermission(),
  ) { granted ->
    viewModel.setCameraPermission(granted)
  }

  LaunchedEffect(Unit) {
    val permission = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
    if (permission == PackageManager.PERMISSION_GRANTED) {
      viewModel.setCameraPermission(true)
    } else {
      permissionLauncher.launch(Manifest.permission.CAMERA)
    }
  }

  DisposableEffect(Unit) {
    onDispose {
      executor.shutdown()
    }
  }

  Box(modifier = Modifier.fillMaxSize()) {
    if (hasPermission) {
      AndroidView(
        factory = { ctx ->
          val previewView = PreviewView(ctx)
          val cameraProvider = cameraProviderFuture.get()

          val preview = Preview.Builder().build().also {
            it.setSurfaceProvider(previewView.surfaceProvider)
          }

          val imageAnalyzer = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
            .also {
              it.setAnalyzer(executor) { imageProxy ->
                val mediaImage = imageProxy.image
                if (mediaImage != null && !viewModel.isScanning.value) {
                  viewModel.setScanning(true)
                  val image = InputImage.fromMediaImage(
                    mediaImage,
                    imageProxy.imageInfo.rotationDegrees,
                  )
                  val scanner = BarcodeScanning.getClient()
                  scanner.process(image)
                    .addOnSuccessListener { barcodes ->
                      for (barcode in barcodes) {
                        if (barcode.format == Barcode.FORMAT_QR_CODE) {
                          barcode.rawValue?.let { code ->
                            viewModel.handleScannedCode(code)
                          }
                        }
                      }
                    }
                    .addOnCompleteListener {
                      imageProxy.close()
                      viewModel.setScanning(false)
                    }
                }
              }
            }

          val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

          try {
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(
              lifecycleOwner,
              cameraSelector,
              preview,
              imageAnalyzer,
            )
          } catch (exc: Exception) {
            viewModel.setScanError("Camera initialization failed: ${exc.message}")
          }

          previewView
        },
        modifier = Modifier.fillMaxSize(),
      )
    } else {
      Box(
        modifier = Modifier.fillMaxSize().background(Color.Black),
        contentAlignment = Alignment.Center,
      ) {
        Text(
          text = "Camera permission required",
          color = Color.White,
          style = MaterialTheme.typography.bodyLarge,
        )
      }
    }

    Column(
      modifier = Modifier.fillMaxSize(),
      verticalArrangement = Arrangement.SpaceBetween,
    ) {
      Box(
        modifier = Modifier.fillMaxWidth().padding(16.dp),
        contentAlignment = Alignment.TopStart,
      ) {
        IconButton(
          onClick = onDismiss,
          modifier = Modifier.background(Color.Black.copy(alpha = 0.5f), RoundedCornerShape(50)),
        ) {
          Icon(
            imageVector = Icons.Default.Close,
            contentDescription = "Close",
            tint = Color.White,
            modifier = Modifier.size(32.dp),
          )
        }
      }

      Spacer(modifier = Modifier.weight(1f))

      Column(
        modifier = Modifier.fillMaxWidth().padding(bottom = 100.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
      ) {
        Text(
          text = "Scan Gateway QR Code",
          style = MaterialTheme.typography.headlineSmall,
          color = Color.White,
          modifier = Modifier.padding(horizontal = 16.dp),
          textAlign = TextAlign.Center,
        )

        if (scanError != null) {
          Text(
            text = scanError!!,
            style = MaterialTheme.typography.bodySmall,
            color = Color.Red,
            modifier = Modifier
              .padding(horizontal = 16.dp, vertical = 8.dp)
              .background(Color.Black.copy(alpha = 0.6f), RoundedCornerShape(8.dp))
              .padding(16.dp),
            textAlign = TextAlign.Center,
          )
        }

        if (isConnecting) {
          Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier
              .background(Color.Black.copy(alpha = 0.6f), RoundedCornerShape(8.dp))
              .padding(16.dp),
          ) {
            CircularProgressIndicator(
              color = Color.White,
              modifier = Modifier.size(24.dp),
            )
            Text(
              text = "Connecting...",
              color = Color.White,
              style = MaterialTheme.typography.bodyMedium,
            )
          }
        }
      }
    }
  }

  LaunchedEffect(viewModel.shouldDismiss.collectAsState().value) {
    if (viewModel.shouldDismiss.value) {
      onDismiss()
    }
  }
}
