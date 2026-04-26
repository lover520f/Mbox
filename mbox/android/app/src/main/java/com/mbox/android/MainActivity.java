package com.mbox.android;

import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "com.mbox.android/main";
    
    private MethodChannel methodChannel;
    private JsSpiderLoader jsLoader;
    
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        
        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "init":
                    init((Map<String, Object>) call.arguments);
                    result.success(true);
                    break;
                case "spiderInit":
                    String jar = call.argument("jar");
                    String extend = call.argument("extend");
                    spiderInit(jar, extend, result);
                    break;
                case "spiderHome":
                    String content = call.argument("content");
                    result.success(spiderHome(content));
                    break;
                case "spiderCategory":
                    result.success(spiderCategory(
                        call.argument("tid"),
                        call.argument("pg"),
                        call.argument("filter"),
                        call.argument("extend")
                    ));
                    break;
                case "spiderDetail":
                    result.success(spiderDetail(
                        call.argument("flag"),
                        call.argument("id")
                    ));
                    break;
                case "spiderPlay":
                    result.success(spiderPlay(
                        call.argument("flag"),
                        call.argument("id"),
                        call.argument("vipFlags")
                    ));
                    break;
                case "spiderSearch":
                    result.success(spiderSearch(
                        call.argument("quick"),
                        call.argument("wd")
                    ));
                    break;
                case "spiderDestroy":
                    spiderDestroy();
                    result.success(true);
                    break;
                case "jsSpiderInit":
                    String jsPath = call.argument("path");
                    jsSpiderInit(jsPath, result);
                    break;
                case "jsSpiderInvoke":
                    String func = call.argument("func");
                    String params = call.argument("params");
                    jsSpiderInvoke(func, params, result);
                    break;
                case "keepScreenOn":
                    boolean keepOn = call.argument("keepOn");
                    keepScreenOn(keepOn);
                    result.success(true);
                    break;
                default:
                    result.notImplemented();
            }
        });
        
        jsLoader = new JsSpiderLoader();
    }
    
    private void init(Map<String, Object> args) {
        try {
            Log.d(TAG, "Initializing...");
            // 从 assets 加载爬虫脚本
            if (jsLoader != null) {
                jsLoader.init(this, "spider.js");
                Log.d(TAG, "Spider loaded successfully");
            }
        } catch (Exception e) {
            Log.e(TAG, "Init error: " + e.getMessage());
        }
    }
    
    private void spiderInit(String jar, String extend, MethodChannel.Result result) {
        try {
            Log.d(TAG, "Spider init: " + jar);
            result.success("{\"code\": 200}");
        } catch (Exception e) {
            result.error("SPIDER_INIT_ERROR", e.getMessage(), null);
        }
    }
    
    private String spiderHome(String content) {
        return "{\"class\":[{\"type_id\":\"1\",\"type_name\":\"电影\"},{\"type_id\":\"2\",\"type_name\":\"电视剧\"}]}";
    }
    
    private String spiderCategory(String tid, String pg, String filter, String extend) {
        return "{\"list\":[],\"page\":1,\"pagecount\":1,\"limit\":20,\"total\":0}";
    }
    
    private String spiderDetail(String flag, String id) {
        return "{\"list\":[{\"vod_id\":\"" + id + "\",\"vod_name\":\"测试视频\",\"type_name\":\"测试\",\"vod_pic\":\"https://via.placeholder.com/300x450\",\"vod_remarks\":\"HD\",\"vod_year\":\"2024\",\"vod_area\":\"中国\",\"vod_content\":\"这是一个测试视频\",\"vod_play_from\":\"test\",\"vod_play_url\":\"第1集$http://example.com/video.mp4\"}]}";
    }
    
    private String spiderPlay(String flag, String id, String vipFlags) {
        return "{\"parse\":0,\"url\":\"http://example.com/video.mp4\"}";
    }
    
    private String spiderSearch(String quick, String wd) {
        return "{\"list\":[{\"vod_id\":\"1\",\"vod_name\":\"搜索结果\",\"type_name\":\"测试\",\"vod_pic\":\"https://via.placeholder.com/300x450\",\"vod_remarks\":\"HD\"}]}";
    }
    
    private void spiderDestroy() {
        Log.d(TAG, "Spider destroyed");
    }
    
    private void jsSpiderInit(String path, MethodChannel.Result result) {
        try {
            jsLoader.init(this, path);
            result.success(true);
        } catch (Exception e) {
            result.error("JS_INIT_ERROR", e.getMessage(), null);
        }
    }
    
    private void jsSpiderInvoke(String func, String params, MethodChannel.Result result) {
        try {
            String jsResult = jsLoader.invoke(func, params);
            result.success(jsResult != null ? jsResult : "");
        } catch (Exception e) {
            result.error("JS_INVOKE_ERROR", e.getMessage(), null);
        }
    }
    
    private void keepScreenOn(boolean keepOn) {
        runOnUiThread(() -> {
            if (keepOn) {
                getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            } else {
                getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            }
        });
    }
    
    @Override
    public void onDestroy() {
        super.onDestroy();
        if (jsLoader != null) {
            jsLoader.destroy();
        }
    }
}
