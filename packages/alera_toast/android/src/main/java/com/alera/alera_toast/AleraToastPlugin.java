package com.alera.alera_toast;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/** Shows Android system toast feedback from both foreground and background engines. */
public final class AleraToastPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
  private Context applicationContext;
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    applicationContext = binding.getApplicationContext();
    channel = new MethodChannel(binding.getBinaryMessenger(), "com.alera/toast");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(MethodCall call, MethodChannel.Result result) {
    if (!"show".equals(call.method)) {
      result.notImplemented();
      return;
    }

    final String message = call.argument("message");
    if (message == null || message.isEmpty()) {
      result.error("invalid_message", "A toast message is required.", null);
      return;
    }

    new Handler(Looper.getMainLooper()).post(
        () -> Toast.makeText(applicationContext, message, Toast.LENGTH_SHORT).show());
    result.success(null);
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;
    applicationContext = null;
  }
}
