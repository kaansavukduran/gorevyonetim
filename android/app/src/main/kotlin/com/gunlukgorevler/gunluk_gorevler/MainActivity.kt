package com.gunlukgorevler.gunluk_gorevler

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var exportText: String? = null
    private var exportName: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.gunlukgorevler/files")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "dataDirectory" -> result.success(filesDir.absolutePath)
                    "exportBackup", "pickBackup" -> {
                        if (pending != null) {
                            result.error("BUSY", "Önce açık dosya penceresini kapat.", null)
                        } else {
                            pending = result
                            try {
                                if (call.method == "exportBackup") {
                                    exportText = call.argument<String>("text") ?: error("Yedek boş")
                                    exportName = call.argument<String>("name") ?: "gunluk-gorevler-yedek.json"
                                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                        addCategory(Intent.CATEGORY_OPENABLE)
                                        type = "application/json"
                                        putExtra(Intent.EXTRA_TITLE, exportName)
                                        suggestDownloads(this)
                                    }
                                    startActivityForResult(intent, EXPORT)
                                } else {
                                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                        addCategory(Intent.CATEGORY_OPENABLE)
                                        type = "*/*"
                                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain", "application/octet-stream"))
                                        suggestDownloads(this)
                                    }
                                    startActivityForResult(intent, IMPORT)
                                }
                            } catch (e: Exception) {
                                finishRequest { it.error("DOCUMENT", e.localizedMessage, null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("FlutterActivity uses the activity result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != EXPORT && requestCode != IMPORT) return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            finishRequest { it.success(null) }
            return
        }
        try {
            if (requestCode == EXPORT) {
                val text = exportText ?: error("Yedek bulunamadı")
                contentResolver.openOutputStream(uri, "wt").use { stream ->
                    requireNotNull(stream) { "Dosya yazılamadı" }
                    stream.write(text.toByteArray(Charsets.UTF_8))
                }
                finishRequest { it.success(exportName) }
            } else {
                val name = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                    if (it.moveToFirst()) it.getString(0) else null
                } ?: "Seçilen yedek.json"
                val bytes = contentResolver.openInputStream(uri).use { stream ->
                    requireNotNull(stream) { "Dosya okunamadı" }
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    var count = stream.read(buffer)
                    while (count != -1) {
                        require(output.size() + count <= 50 * 1024 * 1024) { "Yedek en fazla 50 MB olabilir" }
                        output.write(buffer, 0, count)
                        count = stream.read(buffer)
                    }
                    output.toByteArray()
                }
                // Report invalid UTF-8 rather than silently replacing characters.
                val text = Charsets.UTF_8.newDecoder().decode(java.nio.ByteBuffer.wrap(bytes)).toString()
                finishRequest { it.success(mapOf("name" to name, "text" to text)) }
            }
        } catch (e: Exception) {
            finishRequest { it.error("DOCUMENT", e.localizedMessage, null) }
        }
    }

    private fun finishRequest(send: (MethodChannel.Result) -> Unit) {
        val result = pending
        pending = null
        if (result != null) send(result)
        exportText = null
        exportName = null
    }

    // A starting location only: people can still choose any document provider.
    // SAF grants access to the selected document without storage permission.
    private fun suggestDownloads(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI,
                DocumentsContract.buildDocumentUri("com.android.externalstorage.documents", "primary:Download"))
        }
    }

    companion object {
        private const val EXPORT = 8201
        private const val IMPORT = 8202
    }
}
