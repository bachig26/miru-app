package miru.miaomint

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.database.Cursor
import android.content.ContentUris
import android.net.Uri
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.provider.MediaStore
import android.util.Log

object UriUtils {

    fun getPathFromUri(context: Context, uri: Uri?): String? {
        if (uri == null) {
            return null
        }

        if (DocumentsContract.isDocumentUri(context, uri)) {
            when (uri.authority) {
                "com.android.providers.media.documents" -> {
                    val docId = DocumentsContract.getDocumentId(uri)
                    val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                    val type = split[0]

                    val contentUri: Uri? = when (type) {
                        "image" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                        "video" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                        "audio" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                        else -> null
                    }

                    contentUri?.let {
                        val selection = "_id=?"
                        val selectionArgs = arrayOf(split[1])
                        return getDataColumn(context, it, selection, selectionArgs)
                    }
                }
                "com.android.providers.downloads.documents" -> {
                    val id = DocumentsContract.getDocumentId(uri)
                    if (id.startsWith("raw:")) {
                        return id.replaceFirst("raw:", "")
                    }
                    try {
                        val contentUri = ContentUris.withAppendedId(
                            Uri.parse("content://downloads/public_downloads"),
                            java.lang.Long.valueOf(id)
                        )
                        return getDataColumn(context, contentUri, null, null)
                    } catch (e: NumberFormatException) {
                        Log.e("UriUtils", "NumberFormatException: $e")
                        return null
                    }
                }
                "com.android.externalstorage.documents" -> {
                    val docId = DocumentsContract.getDocumentId(uri)
                    val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                    val type = split[0]
                    if ("primary".equals(type, ignoreCase = true)) {
                        return Environment.getExternalStorageDirectory().toString() + "/" + split[1]
                    }
                }
            }
        } else if ("content".equals(uri.scheme, ignoreCase = true)) {
            // MediaStore (and general)
            return getDataColumn(context, uri, null, null)
        } else if ("file".equals(uri.scheme, ignoreCase = true)) {
            return uri.path
        }
        return null
    }

    private fun getDataColumn(
        context: Context,
        uri: Uri,
        selection: String?,
        selectionArgs: Array<String>?
    ): String? {
        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(column)
        try {
            cursor = context.contentResolver.query(uri, projection, selection, selectionArgs, null)
            if (cursor != null && cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(columnIndex)
            }
        } catch (e: Exception) {
            Log.e("UriUtils", "getDataColumn Exception: $e")
        } finally {
            cursor?.close()
        }
        return null
    }
}

class MainActivity: FlutterActivity() {
    private val CHANNEL = "UTILS" // 保持与 Flutter 代码中的通道名称一致

    fun checkUriPersisted(uri: Uri): Boolean {
        return contentResolver.persistedUriPermissions.any { persisted ->
            uri.path?.startsWith(persisted.uri.path ?: "") ?: false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "getPathFromUri" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        val uri = Uri.parse(uriString)
                        val displayName = UriUtils.getPathFromUri(applicationContext, uri)
                        result.success(displayName)
                    } else {
                        result.error("URI_ERROR", "URI is null", null)
                    }
                }
                "checkUriPersisted" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        var uri = Uri.parse(uriString)
                        result.success(checkUriPersisted(uri))
                    } else {
                        result.error("URI_ERROR", "URI is null", null)
                    }
                }
                else -> result.notImplemented()
            }
            
        }
    }
}
