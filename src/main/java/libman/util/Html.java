package libman.util;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.time.format.DateTimeFormatter;

/** Hàm trợ giúp cho JSP: escape HTML, định dạng ngày, mã hóa URL. */
public final class Html {
    private Html() {}

    private static final DateTimeFormatter VN = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    /** Escape để chèn an toàn vào nội dung/thuộc tính HTML. */
    public static String esc(Object o) {
        if (o == null) return "";
        String s = o.toString();
        StringBuilder sb = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '&': sb.append("&amp;"); break;
                case '<': sb.append("&lt;"); break;
                case '>': sb.append("&gt;"); break;
                case '"': sb.append("&quot;"); break;
                case '\'': sb.append("&#39;"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }

    /** dd/MM/yyyy */
    public static String date(Date d) {
        return d == null ? "" : d.toLocalDate().format(VN);
    }

    /** yyyy-MM-dd (cho input type="date") */
    public static String iso(Date d) {
        return d == null ? "" : d.toLocalDate().toString();
    }

    public static String url(String s) {
        return s == null ? "" : URLEncoder.encode(s, StandardCharsets.UTF_8);
    }

    public static Date today() {
        return Date.valueOf(java.time.LocalDate.now());
    }
}
