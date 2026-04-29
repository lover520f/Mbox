package com.mbox.android;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;
import dalvik.system.DexClassLoader;
import java.lang.reflect.Method;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

/**
 * JAR 爬虫加载器
 * 通过 DexClassLoader 加载 TVBox JAR 爬虫
 */
public class JarSpiderLoader {
    private static final String TAG = "JarSpiderLoader";
    
    private Object spiderInstance;
    private Class<?> spiderClass;
    private Method initMethod;
    private Method homeContentMethod;
    private Method categoryContentMethod;
    private Method detailContentMethod;
    private Method searchContentMethod;
    private Method playerContentMethod;
    private Method destroyMethod;
    
    private Context context;
    private String jarPath;
    private String extend;
    
    public JarSpiderLoader() {
    }
    
    /**
     * 初始化 JAR 爬虫
     * @param context 上下文
     * @param jarFile JAR 文件路径（可以是 assets 路径或本地路径）
     * @param extend 扩展参数
     */
    public void init(Context context, String jarFile, String extend) throws Exception {
        Log.d(TAG, "Initializing JAR spider: " + jarFile);
        this.context = context;
        this.jarPath = jarFile;
        this.extend = extend;
        
        // 从 assets 或本地加载 JAR 文件
        File dexOutputDir = context.getDir("dex", Context.MODE_PRIVATE);
        String optimizedDirectory = dexOutputDir.getAbsolutePath();
        
        // 复制 JAR 到临时目录
        File jarFileObj = copyJarToTemp(jarFile);
        
        // 创建 DexClassLoader
        DexClassLoader classLoader = new DexClassLoader(
            jarFileObj.getAbsolutePath(),
            optimizedDirectory,
            null,
            getClass().getClassLoader()
        );
        
        // 加载 Spider 类（TVBox 标准类名）
        try {
            spiderClass = classLoader.loadClass("com.github.catvospider.Spider");
        } catch (ClassNotFoundException e) {
            // 尝试其他常见类名
            try {
                spiderClass = classLoader.loadClass("Spider");
            } catch (ClassNotFoundException ex) {
                // 查找实现了 loadClass 方法的类
                Log.w(TAG, "Standard Spider class not found, searching...");
                // TODO: 遍历查找
                throw ex;
            }
        }
        
        // 创建实例
        spiderInstance = spiderClass.getDeclaredConstructor().newInstance();
        
        // 获取方法
        initMethod = spiderClass.getMethod("init", Context.class, String.class);
        homeContentMethod = spiderClass.getMethod("homeContent", boolean.class);
        categoryContentMethod = spiderClass.getMethod("categoryContent", 
            String.class, String.class, boolean.class, java.util.Map.class);
        detailContentMethod = spiderClass.getMethod("detailContent", java.util.List.class);
        searchContentMethod = spiderClass.getMethod("searchContent", 
            String.class, boolean.class);
        playerContentMethod = spiderClass.getMethod("playerContent", 
            String.class, String.class, java.util.List.class);
        destroyMethod = spiderClass.getMethod("destroy");
        
        // 调用 init
        initMethod.invoke(spiderInstance, context, extend);
        
        Log.d(TAG, "JAR spider initialized successfully");
    }
    
    /**
     * 复制 JAR 文件到临时目录
     */
    private File copyJarToTemp(String jarPath) throws Exception {
        File jarFile;
        
        if (jarPath.startsWith("assets://")) {
            // 从 assets 复制
            String assetPath = jarPath.substring("assets://".length());
            jarFile = File.createTempFile("spider_", ".jar");
            jarFile.deleteOnExit();
            
            AssetManager assets = context.getAssets();
            InputStream in = assets.open(assetPath);
            FileOutputStream out = new FileOutputStream(jarFile);
            
            byte[] buffer = new byte[8192];
            int len;
            while ((len = in.read(buffer)) != -1) {
                out.write(buffer, 0, len);
            }
            in.close();
            out.close();
        } else if (jarPath.startsWith("http://") || jarPath.startsWith("https://")) {
            // 从网络下载
            jarFile = File.createTempFile("spider_", ".jar");
            jarFile.deleteOnExit();
            
            // 使用 OkHttp 下载
            // TODO: 实现网络下载
            throw new UnsupportedOperationException("Network JAR download not implemented");
        } else {
            // 本地文件路径
            jarFile = new File(jarPath);
        }
        
        return jarFile;
    }
    
    /**
     * 首页内容
     */
    public String homeContent(boolean filter) throws Exception {
        if (spiderInstance == null || homeContentMethod == null) {
            return "{\"class\":[],\"filters\":{}}";
        }
        Object result = homeContentMethod.invoke(spiderInstance, filter);
        return result != null ? result.toString() : "{\"class\":[],\"filters\":{}}";
    }
    
    /**
     * 首页视频内容
     */
    public String homeVideoContent() throws Exception {
        // 默认返回空列表
        return "{\"list\":[]}";
    }
    
    /**
     * 分类内容
     */
    public String categoryContent(String tid, String pg, boolean filter, String extend) 
            throws Exception {
        if (spiderInstance == null || categoryContentMethod == null) {
            return "{\"list\":[],\"page\":1,\"pagecount\":1,\"limit\":20,\"total\":0}";
        }
        
        // 解析 extend 为 Map
        java.util.Map<String, String> extendMap = new java.util.HashMap<>();
        if (extend != null && !extend.isEmpty()) {
            try {
                org.json.JSONObject json = new org.json.JSONObject(extend);
                java.util.Iterator<String> keys = json.keys();
                while (keys.hasNext()) {
                    String key = keys.next();
                    extendMap.put(key, json.getString(key));
                }
            } catch (Exception e) {
                Log.w(TAG, "Parse extend error: " + e.getMessage());
            }
        }
        
        Object result = categoryContentMethod.invoke(
            spiderInstance, tid, pg, filter, extendMap);
        return result != null ? result.toString() : 
            "{\"list\":[],\"page\":1,\"pagecount\":1,\"limit\":20,\"total\":0}";
    }
    
    /**
     * 详情内容
     */
    public String detailContent(String id) throws Exception {
        if (spiderInstance == null || detailContentMethod == null) {
            return "{\"list\":[]}";
        }
        
        java.util.List<String> ids = new java.util.ArrayList<>();
        ids.add(id);
        
        Object result = detailContentMethod.invoke(spiderInstance, ids);
        return result != null ? result.toString() : "{\"list\":[]}";
    }
    
    /**
     * 搜索内容
     */
    public String searchContent(String key, boolean quick) throws Exception {
        if (spiderInstance == null || searchContentMethod == null) {
            return "{\"list\":[]}";
        }
        
        Object result = searchContentMethod.invoke(spiderInstance, key, quick);
        return result != null ? result.toString() : "{\"list\":[]}";
    }
    
    /**
     * 播放内容
     */
    public String playerContent(String flag, String id, String vipFlags) throws Exception {
        if (spiderInstance == null || playerContentMethod == null) {
            return "{\"parse\":0,\"url\":\"\"}";
        }
        
        // 解析 vipFlags
        java.util.List<String> flagsList = new java.util.ArrayList<>();
        if (vipFlags != null && !vipFlags.isEmpty()) {
            try {
                org.json.JSONArray json = new org.json.JSONArray(vipFlags);
                for (int i = 0; i < json.length(); i++) {
                    flagsList.add(json.getString(i));
                }
            } catch (Exception e) {
                Log.w(TAG, "Parse vipFlags error: " + e.getMessage());
            }
        }
        
        Object result = playerContentMethod.invoke(
            spiderInstance, flag, id, flagsList);
        return result != null ? result.toString() : "{\"parse\":0,\"url\":\"\"}";
    }
    
    /**
     * 销毁爬虫
     */
    public void destroy() {
        try {
            if (spiderInstance != null && destroyMethod != null) {
                destroyMethod.invoke(spiderInstance);
            }
        } catch (Exception e) {
            Log.e(TAG, "Destroy error: " + e.getMessage());
        } finally {
            spiderInstance = null;
            spiderClass = null;
            initMethod = null;
            homeContentMethod = null;
            categoryContentMethod = null;
            detailContentMethod = null;
            searchContentMethod = null;
            playerContentMethod = null;
            destroyMethod = null;
        }
    }
}
