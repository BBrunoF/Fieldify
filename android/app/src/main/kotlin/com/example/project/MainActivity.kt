package com.example.project

// flutter_stripe's PaymentSheet renders in an Android fragment, so the host
// activity must be a FragmentActivity. Using plain FlutterActivity crashes
// when presentPaymentSheet() is called.
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
