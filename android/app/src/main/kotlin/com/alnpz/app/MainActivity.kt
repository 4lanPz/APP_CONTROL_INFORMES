package com.alnpz.app

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
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
                "saveBytesToDownloads" -> {
                    val fileName = call.argument<String>("fileName")
                    val subdirectory = call.argument<String>("subdirectory").orEmpty()
                    val mimeType = call.argument<String>("mimeType").orEmpty()
                    val bytes = call.argument<ByteArray>("bytes")

                    if (fileName.isNullOrBlank() || mimeType.isBlank() || bytes == null || bytes.isEmpty()) {
                        result.error(
                            "invalid_args",
                            "fileName, mimeType and bytes are required.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        val savedPath = saveBytesToDownloads(
                            fileName = fileName,
                            subdirectory = subdirectory,
                            mimeType = mimeType,
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
                "openPdfExternally" -> {
                    val path = call.argument<String>("path")

                    if (path.isNullOrBlank()) {
                        result.error(
                            "invalid_args",
                            "path is required.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        openPdfExternally(path)
                        result.success(null)
                    } catch (error: ActivityNotFoundException) {
                        result.error(
                            "no_viewer_app",
                            "No se encontró una aplicación para ver el PDF.",
                            null,
                        )
                    } catch (error: Exception) {
                        result.error(
                            "open_failed",
                            error.message,
                            null,
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // Abre el PDF ya generado con el selector nativo de Android ("Abrir con"),
    // para que el técnico elija en qué app verlo y desde ahí decida si lo
    // guarda o lo comparte. Usa FileProvider (en vez de un file:// directo)
    // porque desde Android 7 (API 24) compartir un Uri file:// entre apps
    // lanza FileUriExposedException; content:// funciona igual en todas las
    // versiones soportadas por esta app (minSdk 21+).
    private fun openPdfExternally(path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw IOException("El archivo PDF ya no existe.")
        }

        val authority = "$packageName.fileprovider"
        val uri = FileProvider.getUriForFile(this, authority, file)

        val viewIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/pdf")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        val chooser = Intent.createChooser(viewIntent, "Abrir informe PDF con")
        startActivity(chooser)
    }

    private fun saveBytesToDownloads(
        fileName: String,
        subdirectory: String,
        mimeType: String,
        bytes: ByteArray,
    ): String {
        // Nunca confiamos en texto que llega desde el lado Dart para armar
        // rutas de archivo: se sanea aquí también (no solo del lado Dart),
        // siguiendo la recomendación de Android de no construir rutas de
        // MediaStore/ContentValues con datos externos sin validar.
        val safeFileName = sanitizeFileName(fileName)
        val safeSubdirectory = sanitizeSubdirectory(subdirectory)

        // Android 10+ (API 29): almacenamiento con ámbito (scoped storage).
        // Se usa MediaStore para que el archivo quede en la carpeta pública
        // "Descargas", visible desde el explorador de archivos o WhatsApp.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return saveWithMediaStore(safeFileName, safeSubdirectory, mimeType, bytes)
        }

        // Android 5-9 (API < 29): MediaStore.Downloads no existe todavía, y
        // escribir en la carpeta pública de Descargas requeriría pedir el
        // permiso peligroso WRITE_EXTERNAL_STORAGE en tiempo de ejecución.
        // En vez de eso se guarda en el almacenamiento externo propio de la
        // app (getExternalFilesDir), que no requiere ningún permiso en
        // ninguna versión de Android y sigue siendo accesible para el
        // técnico desde un explorador de archivos, dentro de
        // Android/data/com.alnpz.app/files/Download.
        return saveWithLegacyExternalStorage(safeFileName, safeSubdirectory, bytes)
    }

    private fun saveWithLegacyExternalStorage(
        fileName: String,
        subdirectory: String,
        bytes: ByteArray,
    ): String {
        val downloadsRoot = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: throw IOException("No se pudo acceder al almacenamiento externo del dispositivo.")

        val targetDirectory = if (subdirectory.isBlank()) {
            downloadsRoot
        } else {
            File(downloadsRoot, subdirectory)
        }

        if (!targetDirectory.exists() && !targetDirectory.mkdirs()) {
            throw IOException("No se pudo crear la carpeta de destino.")
        }

        val targetFile = File(targetDirectory, fileName)
        targetFile.writeBytes(bytes)
        return targetFile.absolutePath
    }

    private fun sanitizeFileName(rawFileName: String): String {
        val nameOnly = File(rawFileName).name
        val sanitized = nameOnly.replace(Regex("[/\\\\:*?\"<>|]"), "_").trim()
        return sanitized.ifBlank { "archivo" }
    }

    private fun sanitizeSubdirectory(rawSubdirectory: String): String {
        val segments = rawSubdirectory
            .split('/', '\\')
            .map { it.trim() }
            .filter { it.isNotEmpty() && it != "." && it != ".." }
            .map { it.replace(Regex("[:*?\"<>|]"), "_") }
        return segments.joinToString("/")
    }

    private fun saveWithMediaStore(
        fileName: String,
        subdirectory: String,
        mimeType: String,
        bytes: ByteArray,
    ): String {
        val resolver = applicationContext.contentResolver
        val relativePath = buildRelativeDownloadsPath(subdirectory)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        val itemUri = resolver.insert(collection, values)
            ?: throw IOException("No se pudo crear el archivo en Descargas.")

        try {
            resolver.openOutputStream(itemUri)?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: throw IOException("No se pudo abrir el archivo para escritura.")

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
    }
}
