# MBox ProGuard Rules

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Cling (DLNA)
-dontwarn org.fourthline.cling.**
-keep class org.fourthline.cling.** { *; }
-dontwarn org.fourthline.baye.**
-keep class org.fourthline.baye.** { *; }
-dontwarn org.seamless.**
-keep class org.seamless.** { *; }

# NanoHTTPD
-dontwarn fi.iki.elonen.**
-keep class fi.iki.elonen.** { *; }

# QuickJS
-dontwarn app.cash.quickjs.**
-keep class app.cash.quickjs.** { *; }

# Glide
-dontwarn com.bumptech.glide.**
-keep class com.bumptech.glide.** { *; }
-keep interface com.bumptech.glide.** { *; }

# Media3 (ExoPlayer)
-dontwarn androidx.media3.**
-keep class androidx.media3.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom view constructors
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep enum methods
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep JSON models
-keep class com.mbox.android.models.** { *; }
-keep class com.mbox.android.**$Creator { *; }
