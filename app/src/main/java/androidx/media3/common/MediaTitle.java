package androidx.media3.common;

public class MediaTitle {
    public int index;
    public boolean selected;
    public String label;
    public long durationUs;

    public MediaTitle() {
    }

    public MediaTitle(String label, long durationUs) {
        this.label = label;
        this.durationUs = durationUs;
        this.selected = false;
        this.index = 0;
    }
}