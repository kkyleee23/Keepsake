# Rules for the release build, used by R8 when it shrinks the app.
#
# The Flutter Gradle plugin points at this file, so it has to exist or
# `flutter build apk --release` stops with "Supplied proguard configuration
# does not exist". Keep what goes in here conservative: a missing rule shows
# up as a crash in the released app and nowhere else, so it is better to keep
# a little too much than to strip something that is only reached by name.

# Flutter itself and the plugins it generates, which are found by reflection.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Deferred components are not used here, so Play Core is not in the app.
# Without this, R8 stops on references it cannot resolve.
-dontwarn com.google.android.play.core.**

# Names and annotations that anything reading or writing JSON needs to keep.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Line numbers make a crash report readable; the file name is not needed.
-keepattributes SourceFile, LineNumberTable
-renamesourcefileattribute SourceFile
