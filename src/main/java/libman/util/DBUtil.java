package libman.util;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Cấp kết nối CSDL từ một connection pool (HikariCP): kết nối được mở sẵn và dùng lại,
 * nên close() trong try-with-resources của các DAO chỉ trả kết nối về pool chứ không đóng thật.
 *
 * Cấu hình đọc từ db.properties (classpath) hoặc từ file chỉ định bằng -Dlibman.config=đường_dẫn
 * (dùng khi kiểm thử). Khóa tùy chọn: db.pool.size (mặc định 10), db.pool.timeout.ms (mặc định 5000).
 */
public final class DBUtil {
    private DBUtil() {}

    private static final Properties PROPS = load();
    private static HikariDataSource pool;   // tạo ở lần dùng đầu, truy cập qua pool()

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
        return p;
    }

    private static synchronized HikariDataSource pool() {
        if (pool == null) {
            HikariConfig cfg = new HikariConfig();
            cfg.setPoolName("libman");
            cfg.setDriverClassName("com.mysql.cj.jdbc.Driver");
            cfg.setJdbcUrl(PROPS.getProperty("db.url"));
            cfg.setUsername(PROPS.getProperty("db.username"));
            cfg.setPassword(PROPS.getProperty("db.password", ""));

            int size = Integer.parseInt(PROPS.getProperty("db.pool.size", "10").trim());
            cfg.setMaximumPoolSize(size);
            cfg.setMinimumIdle(Math.min(2, size));
            // Hết thời gian chờ thì ném SQLException để trang báo lỗi cấu hình, thay vì treo 30 giây
            cfg.setConnectionTimeout(Long.parseLong(PROPS.getProperty("db.pool.timeout.ms", "5000").trim()));
            // Sai user/mật khẩu lúc khởi động không được làm hỏng ứng dụng: pool vẫn tạo,
            // lỗi chỉ xuất hiện khi có yêu cầu lấy kết nối (và đăng nhập sẽ báo "không kết nối được CSDL")
            cfg.setInitializationFailTimeout(-1);
            pool = new HikariDataSource(cfg);
        }
        return pool;
    }

    public static Connection getConnection() throws SQLException {
        return pool().getConnection();
    }

    public static boolean isAutoInit() {
        return Boolean.parseBoolean(PROPS.getProperty("db.autoinit", "false"));
    }

    /** Đóng pool khi ứng dụng dừng (được gọi từ DatabaseInitializer). */
    public static synchronized void shutdown() {
        if (pool != null) {
            pool.close();
            pool = null;
        }
    }
}
