package com.example.app_control_informes

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STORAGE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "savePdfToDownloads" -> {
                    val fileName = call.argument<String>("fileName")
                    val subdirectory = call.argument<String>("subdirectory").orEmpty()
                    val bytes = call.argument<ByteArray>("bytes")

                    if (fileName.isNullOrBlank() || bytes == null || bytes.isEmpty()) {
                        result.error(
                            "invalid_args",
                            "fileName and bytes are required to save the PDF.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        val savedPath = savePdfToDownloads(
                            fileName = fileName,
                            subdirectory = subdirectory,
                            bytes = bytes,
                        )
                        result.success(savedPath)
                    } catch (error: Exception) {
                        result.error(
                            "save_failed",
                            error.message,
                            null,
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun savePdfToDownloads(
        fileName: String,
        subdirectory: String,
        bytes: ByteArray,
    ): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw IOException(
                "Guardar PDFs en Descargas requiere Android 10 o superior.",
            )
        }

        return savePdfWithMediaStore(fileName, subdirectory, bytes)
    }

    private fun savePdfWithMediaStore(
        fileName: String,
        subdirectory: String,
        bytes: ByteArray,
    ): String {
        val resolver = applicationContext.contentResolver
        val relativePath = buildRelativeDownloadsPath(subdirectory)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, PDF_MIME_TYPE)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        val itemUri = resolver.insert(collection, values)
            ?: throw IOException("No se pudo crear el archivo PDF en Descargas.")

        try {
            resolver.openOutputStream(itemUri)?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: throw IOException("No se pudo abrir el archivo PDF para escritura.")

            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(itemUri, values, null, null)

            return buildAbsoluteDownloadsPath(fileName, subdirectory)
        } catch (error: Exception) {
            resolver.delete(itemUri, null, null)
            throw error
        }
    }

    private fun buildRelativeDownloadsPath(subdirectory: String): String {
        return if (subdirectory.isBlank()) {
            Environment.DIRECTORY_DOWNLOADS
        } else {
            "${Environment.DIRECTORY_DOWNLOADS}/$subdirectory"
        }
    }

    private fun buildAbsoluteDownloadsPath(
        fileName: String,
        subdirectory: String,
    ): String {
        val downloadsRoot = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        val directory = if (subdirectory.isBlank()) {
            downloadsRoot
        } else {
            File(downloadsRoot, subdirectory)
        }
        return File(directory, fileName).absolutePath
    }

    private companion object {
        const val STORAGE_CHANNEL = "app_control_informes/storage"
        const val PDF_MIME_TYPE = "application/pdf"
    }
}
