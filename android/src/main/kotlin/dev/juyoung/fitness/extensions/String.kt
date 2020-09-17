package dev.juyoung.fitness.extensions

import java.util.concurrent.TimeUnit

val String.timeUnit: TimeUnit
    @Throws
    get() = when (this) {
        "days" -> TimeUnit.DAYS
        "hours" -> TimeUnit.HOURS
        "minutes" -> TimeUnit.MINUTES
        else -> throw NullPointerException()
    }
