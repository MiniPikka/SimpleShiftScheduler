# Compose
-keep class androidx.compose.** { *; }
-keepclassmembers class androidx.compose.** { *; }

# Enum classes used by Compose
-keepclassmembers enum com.simpleshift.scheduler.domain.model.ShiftType { *; }
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Data classes
-keep class com.simpleshift.scheduler.domain.model.** { *; }
-keep class com.simpleshift.scheduler.viewmodel.** { *; }

# ViewModel classes
-keep class * extends androidx.lifecycle.ViewModel { *; }
-keepclassmembers class * extends androidx.lifecycle.ViewModel { *; }
