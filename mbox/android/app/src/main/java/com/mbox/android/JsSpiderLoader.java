package com.mbox.android;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Looper;
import android.os.Handler;
import android.util.Log;
import app.cash.quickjs.QuickJs;
import java.util.concurrent.CountDownLatch;
import org.json.JSONObject;

/**
 * JS 爬虫加载器
 * 使用 QuickJS 引擎执行 TVBox JS 爬虫脚本
 */
public class JsSpiderLoader {
    private static final String TAG = "JsSpiderLoader";
    
    private QuickJs quickJs;
    private Handler mainHandler;
    private boolean initialized = false;
    private boolean isReady = false;
    
    public JsSpiderLoader() {
        mainHandler = new Handler(Looper.getMainLooper());
    }
    
    public void init(Context context, String path) throws Exception {
        Log.d(TAG, "Loading JS spider: " + (path != null ? path : "spider.js"));
        
        // 创建 QuickJS 引擎
        quickJs = QuickJs.create();
        
        // 读取 JS 文件
        String jsCode = loadJsFile(context.getAssets(), path != null ? path : "spider.js");
        
        // 评估 JS 代码
        try {
            quickJs.evaluate("(function() { " + jsCode + " return true; })();");
            Log.d(TAG, "JS spider loaded successfully");
            
            // 调用 init 方法
            String result = invoke("init", "{}");
            Log.d(TAG, "Spider init result: " + result);
            initialized = true;
            isReady = true;
        } catch (Exception e) {
            Log.e(TAG, "JS evaluate error: " + e.getMessage());
            throw e;
        }
    }
    
    private String loadJsFile(AssetManager assets, String fileName) throws Exception {
        java.io.InputStream is = assets.open(fileName);
        byte[] buffer = new byte[is.available()];
        is.read(buffer);
        is.close();
        
        StringBuilder sb = new StringBuilder(new String(buffer, java.nio.charset.StandardCharsets.UTF_8));
        
        // 添加 polyfill
        String polyfill = getJsPolyfill();
        return polyfill + "\n" + sb.toString();
    }
    
    /**
     * JS Polyfill - 提供浏览器环境的兼容性代码
     */
    private String getJsPolyfill() {
        return 
        // Console log
        "var console = { log: function(m) { }, " +
        "  error: function(m) { }, " +
        "  debug: function(m) { } }; " +
        // Base64 encode/decode
        "var atob = function(s) { return android.util.Base64.decode(s, android.util.Base64.DEFAULT); }; " +
        "var btoa = function(s) { return android.util.Base64.encodeToString(s.getBytes(), android.util.Base64.DEFAULT); }; " +
        "";
    }
    
    public String invoke(final String func, final String params) {
        try {
            if (!initialized || quickJs == null) {
                Log.e(TAG, "Spider not initialized");
                return "";
            }
            
            // 构建 JS 调用代码
            String jsCode = "JSON.stringify(" + func + "(" + params + "))";
            
            // 执行 JS 并获取结果
            Object result = quickJs.evaluate(jsCode);
            
            if (result instanceof String) {
                return (String) result;
            } else if (result != null) {
                return result.toString();
            }
            
            return "";
        } catch (Exception e) {
            Log.e(TAG, "Invoke error (" + func + "): " + e.getMessage());
            return "";
        }
    }
    
    public void destroy() {
        try {
            if (quickJs != null) {
                quickJs = null;
            }
            initialized = false;
            isReady = false;
            Log.d(TAG, "JS spider destroyed");
        } catch (Exception e) {
            Log.e(TAG, "Destroy error: " + e.getMessage());
        }
    }
}
