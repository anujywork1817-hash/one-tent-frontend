package com.kumbh.one_tent

import android.os.Bundle
import androidx.activity.OnBackPressedCallback
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not the plain FlutterActivity) is required by
// razorpay_flutter's Android SDK.
//
// That comes at a cost: relying on FlutterFragmentActivity's own back-press
// wiring turned out to be a dead end on this device/Android version, in two
// separate ways confirmed live on-device:
//  1. When Flutter's PopScope intercepts a back press with canPop:false at
//     the app's ROOT-most route (nothing left to pop), the event never
//     reached Flutter's navigation channel at all — Android just fell
//     through to its default behaviour and finished the Activity.
//  2. Forwarding the press manually via the "flutter/navigation" -> popRoute
//     platform message (the obvious fix for #1) worked for a single press,
//     but with predictive back disabled (needed to make gesture-nav route
//     through this dispatcher instead of animating past it) a single
//     edge-swipe gesture produced tens of thousands of repeated
//     handleOnBackPressed() calls in a tight loop instead of one.
//
// The fix that actually holds up: forward through our OWN dedicated
// MethodChannel ("app/back") instead of Flutter's internal navigation
// channel, with an explicit debounce here so a single press/swipe can only
// ever produce one Dart-side call no matter how many times the dispatcher
// re-invokes handleOnBackPressed() for it. Dart owns all the actual
// "go to Home" / "press again to exit" logic — see
// lib/core/navigation/back_navigation.dart.
//
// Separately: SystemNavigator.pop() (Flutter's standard "exit the app" call)
// only moves this Activity to the back on a single-activity task root like
// this one — it doesn't finish/kill it. That reads as "Exit does nothing"
// to a user who expects the app to actually close. "app/exit" -> "exit"
// below does that for real: finishAndRemoveTask() plus killProcess so the
// process is actually gone, not just backgrounded.
class MainActivity : FlutterFragmentActivity() {
    private var lastBackPressAt = 0L
    private val debounceMs = 400L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app/exit")
            .setMethodCallHandler { call, result ->
                if (call.method == "exit") {
                    result.success(null)
                    finishAndRemoveTask()
                    android.os.Process.killProcess(android.os.Process.myPid())
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        onBackPressedDispatcher.addCallback(
            this,
            object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    val now = System.currentTimeMillis()
                    if (now - lastBackPressAt < debounceMs) return
                    lastBackPressAt = now

                    val engine = flutterEngine ?: return
                    MethodChannel(engine.dartExecutor.binaryMessenger, "app/back")
                        .invokeMethod("pressed", null)
                }
            }
        )
    }
}
