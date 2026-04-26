package com.mbox.android;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry;

public class MainActivity extends FlutterActivity 
        implements PluginRegistry.RequestPermissionsResultListener,
                   LocalHttpServer.ApiHandler {
    private static final String TAG = "MainActivity";
    
    // Method Channel
    private static final String NATIVE_CHANNEL = "com.mbox.android/native";
    private static final String SPIDER_CHANNEL = "com.mbox.android/spider";
    private static final String DLNA_CHANNEL = "com.mbox.android/dlna";
    private static final int PERMISSION_REQUEST_CODE = 1000;
    
    // 组件
    private JarSpiderLoader spiderLoader;
    private LocalHttpServer httpServer;
    private DlnaController dlnaController;
    private DrmManager currentDrm;
    private JsSpiderLoader jsSpiderLoader;
    
    private MethodChannel nativeChannel;
    private MethodChannel spiderChannel;
    private MethodChannel dlnaChannel;
    
    // 需要请求的权限
    private final String[] permissions = {
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE,
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_NETWORK_STATE,
        Manifest.permission.CHANGE_WIFI_MULTICAST_STATE,
        Manifest.permission.INTERNET,
    };

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        // 初始化组件
        spiderLoader = new JarSpiderLoader(this);
        dlnaController = new DlnaController(this);
        
        // 注册 Method Channels
        nativeChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), NATIVE_CHANNEL);
        spiderChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SPIDER_CHANNEL);
        dlnaChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), DLNA_CHANNEL);
        
        // Native 方法调用
        nativeChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "checkPermissions":
                    checkPermissions(result);
                    break;
                    
                case "requestPermissions":
                    requestPermissions();
                    result.success(true);
                    break;
                    
                case "getDeviceInfo":
                    getDeviceInfo(result);
                    break;
                    
                case "getIpAddress":
                    getIpAddress(result);
                    break;
                    
                case "startHttpServer":
                    int port = call.argument("port");
                    startHttpServer(port, result);
                    break;
                    
                case "stopHttpServer":
                    stopHttpServer(result);
                    break;
                    
                case "startDlna":
                    startDlna(result);
                    break;
                    
                case "stopDlna":
                    stopDlna(result);
                    break;
                    
                case "searchDlnaDevices":
                    searchDlnaDevices(result);
                    break;
                    
                case "castVideo":
                    String deviceId = call.argument("deviceId");
                    String videoUrl = call.argument("videoUrl");
                    String title = call.argument("title");
                    String poster = call.argument("poster");
                    castVideo(deviceId, videoUrl, title, poster, result);
                    break;
                    
                case "loadDrm":
                    String drmType = call.argument("drmType");
                    String licenseUrl = call.argument("licenseUrl");
                    Map<String, String> headers = (Map<String, String>) call.argument("headers");
                    loadDrm(drmType, licenseUrl, headers, result);
                    break;
                    
                case "unloadDrm":
                    unloadDrm(result);
                    break;
                    
                default:
                    result.notImplemented();
            }
        });
        
        // Spider 方法调用
        spiderChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "loadJar":
                    String key = call.argument("key");
                    String jarPath = call.argument("jarPath");
                    loadJar(key, jarPath, result);
                    break;
                    
                case "callSpider":
                    String spiderKey = call.argument("key");
                    String method = call.argument("method");
                    String arg = call.argument("arg");
                    callSpider(spiderKey, method, arg, result);
                    break;
                    
                case "unloadJar":
                    String unloadKey = call.argument("key");
                    unloadJar(unloadKey, result);
                    break;
                    
                default:
                    result.notImplemented();
            }
        });
        
        // DLNA 事件监听
        dlnaChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "control":
                    String deviceId = call.argument("deviceId");
                    String action = call.argument("action");
                    controlDlna(deviceId, action, result);
                    break;
                    
                default:
                    result.notImplemented();
            }
        });
        
        // 注册权限回调
        flutterEngine.addRequestPermissionsResultListener(this);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 请求必要权限
        requestPermissionsIfNeeded();
        
        Log.d(TAG, "MBox MainActivity created");
    }

    @Override
    protected void onDestroy() {
        // 清理资源
        if (httpServer != null) {
            httpServer.stop();
        }
        if (dlnaController != null) {
            dlnaController.stop();
        }
        if (spiderLoader != null) {
            spiderLoader.destroyAll();
        }
        if (currentDrm != null) {
            currentDrm.release();
        }
        
        super.onDestroy();
        Log.d(TAG, "MBox MainActivity destroyed");
    }

    // ===================== Native API =====================
    
    private void checkPermissions(MethodChannel.Result result) {
        boolean allGranted = true;
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) 
                    != PackageManager.PERMISSION_GRANTED) {
                allGranted = false;
                break;
            }
        }
        result.success(allGranted);
    }

    private void requestPermissionsIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            java.util.List<String> permissionsToRequest = new java.util.ArrayList<>();
            for (String permission : permissions) {
                if (ContextCompat.checkSelfPermission(this, permission) 
                        != PackageManager.PERMISSION_GRANTED) {
                    permissionsToRequest.add(permission);
                }
            }
            
            if (!permissionsToRequest.isEmpty()) {
                ActivityCompat.requestPermissions(
                    this,
                    permissionsToRequest.toArray(new String[0]),
                    PERMISSION_REQUEST_CODE
                );
            }
        }
    }

    private void requestPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            ActivityCompat.requestPermissions(
                this,
                permissions,
                PERMISSION_REQUEST_CODE
            );
        }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            
            if (!allGranted) {
                // 有权限被拒绝
                nativeChannel.invokeMethod("permissionsDenied", null);
            } else {
                nativeChannel.invokeMethod("permissionsGranted", null);
            }
        }
        return true;
    }

    private void getDeviceInfo(MethodChannel.Result result) {
        Log.d(TAG, "Getting device info");
        
        Map<String, Object> deviceInfo = new HashMap<>();
        deviceInfo.put("brand", Build.BRAND);
        deviceInfo.put("model", Build.MODEL);
        deviceInfo.put("sdkInt", Build.VERSION.SDK_INT);
        deviceInfo.put("release", Build.VERSION.RELEASE);
        deviceInfo.put("manufacturer", Build.MANUFACTURER);
        deviceInfo.put("device", Build.DEVICE);
        deviceInfo.put("product", Build.PRODUCT);
        
        result.success(deviceInfo);
    }
    
    private void getIpAddress(MethodChannel.Result result) {
        String ip = DlnaController.getDeviceIpAddress();
        result.success(ip);
    }
    
    // ===================== HTTP Server =====================
    
    private void startHttpServer(int port, MethodChannel.Result result) {
        try {
            if (httpServer != null) {
                httpServer.stop();
            }
            
            httpServer = new LocalHttpServer(this, port, this);
            httpServer.start();
            
            Log.d(TAG, "HTTP server started on port " + port);
            result.success(true);
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to start HTTP server", e);
            result.error("SERVER_ERROR", e.getMessage(), null);
        }
    }
    
    private void stopHttpServer(MethodChannel.Result result) {
        if (httpServer != null) {
            httpServer.stop();
            httpServer = null;
            Log.d(TAG, "HTTP server stopped");
        }
        result.success(true);
    }
    
    // ===================== DLNA =====================
    
    private void startDlna(MethodChannel.Result result) {
        dlnaController.start();
        result.success(true);
    }
    
    private void stopDlna(MethodChannel.Result result) {
        dlnaController.stop();
        result.success(true);
    }
    
    private void searchDlnaDevices(MethodChannel.Result result) {
        dlnaController.searchDevices(new DlnaController.DlnaDeviceCallback() {
            @Override
            public void onDeviceFound(DlnaController.DlnaDevice device) {
                Map<String, String> deviceMap = new HashMap<>();
                deviceMap.put("name", device.name);
                deviceMap.put("uuid", device.uuid);
                deviceMap.put("baseUrl", device.baseUrl);
                
                dlnaChannel.invokeMethod("deviceFound", deviceMap);
                result.success(true);
            }
            
            @Override
            public void onError(String error) {
                Log.e(TAG, "DLNA search error: " + error);
                result.error("DLNA_ERROR", error, null);
            }
        });
    }
    
    private void castVideo(String deviceId, String videoUrl, String title, String poster, MethodChannel.Result result) {
        dlnaController.castVideo(deviceId, videoUrl, title, poster, new DlnaController.CastCallback() {
            @Override
            public void onSuccess() {
                Log.d(TAG, "Cast started");
                result.success(true);
            }
            
            @Override
            public void onError(String error) {
                Log.e(TAG, "Cast error: " + error);
                result.error("CAST_ERROR", error, null);
            }
        });
    }
    
    private void controlDlna(String deviceId, String action, MethodChannel.Result result) {
        dlnaController.control(deviceId, action, new DlnaController.ControlCallback() {
            @Override
            public void onSuccess() {
                result.success(true);
            }
            
            @Override
            public void onError(String error) {
                result.error("CONTROL_ERROR", error, null);
            }
        });
    }
    
    // ===================== DRM =====================
    
    private void loadDrm(String drmType, String licenseUrl, Map<String, String> headers, MethodChannel.Result result) {
        if (currentDrm != null) {
            currentDrm.release();
        }
        
        currentDrm = new DrmManager(drmType, licenseUrl, headers);
        currentDrm.prepare(new DrmManager.PrepareCallback() {
            @Override
            public void onSuccess() {
                Log.d(TAG, "DRM prepared: " + drmType);
                nativeChannel.invokeMethod("drmPrepared", null);
            }
            
            @Override
            public void onError(String error) {
                Log.e(TAG, "DRM prepare error: " + error);
                nativeChannel.invokeMethod("drmError", error);
            }
        });
        
        result.success(true);
    }
    
    private void unloadDrm(MethodChannel.Result result) {
        if (currentDrm != null) {
            currentDrm.release();
            currentDrm = null;
        }
        result.success(true);
    }
    
    // ===================== Spider =====================
    
    private void loadJar(String key, String jarPath, MethodChannel.Result result) {
        try {
            String libPath = getApplicationContext().getDir("libs", Context.MODE_PRIVATE).getAbsolutePath();
            ClassLoader parent = getClass().getClassLoader();
            
            spiderLoader.loadJar(key, jarPath, libPath, parent);
            result.success(true);
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to load JAR", e);
            result.error("JAR_ERROR", e.getMessage(), null);
        }
    }
    
    private void callSpider(String key, String method, String arg, MethodChannel.Result result) {
        spiderLoader.callSpider(key, method, new Object[]{arg}, new JarSpiderLoader.SpiderCallback() {
            @Override
            public void onSuccess(Object response) {
                result.success(response != null ? response.toString() : null);
            }
            
            @Override
            public void onError(String error) {
                result.error("SPIDER_ERROR", error, null);
            }
        });
    }
    
    private void unloadJar(String key, MethodChannel.Result result) {
        spiderLoader.unloadJar(key);
        result.success(true);
    }
    
    // ===================== LocalHttpServer.ApiHandler =====================
    
    @Override
    public void onPlay(float position) {
        nativeChannel.invokeMethod("onPlay", position);
    }

    @Override
    public void onPause() {
        nativeChannel.invokeMethod("onPause", null);
    }

    @Override
    public void onResume() {
        nativeChannel.invokeMethod("onResume", null);
    }

    @Override
    public void onStop() {
        nativeChannel.invokeMethod("onStop", null);
    }

    @Override
    public void onSeek(int position) {
        nativeChannel.invokeMethod("onSeek", position);
    }

    @Override
    public void onSpeed(float speed) {
        nativeChannel.invokeMethod("onSpeed", speed);
    }

    @Override
    public void onPush(String type, String url) {
        Map<String, String> params = new HashMap<>();
        params.put("type", type);
        params.put("url", url);
        nativeChannel.invokeMethod("onPush", params);
    }

    @Override
    public String onGetConfig() {
        // TODO: 获取配置
        return "{}";
    }

    @Override
    public void onSetConfig(String config) {
        // TODO: 设置配置
        nativeChannel.invokeMethod("onSetConfig", config);
    }

    @Override
    public void onClearConfig() {
        nativeChannel.invokeMethod("onClearConfig", null);
    }

    @Override
    public void onClearCache() {
        nativeChannel.invokeMethod("onClearCache", null);
    }

    @Override
    public String onSearch(String site, String wd, boolean quick) {
        // TODO: 实现搜索
        return "{\"code\": 0, \"msg\": \"success\"}";
    }

    @Override
    public String onDetail(String site, String id) {
        // TODO: 实现详情
        return "{\"code\": 0, \"msg\": \"success\"}";
    }

    @Override
    public String onHome(String site) {
        // TODO: 实现首页
        return "{\"code\": 0, \"msg\": \"success\"}";
    }

    @Override
    public String onCategory(String site, String tid, String pg, boolean filter, Map<String, String> params) {
        // TODO: 实现分类
        return "{\"code\": 0, \"msg\": \"success\"}";
    }

    @Override
    public String onProxyInvoke(String do, Map<String, String> params) {
        // TODO: 调用爬虫的 proxy 接口
        return "{\"code\": 0, \"msg\": \"success\"}";
    }
}
