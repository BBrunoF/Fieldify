# Stripe push provisioning (Google Wallet card-add) classes are referenced
# by the Stripe Android SDK but only exist if you depend on
# stripe-android-pushProvisioning. The app does not use that flow, so tell
# R8 the references are intentionally unresolved.
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }
