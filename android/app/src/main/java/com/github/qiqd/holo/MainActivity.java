package com.github.qiqd.holo;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.os.Build;
public class MainActivity extends FlutterActivity {
      // 通道名称，保持和 Dart 侧一致
    private static final String CHANNEL = "abi_detector";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // 创建 MethodChannel 并设置方法调用处理器
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if ("getDeviceAbi".equals(call.method)) {
                        String abi = getDeviceAbi();
                        result.success(abi);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    // 获取设备主要 ABI
    private String getDeviceAbi() {
        return Build.SUPPORTED_ABIS[0];
    }
}
