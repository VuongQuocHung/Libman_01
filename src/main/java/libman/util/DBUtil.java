package libman.util;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Kết nối CSDL. Đọc cấu hình từ db.properties (classpath) hoặc từ file chỉ định bằng
 * -Dlibman.config=đường_dẫn (dùng khi kiểm thử).
 */
public final class DBUtil {
    private DBUtil() {}

    private static final Properties PROPS = load();

    private static Properties load() {
        Properties p = new Properties();
        String external = System.getProperty("libman.config");
        try (InputStream in = external != null
                ? new FileInputStream(external)
                : DBUtil.class.getResourceAsStream("/db.properties")) {
            if (in == null) throw new IllegalStateException("Không tìm thấy db.properties");
            try (Reader r = new InputStreamReader(in, StandardCharsets.UTF_8)) {
                p.load(r);
            }
        } catch (IOException e) {
            throw new IllegalStateException("Không đọc được db.properties", e);
        }
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new IllegalStateException("Thiếu MySQL JDBC driver", e);
        }
        return p;
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(
                PROPS.getProperty("db.url"),
                PROPS.getProperty("db.username"),
                PROPS.getProperty("db.password", ""));
    }

    public static boolean isAutoInit() {
        return Boolean.parseBoolean(PROPS.getProperty("db.autoinit", "false"));
    }
}
