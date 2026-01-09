# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Supabase / Postgrest
-keep class io.supabase.** { *; }
-keep class io.github.jan.supabase.** { *; }

# PowerSync
-keep class com.powersync.** { *; }

# SQLite / Drift
-keep class androidx.sqlite.** { *; }
-keep class org.sqlite.** { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations

# Keep generic signatures for Gson/JSON
-keepattributes Signature
-keepattributes Exceptions

# Google Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
