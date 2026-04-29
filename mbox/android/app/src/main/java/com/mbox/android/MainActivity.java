package com.mbox.android;

import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import org.json.JSONObject;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "com.mbox.android/main";
    
    private MethodChannel methodChannel;
    private JsSpiderLoader jsLoader;
    private JarSpiderLoader jarLoader;
    private int currentSpiderType = 0; // 0=JS, 3=JAR
    
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
                case "initSpider":
                    Integer type = call.argument("type");
                    String spiderPath = call.argument("path");
                    String extend = call.argument("extend");
                    initSpider(type, spiderPath, extend, result);
                    break;
                case "spiderHome":
                    Boolean filter = call.argument("filter");
                    result.success(spiderHome(filter != null && filter));
                    break;
                case "spiderCategory":
                    result.success(spiderCategory(
                        call.argument("tid"),
                        call.argument("pg"),
                        call.argument("filter") != null && (Boolean) call.argument("filter"),
                        call.argument("extend")
                    ));
                    break;
                case "spiderDetail":
                    String id = call.argument("id");
                    result.success(spiderDetail(id));
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
                case "keepScreenOn":
                    boolean keepOn = call.argument("keepOn") != null && (boolean) call.argument("keepOn");
                    keepScreenOn(keepOn);
                    result.success(true);
                    break;
                default:
                    result.notImplemented();
            }
        });
        
        jsLoader = new JsSpiderLoader();
        jarLoader = new JarSpiderLoader();
    }
    
    private void init(Map<String, Object> args) {
        try {
            Log.d(TAG, "Initializing...");
        } catch (Exception e) {
            Log.e(TAG, "Init error: " + e.getMessage());
        }
    }
    
    private void initSpider(Integer type, String path, String extend, MethodChannel.Result result) {
        try {
            if (type == null) {
                result.error("INVALID_TYPE", "Spider type is required", null);
                return;
            }
            
            currentSpiderType = type;
            Log.d(TAG, "Init spider: type=" + type + ", path=" + path);
            
            if (type == 0 || type == 1 || type == 4) {
                // JS Spider (Type 0=XML 中的 JS, Type 1/4=JSON 中的 JS)
                jsLoader.init(this, path);
                result.success("{\"code\": 200, \"msg\": \"JS spider initialized\"}");
            } else if (type == 3) {
                // JAR Spider (Type 3)
                jarLoader.init(this, path, extend != null ? extend : "");
                result.success("{\"code\": 200, \"msg\": \"JAR spider initialized\"}");
            } else {
                result.error("UNSUPPORTED_TYPE", "Unsupported spider type: " + type, null);
            }
        } catch (Exception e) {
            Log.e(TAG, "Spider init error: " + e.getMessage());
            result.error("SPIDER_INIT_ERROR", e.getMessage(), null);
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
    
    private String spiderHome(boolean filter) {
        try {
            if (currentSpiderType == 3) {
                return jarLoader.homeContent(filter);
            } else {
                return jsLoader.invoke("home", "{}");
            }
        } catch (Exception e) {
            Log.e(TAG, "Home error: " + e.getMessage());
            return "{\"class\":[],\"filters\":{}}";
        }
    }
    
    private String spiderCategory(String tid, String pg, boolean filter, String extend) {
        try {
            if (currentSpiderType == 3) {
                return jarLoader.categoryContent(tid, pg, filter, extend != null ? extend : "");
            } else {
                String params = new JSONObject()
                    .put("tid", tid)
                    .put("page", pg)
                    .put("filter", filter)
                    .put("extend", extend != null ? extend : "")
                    .toString();
                return jsLoader.invoke("category", params);
            }
        } catch (Exception e) {
            Log.e(TAG, "Category error: " + e.getMessage());
            return "{\"list\":[],\"page\":1,\"pagecount\":1,\"limit\":20,\"total\":0}";
        }
    }
    
    private String spiderDetail(String id) {
        try {
            if (currentSpiderType == 3) {
                return jarLoader.detailContent(id);
            } else {
                String params = new JSONObject()
                    .put("flag", "")
                    .put("id", id)
                    .toString();
                return jsLoader.invoke("detail", params);
            }
        } catch (Exception e) {
            Log.e(TAG, "Detail error: " + e.getMessage());
            return "{\"list\":[]}";
        }
    }
    
    private String spiderPlay(String flag, String id, String vipFlags) {
        try {
            if (currentSpiderType == 3) {
                return jarLoader.playerContent(flag != null ? flag : "", id != null ? id : "", vipFlags != null ? vipFlags : "");
            } else {
                String params = new JSONObject()
                    .put("flag", flag != null ? flag : "")
                    .put("id", id != null ? id : "")
                    .put("vipFlags", vipFlags != null ? vipFlags : "")
                    .toString();
                return jsLoader.invoke("play", params);
            }
        } catch (Exception e) {
            Log.e(TAG, "Play error: " + e.getMessage());
            return "{\"parse\":0,\"url\":\"\"}";
        }
    }
    
    private String spiderSearch(Object quick, String wd) {
        try {
            boolean quickSearch = quick != null && (quick instanceof Boolean ? (Boolean) quick : quick.equals("true"));
            if (currentSpiderType == 3) {
                return jarLoader.searchContent(wd != null ? wd : "", quickSearch);
            } else {
                String params = new JSONObject()
                    .put("quick", quickSearch)
                    .put("wd", wd != null ? wd : "")
                    .toString();
                return jsLoader.invoke("search", params);
            }
        } catch (Exception e) {
            Log.e(TAG, "Search error: " + e.getMessage());
            return "{\"list\":[]}";
        }
    }
    
    private void spiderDestroy() {
        try {
            if (currentSpiderType == 3) {
                jarLoader.destroy();
            } else {
                jsLoader.destroy();
            }
            Log.d(TAG, "Spider destroyed");
        } catch (Exception e) {
            Log.e(TAG, "Destroy error: " + e.getMessage());
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
        if (jarLoader != null) {
            jarLoader.destroy();
        }
    }
}
