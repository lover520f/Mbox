package com.mbox.android;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import fi.iki.elonen.NanoHTTPD;

/**
 * HTTP 服务器 - 提供本地 API 服务（9978-9998 端口）
 * 兼容 FongMi/TV 的本地 HTTP API
 */
public class LocalHttpServer extends NanoHTTPD {
    private static final String TAG = "LocalHttpServer";
    private static final int DEFAULT_PORT = 9978;
    
    private final Context context;
    private final ApiHandler apiHandler;
    private final ExecutorService executor = Executors.newCachedThreadPool();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    
    public LocalHttpServer(Context context, ApiHandler apiHandler) {
        super(DEFAULT_PORT);
        this.context = context;
        this.apiHandler = apiHandler;
    }
    
    public LocalHttpServer(Context context, int port, ApiHandler apiHandler) {
        super(port);
        this.context = context;
        this.apiHandler = apiHandler;
    }
    
    @Override
    public Response serve(IHTTPSession session) {
        String uri = session.getUri();
        Method method = session.getMethod();
        
        Log.d(TAG, "Request: " + method + " " + uri);
        
        try {
            // 路由处理
            if (uri.startsWith("/api/")) {
                return handleApi(session, uri.substring(5), method);
            } else if (uri.startsWith("/proxy/")) {
                return handleProxy(session, uri.substring(7), method);
            } else if (uri.startsWith("/adb/")) {
                return handleAdb(session, uri.substring(5), method);
            } else {
                return handleStatic(session, uri, method);
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error handling request: " + uri, e);
            return newFixedLengthResponse(Response.Status.INTERNAL_ERROR, 
                MIME_PLAINTEXT, "Internal Server Error: " + e.getMessage());
        }
    }
    
    /**
     * 处理 API 请求
     */
    private Response handleApi(IHTTPSession session, String path, Method method) throws Exception {
        String[] parts = path.split("/");
        if (parts.length < 1) {
            return jsonResponse("{\"error\": \"Invalid path\"}");
        }
        
        String action = parts[0];
        Map<String, String> params = session.getParms();
        String body = parseBody(session);
        
        switch (action) {
            case "play":
                // 播放控制
                return handlePlay(params, body);
                
            case "push":
                // 内容推送
                return handlePush(params, body);
                
            case "config":
                // 配置管理
                return handleConfig(params, body);
                
            case "cache":
                // 缓存操作
                return handleCache(params, body);
                
            case "search":
                // 搜索
                return handleSearch(params, body);
                
            case "detail":
                // 详情
                return handleDetail(params, body);
                
            case "home":
                // 首页
                return handleHome(params, body);
                
            case "category":
                // 分类
                return handleCategory(params, body);
                
            default:
                return jsonResponse("{\"error\": \"Unknown action: " + action + "\"}");
        }
    }
    
    /**
     * 处理代理请求
     */
    private Response handleProxy(IHTTPSession session, String path, Method method) throws Exception {
        // 代理到爬虫的 proxy 接口
        Map<String, String> params = session.getParms();
        String do = params.get("do");
        
        if (do == null) {
            return jsonResponse("{\"error\": \"Missing 'do' parameter\"}");
        }
        
        String result = apiHandler.onProxyInvoke(do, params);
        return newFixedLengthResponse(Response.Status.OK, 
            "application/json", result);
    }
    
    /**
     * 处理 ADB 推送
     */
    private Response handleAdb(IHTTPSession session, String path, Method method) {
        // ADB 推送处理
        return newFixedLengthResponse(Response.Status.OK, 
            MIME_PLAINTEXT, "OK");
    }
    
    /**
     * 处理静态文件
     */
    private Response handleStatic(IHTTPSession session, String path, Method method) {
        // 静态文件服务
        return newFixedLengthResponse(Response.Status.NOT_FOUND, 
            MIME_PLAINTEXT, "Not Found");
    }
    
    /**
     * 播放控制
     */
    private Response handlePlay(Map<String, String> params, String body) {
        String action = params.get("action");
        if (action == null) {
            return jsonResponse("{\"error\": \"Missing action\"}");
        }
        
        switch (action) {
            case "play":
                float position = parseFloat(params.get("position"), 0);
                apiHandler.onPlay(position);
                break;
                
            case "pause":
                apiHandler.onPause();
                break;
                
            case "resume":
                apiHandler.onResume();
                break;
                
            case "stop":
                apiHandler.onStop();
                break;
                
            case "seek":
                int pos = parseInt(params.get("pos"), 0);
                apiHandler.onSeek(pos);
                break;
                
            case "speed":
                float speed = parseFloat(params.get("speed"), 1.0f);
                apiHandler.onSpeed(speed);
                break;
        }
        
        return jsonResponse("{\"code\": 0, \"msg\": \"success\"}");
    }
    
    /**
     * 内容推送
     */
    private Response handlePush(Map<String, String> params, String body) {
        String type = params.get("type");
        String url = params.get("url");
        
        if (url == null) {
            return jsonResponse("{\"error\": \"Missing url\"}");
        }
        
        apiHandler.onPush(type, url);
        return jsonResponse("{\"code\": 0, \"msg\": \"success\"}");
    }
    
    /**
     * 配置管理
     */
    private Response handleConfig(Map<String, String> params, String body) {
        String action = params.get("action");
        
        if ("get".equals(action)) {
            String config = apiHandler.onGetConfig();
            return jsonResponse(config != null ? config : "{}");
        } else if ("set".equals(action)) {
            apiHandler.onSetConfig(body);
            return jsonResponse("{\"code\": 0, \"msg\": \"success\"}");
        } else if ("clear".equals(action)) {
            apiHandler.onClearConfig();
            return jsonResponse("{\"code\": 0, \"msg\": \"success\"}");
        }
        
        return jsonResponse("{\"error\": \"Invalid action\"}");
    }
    
    /**
     * 缓存操作
     */
    private Response handleCache(Map<String, String> params, String body) {
        String action = params.get("action");
        
        if ("clear".equals(action)) {
            apiHandler.onClearCache();
            return jsonResponse("{\"code\": 0, \"msg\": \"success\"}");
        }
        
        return jsonResponse("{\"error\": \"Invalid action\"}");
    }
    
    /**
     * 搜索
     */
    private Response handleSearch(Map<String, String> params, String body) {
        String site = params.get("site");
        String wd = params.get("wd");
        boolean quick = Boolean.parseBoolean(params.get("quick"));
        
        if (site == null || wd == null) {
            return jsonResponse("{\"error\": \"Missing parameters\"}");
        }
        
        executor.execute(() -> {
            String result = apiHandler.onSearch(site, wd, quick);
            // 结果将通过其他方式返回
        });
        
        return jsonResponse("{\"code\": 0, \"msg\": \"searching\"}");
    }
    
    /**
     * 详情
     */
    private Response handleDetail(Map<String, String> params, String body) {
        String site = params.get("site");
        String id = params.get("id");
        
        if (site == null || id == null) {
            return jsonResponse("{\"error\": \"Missing parameters\"}");
        }
        
        executor.execute(() -> {
            String result = apiHandler.onDetail(site, id);
            // 结果将通过其他方式返回
        });
        
        return jsonResponse("{\"code\": 0, \"msg\": \"loading\"}");
    }
    
    /**
     * 首页
     */
    private Response handleHome(Map<String, String> params, String body) {
        String site = params.get("site");
        
        if (site == null) {
            return jsonResponse("{\"error\": \"Missing site\"}");
        }
        
        executor.execute(() -> {
            String result = apiHandler.onHome(site);
            // 结果将通过其他方式返回
        });
        
        return jsonResponse("{\"code\": 0, \"msg\": \"loading\"}");
    }
    
    /**
     * 分类
     */
    private Response handleCategory(Map<String, String> params, String body) {
        String site = params.get("site");
        String tid = params.get("tid");
        String pg = params.get("pg");
        boolean filter = Boolean.parseBoolean(params.get("filter"));
        
        if (site == null || tid == null) {
            return jsonResponse("{\"error\": \"Missing parameters\"}");
        }
        
        executor.execute(() -> {
            String result = apiHandler.onCategory(site, tid, pg, filter, params);
            // 结果将通过其他方式返回
        });
        
        return jsonResponse("{\"code\": 0, \"msg\": \"loading\"}");
    }
    
    /**
     * 解析请求体
     */
    private String parseBody(IHTTPSession session) throws IOException {
        if (session.getHeaders().get("content-length") == null) {
            return "";
        }
        
        int contentLength = Integer.parseInt(session.getHeaders().get("content-length"));
        byte[] buffer = new byte[contentLength];
        session.getInputStream().read(buffer, 0, contentLength);
        return new String(buffer, "UTF-8");
    }
    
    /**
     * JSON 响应
     */
    private Response jsonResponse(String json) {
        return newFixedLengthResponse(Response.Status.OK, "application/json", json);
    }
    
    private int parseInt(String value, int defaultValue) {
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }
    
    private float parseFloat(String value, float defaultValue) {
        try {
            return Float.parseFloat(value);
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }
    
    /**
     * API 处理器接口
     */
    public interface ApiHandler {
        void onPlay(float position);
        void onPause();
        void onResume();
        void onStop();
        void onSeek(int position);
        void onSpeed(float speed);
        void onPush(String type, String url);
        String onGetConfig();
        void onSetConfig(String config);
        void onClearConfig();
        void onClearCache();
        String onSearch(String site, String wd, boolean quick);
        String onDetail(String site, String id);
        String onHome(String site);
        String onCategory(String site, String tid, String pg, boolean filter, Map<String, String> params);
        String onProxyInvoke(String do, Map<String, String> params);
    }
}
