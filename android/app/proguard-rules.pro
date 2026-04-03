# TouchifyMouse ProGuard Rules
# Keep all Flutter + Riverpod + Dart:io socket classes from R8 stripping

# Flutter framework
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Riverpod — keep generated providers and state notifiers
-keep class dev.rift.** { *; }
-keep @interface dev.rift.**

# Dart-to-Java bridge (required for plugin channels)
-keep class ** implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class ** implements io.flutter.plugin.common.EventChannel$StreamHandler { *; }

# Keep all classes with annotations (Riverpod uses reflection-like patterns)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Socket / networking classes used by trackpad service
-keep class java.net.** { *; }
-keep class java.io.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# mobile_scanner / camera
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**

# record (audio)
-keep class com.llfbandit.record.** { *; }

# wakelock_plus
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# Don't obfuscate method names (crashes Dart exception -> Java bridge)
-keepnames class ** { *; }
