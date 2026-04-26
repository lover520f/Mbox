package com.mbox.android;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Base64;
import android.util.Log;

import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import dalvik.system.DexClassLoader;

/**
 * JAR 爬虫加载器 - 使用 DexClassLoader 加载 Java 爬虫
 */
public class JarSpiderLoader {
    private static final String TAG = "JarSpiderLoader";
    private static final String OPTIMIZED_DIR = "optimized_jars";
    
    private final Context context;
    private final Map<String, Object> loadedJars = new HashMap<>();
    private final Map<String, Class<?>> spiderClasses = new HashMap<>();
    private final ExecutorService executor = Executors.newCachedThreadPool();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    
    public JarSpiderLoader(Context context) {
        this.context = context;
    }
    
    /**
     * 加载 JAR 文件
     */
    public void loadJar(String key, String jarPath, String libPath, ClassLoader parent) {
        executor.execute(() -> {
            try {
                File jarFile = new File(jarPath);
                if (!jarFile.exists()) {
                    Log.e(TAG, "JAR file not found: " + jarPath);
                    postError(key, "JAR file not found");
                    return;
                }
                
                // 创建优化目录
                File optimizedDir = new File(context.getDir(OPTIMIZED_DIR, Context.MODE_PRIVATE), key);
                if (!optimizedDir.exists()) {
                    optimizedDir.mkdirs();
                }
                
                // 创建 DexClassLoader
                DexClassLoader classLoader = new DexClassLoader(
                    jarPath,
                    optimizedDir.getAbsolutePath(),
                    libPath,
                    parent
                );
                
                // 加载 Spider 类
                Class<?> spiderClass = classLoader.loadClass("cat.fox.spider.Spider");
                spiderClasses.put(key, spiderClass);
                loadedJars.put(key, classLoader);
                
                Log.d(TAG, "JAR loaded successfully: " + key);
                postSuccess(key);
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to load JAR: " + key, e);
                postError(key, e.getMessage());
            }
        });
    }
    
    /**
     * 调用 Spider 方法
     */
    public void callSpider(String key, String method, Object[] args, SpiderCallback callback) {
        executor.execute(() -> {
            try {
                Class<?> spiderClass = spiderClasses.get(key);
                if (spiderClass == null) {
                    Log.e(TAG, "Spider not found: " + key);
                    mainHandler.post(() -> callback.onError("Spider not found"));
                    return;
                }
                
                // 创建 Spider 实例
                Object spider = spiderClass.getDeclaredConstructor().newInstance();
                
                // 调用方法
                java.lang.reflect.Method spiderMethod = spiderClass.getMethod(method, String.class);
                Object result = spiderMethod.invoke(spider, args[0]);
                
                mainHandler.post(() -> callback.onSuccess(result));
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to call spider: " + key + "." + method, e);
                mainHandler.post(() -> callback.onError(e.getMessage()));
            }
        });
    }
    
    /**
     * 调用带多个参数的方法
     */
    public void callSpiderMultiArgs(String key, String method, Class<?>[] paramTypes, Object[] args, SpiderCallback callback) {
        executor.execute(() -> {
            try {
                Class<?> spiderClass = spiderClasses.get(key);
                if (spiderClass == null) {
                    Log.e(TAG, "Spider not found: " + key);
                    mainHandler.post(() -> callback.onError("Spider not found"));
                    return;
                }
                
                Object spider = spiderClass.getDeclaredConstructor().newInstance();
                java.lang.reflect.Method spiderMethod = spiderClass.getMethod(method, paramTypes);
                Object result = spiderMethod.invoke(spider, args);
                
                mainHandler.post(() -> callback.onSuccess(result));
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to call spider: " + key + "." + method, e);
                mainHandler.post(() -> callback.onError(e.getMessage()));
            }
        });
    }
    
    /**
     * 卸载 JAR
     */
    public void unloadJar(String key) {
        loadedJars.remove(key);
        spiderClasses.remove(key);
        Log.d(TAG, "JAR unloaded: " + key);
    }
    
    /**
     * 清理所有
     */
    public void destroyAll() {
        loadedJars.clear();
        spiderClasses.clear();
        executor.shutdown();
        Log.d(TAG, "All JARs destroyed");
    }
    
    private void postSuccess(String key) {
        mainHandler.post(() -> Log.d(TAG, "Success: " + key));
    }
    
    private void postError(String key, String error) {
        mainHandler.post(() -> Log.e(TAG, "Error: " + key + " - " + error));
    }
    
    /**
     * Spider 回调接口
     */
    public interface SpiderCallback {
        void onSuccess(Object result);
        void onError(String error);
    }
}
