# LingoSync ProGuard & R8 Keep Rules for Android Audio and Native JNI libs (C22)

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Audio Session & Recording Native Classes
-keep class com.ryanheise.** { *; }
-keep class com.llfbandit.record.** { *; }
-keep class tflite.** { *; }

# Keep Flutter TTS
-keep class com.tundralabs.fluttertts.** { *; }

# Keep Supabase & Networking Models
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes InnerClasses

# Preserve JNI method names
-keepclasseswithmembernames class * {
    native <methods>;
}
