package com.mbox.android;

import android.content.Context;
import android.util.Log;

import app.cash.quickjs.QuickJs;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.json.JSONObject;
import org.json.JSONArray;

/**
 * JavaScript 爬虫加载器 - 使用 QuickJS 引擎
 */
public class JsSpiderLoader {
    private static final String TAG = "JsSpiderLoader";
    
    private final Context context;
    private final Map<String, QuickJs> jsEngines = new HashMap<>();
    private final Map<String, String> jsScripts = new HashMap<>();
    private final ExecutorService executor = Executors.newCachedThreadPool();
    
    public JsSpiderLoader(Context context) {
        this.context = context;
    }
    
    /**
     * 加载 JS 脚本
     */
    public void loadJs(String key, String jsCode, JsCallback callback) {
        executor.execute(() -> {
            try {
                Log.d(TAG, "Loading JS: " + key);
                
                // 创建 QuickJS 引擎
                QuickJs quickJs = QuickJs.create();
                if (quickJs == null) {
                    callback.onError("Failed to create QuickJS engine");
                    return;
                }
                
                // 执行脚本
                Object result = quickJs.evaluate(jsCode);
                if (result instanceof String) {
                    String error = (String) result;
                    Log.e(TAG, "JS error: " + error);
                    callback.onError(error);
                    return;
                }
                
                // 存储引擎和脚本
                jsEngines.put(key, quickJs);
                jsScripts.put(key, jsCode);
                
                Log.d(TAG, "JS loaded successfully: " + key);
                callback.onSuccess();
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to load JS: " + key, e);
                callback.onError(e.getMessage());
            }
        });
    }
    
    /**
     * 调用 JS 方法
     */
    public void callJs(String key, String method, Object[] args, JsResultCallback callback) {
        executor.execute(() -> {
            try {
                QuickJs quickJs = jsEngines.get(key);
                if (quickJs == null) {
                    callback.onError("JS engine not found: " + key);
                    return;
                }
                
                // 构造调用参数
                JSONArray jsonArgs = new JSONArray();
                for (Object arg : args) {
                    jsonArgs.put(arg != null ? arg : JSONObject.NULL);
                }
                
                // 生成调用代码
                String callCode = String.format(
                    "(function() { try { return JSON.stringify(%s(%s)); } catch(e) { return JSON.stringify({error: e.message}); } })()",
                    method,
                    jsonArgs.toString()
                );
                
                // 执行调用
                Object result = quickJs.evaluate(callCode);
                
                if (result instanceof String) {
                    String resultStr = (String) result;
                    if (resultStr.contains("\"error\"")) {
                        JSONObject errorObj = new JSONObject(resultStr);
                        callback.onError(errorObj.optString("error"));
                    } else {
                        callback.onSuccess(resultStr);
                    }
                } else {
                    callback.onError("Invalid result type");
                }
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to call JS: " + key + "." + method, e);
                callback.onError(e.getMessage());
            }
        });
    }
    
    /**
     * 卸载 JS
     */
    public void unloadJs(String key) {
        QuickJs quickJs = jsEngines.remove(key);
        if (quickJs != null) {
            quickJs.destroy();
            Log.d(TAG, "JS unloaded: " + key);
        }
        jsScripts.remove(key);
    }
    
    /**
     * 清理所有
     */
    public void destroyAll() {
        for (QuickJs quickJs : jsEngines.values()) {
            try {
                quickJs.destroy();
            } catch (Exception e) {
                Log.e(TAG, "Failed to destroy JS engine", e);
            }
        }
        jsEngines.clear();
        jsScripts.clear();
        Log.d(TAG, "All JS engines destroyed");
    }
    
    /**
     * 检查是否已加载
     */
    public boolean hasJs(String key) {
        return jsEngines.containsKey(key);
    }
    
    public interface JsCallback {
        void onSuccess();
        void onError(String error);
    }
    
    public interface JsResultCallback {
        void onSuccess(String result);
        void onError(String error);
    }
}