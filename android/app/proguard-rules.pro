-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
# Keep Stripe classes
-keep class com.stripe.** { *; }

# Keep ReLinker classes
-dontwarn com.getkeepsafe.relinker.ReLinker$Logger
-dontwarn com.getkeepsafe.relinker.ReLinker
-dontwarn com.getkeepsafe.relinker.ReLinkerInstance

# Keep Flutter plugin registrant and all Flutter embedding classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }

# Keep all plugin classes
-keep class dev.fluttercommunity.** { *; }
-keep class io.github.ponnamkarthik.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep app entry point
-keep class com.veraapp.app.** { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable