package com.simpleshift.scheduler.calendar

import android.content.ContentResolver
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri

/**
 * Thin abstraction over ContentResolver for calendar operations, enabling testability.
 */
interface CalendarResolver {
    fun query(uri: Uri, projection: Array<String>?, selection: String?, selectionArgs: Array<String>?, sortOrder: String?): Cursor?
    fun insert(uri: Uri, values: ContentValues?): Uri?
    fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?): Int
}

internal class ContentCalendarResolver(private val contentResolver: ContentResolver) : CalendarResolver {
    override fun query(uri: Uri, projection: Array<String>?, selection: String?, selectionArgs: Array<String>?, sortOrder: String?) =
        contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)

    override fun insert(uri: Uri, values: ContentValues?) =
        contentResolver.insert(uri, values)

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?) =
        contentResolver.delete(uri, selection, selectionArgs)
}
