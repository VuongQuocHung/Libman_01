package libman.util;

import javax.servlet.http.HttpSession;

/** Thông báo một lần, sống qua một lần redirect (Post-Redirect-Get). */
public final class Flash {
    private Flash() {
    }

    private static final String KEY = "libman.flash";

    public static void error(HttpSession s, String msg) {
        s.setAttribute(KEY, new String[]{"error", msg});
    }

    public static void success(HttpSession s, String msg) {
        s.setAttribute(KEY, new String[]{"success", msg});
    }

    public static void info(HttpSession s, String msg) {
        s.setAttribute(KEY, new String[]{"info", msg});
    }

    /** Lấy và xóa thông báo; trả về {loại, nội dung} hoặc null. */
    public static String[] take(HttpSession s) {
        String[] flash = (String[]) s.getAttribute(KEY);
        if (flash != null) {
            s.removeAttribute(KEY);
        }
        return flash;
    }
}
