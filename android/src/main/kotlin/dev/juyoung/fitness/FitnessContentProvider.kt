package dev.juyoung.fitness

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import dev.juyoung.fitness.extensions.isDebuggable
import timber.log.Timber

class FitnessContentProvider : ContentProvider() {
    override fun onCreate(): Boolean {
        val isDebuggable = context?.isDebuggable ?: false

        if (Timber.treeCount() < 1 && isDebuggable) {
            Timber.plant(Timber.DebugTree())
        }

        return true
    }

    override fun query(uri: Uri, projection: Array<String>?, selection: String?, selectionArgs: Array<String>?, sortOrder: String?): Cursor? {
        throw UnsupportedOperationException()
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? {
        throw UnsupportedOperationException()
    }

    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<String>?): Int {
        throw UnsupportedOperationException()
    }

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?): Int {
        throw UnsupportedOperationException()
    }

    override fun getType(uri: Uri): String? {
        throw UnsupportedOperationException()
    }
}