package com.mbox.android;

import android.content.Context;
import android.net.wifi.WifiManager;
import android.util.Log;

import org.fourthline.cling.android.AndroidUpnpService;
import org.fourthline.cling.android.AndroidUpnpServiceImpl;
import org.fourthline.cling.model.action.ActionInvocation;
import org.fourthline.cling.model.message.UpnpResponse;
import org.fourthline.cling.model.meta.Device;
import org.fourthline.cling.model.types.ServiceType;
import org.fourthline.cling.model.types.UDADeviceType;
import org.fourthline.cling.support.avtransport.callback.Play;
import org.fourthline.cling.support.avtransport.callback.Pause;
import org.fourthline.cling.support.avtransport.callback.SetAVTransportURI;
import org.fourthline.cling.support.avtransport.callback.Stop;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * DLNA 控制器 - 完整集成 Cling 2.1.1
 */
public class DlnaController {
    private static final String TAG = "DlnaController";
    
    private final Context context;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    
    private AndroidUpnpService upnpService;
    private boolean isRunning = false;
    private final List<DlnaDevice> discoveredDevices = new ArrayList<>();
    
    private static final ServiceType[] SEARCH_TYPES = {
        new UDADeviceType("MediaRenderer")
    };
    
    public DlnaController(Context context) {
        this.context = context;
    }
    
    public void start() {
        if (isRunning) return;
        
        executor.execute(() -> {
            try {
                upnpService = new AndroidUpnpServiceImpl(context);
                Thread.sleep(1000);
                upnpService.getRegistry().enableNotifications(true);
                isRunning = true;
                Log.d(TAG, "DLNA service started");
            } catch (Exception e) {
                Log.e(TAG, "Failed to start DLNA service", e);
            }
        });
    }
    
    public void stop() {
        if (!isRunning || upnpService == null) return;
        
        executor.execute(() -> {
            try {
                upnpService.getRegistry().enableNotifications(false);
                upnpService.getRegistry().removeAllRemoteDevices();
                isRunning = false;
                discoveredDevices.clear();
                Log.d(TAG, "DLNA service stopped");
            } catch (Exception e) {
                Log.e(TAG, "Failed to stop DLNA service", e);
            }
        });
    }
    
    public void searchDevices(DlnaDeviceCallback callback) {
        if (!isRunning || upnpService == null) {
            callback.onError("DLNA service not running");
            return;
        }
        
        executor.execute(() -> {
            try {
                discoveredDevices.clear();
                for (ServiceType searchType : SEARCH_TYPES) {
                    upnpService.getControlPoint().search(searchType);
                }
                
                Thread.sleep(5000);
                
                List<Device> devices = upnpService.getRegistry().getDevices();
                for (Device device : devices) {
                    if (device.getType().getType().equals("MediaRenderer")) {
                        DlnaDevice dlnaDevice = createDlnaDevice(device);
                        discoveredDevices.add(dlnaDevice);
                        callback.onDeviceFound(dlnaDevice);
                    }
                }
                
                if (discoveredDevices.isEmpty()) {
                    callback.onError("No devices found");
                }
                
            } catch (Exception e) {
                Log.e(TAG, "Search failed", e);
                callback.onError(e.getMessage());
            }
        });
    }
    
    public void castVideo(String deviceUuid, String videoUrl, String title, String poster, CastCallback callback) {
        if (!isRunning || upnpService == null) {
            callback.onError("DLNA service not running");
            return;
        }
        
        executor.execute(() -> {
            try {
                Device device = findDeviceByUuid(deviceUuid);
                if (device == null) {
                    callback.onError("Device not found");
                    return;
                }
                
                org.fourthline.cling.model.meta.Service service = 
                    device.findService(org.fourthline.cling.model.types.ServiceType.AVTransport);
                
                if (service == null) {
                    callback.onError("AVTransport service not found");
                    return;
                }
                
                String metadata = createDidlMetadata(title, poster, videoUrl);
                upnpService.getControlPoint().execute(new SetAVTransportURI(service, 0, videoUrl, metadata) {
                    @Override
                    public void success(ActionInvocation invocation) {
                        Log.d(TAG, "URI set successfully");
                        upnpService.getControlPoint().execute(new Play(service, 0) {
                            @Override
                            public void success(ActionInvocation invocation) {
                                Log.d(TAG, "Playback started");
                                callback.onSuccess();
                            }
                            @Override
                            public void failure(ActionInvocation invocation, UpnpResponse operation, String defaultMsg) {
                                callback.onError("Play failed: " + defaultMsg);
                            }
                        });
                    }
                    @Override
                    public void failure(ActionInvocation invocation, UpnpResponse operation, String defaultMsg) {
                        callback.onError("Set URI failed: " + defaultMsg);
                    }
                });
                
            } catch (Exception e) {
                Log.e(TAG, "Cast failed", e);
                callback.onError(e.getMessage());
            }
        });
    }
    
    public void control(String deviceUuid, String action, ControlCallback callback) {
        executor.execute(() -> {
            try {
                Device device = findDeviceByUuid(deviceUuid);
                if (device == null) {
                    callback.onError("Device not found");
                    return;
                }
                
                org.fourthline.cling.model.meta.Service service = 
                    device.findService(org.fourthline.cling.model.types.ServiceType.AVTransport);
                
                if (service == null) {
                    callback.onError("Service not found");
                    return;
                }
                
                switch (action) {
                    case "play": executePlay(service, callback); break;
                    case "pause": executePause(service, callback); break;
                    case "stop": executeStop(service, callback); break;
                    default: callback.onError("Unknown action: " + action);
                }
                
            } catch (Exception e) {
                Log.e(TAG, "Control failed", e);
                callback.onError(e.getMessage());
            }
        });
    }
    
    private void executePlay(org.fourthline.cling.model.meta.Service service, ControlCallback callback) {
        upnpService.getControlPoint().execute(new Play(service, 0) {
            @Override public void success(ActionInvocation invocation) { callback.onSuccess(); }
            @Override public void failure(ActionInvocation invocation, UpnpResponse operation, String defaultMsg) { 
                callback.onError("Play failed: " + defaultMsg); 
            }
        });
    }
    
    private void executePause(org.fourthline.cling.model.meta.Service service, ControlCallback callback) {
        upnpService.getControlPoint().execute(new Pause(service, 0) {
            @Override public void success(ActionInvocation invocation) { callback.onSuccess(); }
            @Override public void failure(ActionInvocation invocation, UpnpResponse operation, String defaultMsg) { 
                callback.onError("Pause failed: " + defaultMsg); 
            }
        });
    }
    
    private void executeStop(org.fourthline.cling.model.meta.Service service, ControlCallback callback) {
        upnpService.getControlPoint().execute(new Stop(service, 0) {
            @Override public void success(ActionInvocation invocation) { callback.onSuccess(); }
            @Override public void failure(ActionInvocation invocation, UpnpResponse operation, String defaultMsg) { 
                callback.onError("Stop failed: " + defaultMsg); 
            }
        });
    }
    
    private DlnaDevice createDlnaDevice(Device device) {
        String friendlyName = device.getDetails().getFriendlyName();
        String udn = device.getIdentity().getUdn().getIdentifierString();
        String baseUrl = device.getIdentity().getBaseUrl().toString();
        return new DlnaDevice(friendlyName, udn, baseUrl);
    }
    
    private Device findDeviceByUuid(String uuid) {
        List<Device> devices = upnpService.getRegistry().getDevices();
        for (Device device : devices) {
            if (device.getIdentity().getUdn().getIdentifierString().equals(uuid)) {
                return device;
            }
        }
        return null;
    }
    
    private String createDidlMetadata(String title, String poster, String url) {
        StringBuilder sb = new StringBuilder();
        sb.append("<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" ");
        sb.append("xmlns:dc=\"http://purl.org/dc/elements/1.1/\" ");
        sb.append("xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\">");
        sb.append("<item id=\"0\" parentID=\"-1\" restricted=\"1\">");
        sb.append("<dc:title>").append(title).append("</dc:title>");
        sb.append("<res protocolInfo=\"http-get:*:video/mp4:*\">").append(url).append("</res>");
        if (poster != null && !poster.isEmpty()) {
            sb.append("<upnp:albumArtURI>").append(poster).append("</upnp:albumArtURI>");
        }
        sb.append("<upnp:class>object.item.videoItem</upnp:class>");
        sb.append("</item></DIDL-Lite>");
        return sb.toString();
    }
    
    public static String getDeviceIpAddress() {
        try {
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            while (interfaces.hasMoreElements()) {
                NetworkInterface networkInterface = interfaces.nextElement();
                Enumeration<InetAddress> addresses = networkInterface.getInetAddresses();
                while (addresses.hasMoreElements()) {
                    InetAddress address = addresses.nextElement();
                    if (!address.isLoopbackAddress() && !address.isLinkLocalAddress()) {
                        String ip = address.getHostAddress();
                        if (ip != null && ip.contains(".") && !ip.startsWith("fe80")) {
                            return ip;
                        }
                    }
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to get IP address", e);
        }
        return "127.0.0.1";
    }
    
    public interface DlnaDeviceCallback {
        void onDeviceFound(DlnaDevice device);
        void onError(String error);
    }
    
    public static class DlnaDevice {
        public final String name;
        public final String uuid;
        public final String baseUrl;
        
        public DlnaDevice(String name, String uuid, String baseUrl) {
            this.name = name;
            this.uuid = uuid;
            this.baseUrl = baseUrl;
        }
    }
    
    public interface CastCallback {
        void onSuccess();
        void onError(String error);
    }
    
    public interface ControlCallback {
        void onSuccess();
        void onError(String error);
    }
}
