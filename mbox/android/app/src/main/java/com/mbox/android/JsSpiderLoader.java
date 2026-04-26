package com.mbox.android;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Looper;
import android.os.Handler;
import android.util.Log;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.ValueCallback;
import androidx.annotation.NonNull;
import java.util.concurrent.CountDownLatch;
import org.json.JSONObject;

public class JsSpiderLoader {
    private static final String TAG = "JsSpiderLoader";
    
    private WebView webView;
    private Handler mainHandler;
    private boolean initialized = false;
    private boolean isReady = false;
    
    public JsSpiderLoader() {
        mainHandler = new Handler(Looper.getMainLooper());
        // 使用 WebView 作为 JS 引擎
        mainHandler.post(() -> {
            webView = new WebView(getContext());
            webView.getSettings().setJavaScriptEnabled(true);
            webView.setWebChromeClient(null);
            webView.addJavascriptInterface(new JsBridge(), "Android");
            webView.setWebViewClient(new WebViewClient() {
                @Override
                public void onPageFinished(WebView view, String url) {
                    super.onPageFinished(view, url);
                    // 页面加载完成
                }
            });
            Log.d(TAG, "WebView spider initialized");
        });
    }
    
    private Context getContext() {
        // 通过反射获取 Application Context
        try {
            Class<?> activityThreadClass = Class.forName("android.app.ActivityThread");
            java.lang.reflect.Method currentActivityThreadMethod = activityThreadClass.getMethod("currentActivityThread");
            Object activityThread = currentActivityThreadMethod.invoke(null);
            java.lang.reflect.Method getApplicationMethod = activityThreadClass.getMethod("getApplication");
            return (Context) getApplicationMethod.invoke(activityThread);
        } catch (Exception e) {
            Log.e(TAG, "Get context error: " + e.getMessage());
            return null;
        }
    }
    
    public void init(@NonNull Context context, String path) throws Exception {
        Log.d(TAG, "Loading JS spider: " + (path != null ? path : "spider.js"));
        
        if (webView == null) {
            throw new IllegalStateException("WebView not initialized");
        }
        
        // 读取 JS 文件
        String jsCode = loadJsFile(context.getAssets(), path != null ? path : "spider.js");
        
        // 在 WebView 中执行 JS 代码
        final boolean[] success = {false};
        final Exception[] error = {null};
        
        mainHandler.post(() -> {
            try {
                webView.evaluateJavascript("(function() { " + jsCode + " return true; })();", 
                    new ValueCallback<String>() {
                        @Override
                        public void onReceiveValue(String value) {
                            if ("true".equals(value)) {
                                success[0] = true;
                                Log.d(TAG, "JS spider loaded successfully");
                            } else {
                                error[0] = new Exception("JS load failed: " + value);
                            }
                        }
                    });
            } catch (Exception e) {
                error[0] = e;
            }
        });
        
        // 等待加载完成
        Thread.sleep(500);
        
        if (error[0] != null) {
            throw error[0];
        }
        
        // 调用 init 方法
        String result = invoke("init", "{}");
        Log.d(TAG, "Spider init result: " + result);
        initialized = true;
        isReady = true;
    }
    
    private String loadJsFile(AssetManager assets, String fileName) throws Exception {
        StringBuilder sb = new StringBuilder();
        java.io.BufferedReader reader = new java.io.BufferedReader(
            new java.io.InputStreamReader(assets.open(fileName), java.nio.charset.StandardCharsets.UTF_8)
        );
        
        String line;
        while ((line = reader.readLine()) != null) {
            sb.append(line).append("\n");
        }
        reader.close();
        
        return sb.toString();
    }
    
    public String invoke(final String func, final String params) {
        try {
            if (!initialized || webView == null) {
                Log.e(TAG, "Spider not initialized");
                return "";
            }
            
            final String[] result = {""};
            final CountDownLatch latch = new java.util.concurrent.CountDownLatch(1);
            
            mainHandler.post(() -> {
                try {
                    String js = "JSON.stringify(" + func + "(" + params + "))";
                    webView.evaluateJavascript(js, new ValueCallback<String>() {
                        @Override
                        public void onReceiveValue(String value) {
                            // WebView 的 evaluateJavascript 返回的是带引号的字符串
                            if (value != null && value.startsWith("\"") && value.endsWith("\"")) {
                                value = value.substring(1, value.length() - 1);
                            }
                            result[0] = value != null ? value : "";
                            latch.countDown();
                        }
                    });
                } catch (Exception e) {
                    Log.e(TAG, "Invoke error: " + e.getMessage());
                    latch.countDown();
                }
            });
            
            latch.await();
            return result[0];
        } catch (Exception e) {
            Log.e(TAG, "Invoke error (" + func + "): " + e.getMessage());
            return "";
        }
    }
    
    public void destroy() {
        try {
            if (webView != null) {
                mainHandler.post(() -> {
                    webView.evaluateJavascript("destroy()", null);
                    webView.destroy();
                    webView = null;
                });
            }
            initialized = false;
            isReady = false;
            Log.d(TAG, "JS spider destroyed");
        } catch (Exception e) {
            Log.e(TAG, "Destroy error: " + e.getMessage());
        }
    }
    
    // JS Bridge
    public class JsBridge {
        @JavascriptInterface
        public void log(String message) {
            Log.d(TAG, "JS Log: " + message);
        }
    }
}
