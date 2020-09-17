package dev.juyoung.fitness.extensions

import io.flutter.plugin.common.MethodCall

fun MethodCall.getString(key: String): String? {
    return argument(key)
}

fun MethodCall.getInt(key: String): Int? {
    return argument(key)
}

fun MethodCall.getLong(key: String): Long? {
    return when (val value: Any? = argument(key)) {
        is Int -> value.toLong()
        is Long -> value
        else -> null
    }
}
