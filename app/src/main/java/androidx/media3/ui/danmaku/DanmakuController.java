package androidx.media3.ui.danmaku;

import android.net.Uri;
import android.view.View;

import androidx.annotation.Nullable;
import androidx.media3.common.util.UnstableApi;

import okhttp3.OkHttpClient;

@UnstableApi
public class DanmakuController {
    public interface Listener {
        void onDanmakuClicked(float x, float y);
        void onDanmakuAppeared(String text, float x, float y);
        void onDanmakuOutside(String text);
    }

    private Listener listener;
    private boolean enabled = true;
    private OkHttpClient httpClient;

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void setOkHttpClient(OkHttpClient client) {
        this.httpClient = client;
    }

    public OkHttpClient getOkHttpClient() {
        return httpClient;
    }

    public void setDataSource(Uri uri) {
    }

    public void clearItems() {
    }

    public void onAttachedToWindow(View view) {
    }

    public void onDetachedFromWindow(View view) {
    }

    public void onVisibilityChanged(int visibility) {
    }

    public void release() {
    }
}