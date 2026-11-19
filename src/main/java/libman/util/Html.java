package libman.util;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/** Hàm trợ giúp cho JSP: escape HTML, định dạng ngày, mã hóa URL. */
public final class Html {

    private Html() {
    }

    private static final DateTimeFormatter VIETNAM_DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    /** Escape để chèn an toàn vào nội dung hoặc thuộc tính HTML. */
    public static String esc(Object value) {
        if (value == null) {
            return "";
        }

        String text = value.toString();
        StringBuilder result = new StringBuilder(text.length() + 16);

        for (int i = 0; i < text.length(); i++) {
            char ch = text.charAt(i);
            switch (ch) {
                case '&':
                    result.append("&amp;");
                    break;
                case '<':
                    result.append("&lt;");
                    break;
                case '>':
                    result.append("&gt;");
                    break;
                case '"':
                    result.append("&quot;");
                    break;
                case '\'':
                    result.append("&#39;");
                    break;
                default:
                    result.append(ch);
                    break;
            }
        }
        return result.toString();
    }

    /** Định dạng dd/MM/yyyy; chuỗi rỗng nếu ngày là null. */
    public static String date(Date date) {
        if (date == null) {
            return "";
        }
        return date.toLocalDate().format(VIETNAM_DATE);
    }

    /** Định dạng yyyy-MM-dd (dùng cho input type="date"); chuỗi rỗng nếu ngày là null. */
    public static String iso(Date date) {
        if (date == null) {
            return "";
        }
        return date.toLocalDate().toString();
    }

    /** Mã hóa để đưa vào tham số trên URL; chuỗi rỗng nếu text là null. */
    public static String url(String text) {
        if (text == null) {
            return "";
        }
        return URLEncoder.encode(text, StandardCharsets.UTF_8);
    }

    /** Ngày hôm nay. */
    public static Date today() {
        return Date.valueOf(LocalDate.now());
    }
}
