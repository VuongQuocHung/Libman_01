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
 * Cấu hình đọc từ db.properties (trong classpath) hoặc từ file chỉ định bằng
 * -Dlibman.config=đường_dẫn (dùng khi kiểm thử).
 * Khóa tùy chọn: db.pool.size (mặc định 10), db.pool.timeout.ms (mặc định 5000).
 */
public final class DBUtil {

    private DBUtil() {
    }

    private static final Properties PROPS = loadProperties();

    /** Pool kết nối, tạo ở lần dùng đầu tiên (truy cập qua hàm pool()). */
    private static HikariDataSource pool;

    private static Properties loadProperties() {
        Properties properties = new Properties();
        String externalConfigPath = System.getProperty("libman.config");

        try (InputStream in = openConfigStream(externalConfigPath)) {
            if (in == null) {
                throw new IllegalStateException("Không tìm thấy db.properties");
            }
            try (Reader reader = new InputStreamReader(in, StandardCharsets.UTF_8)) {
                properties.load(reader);
            }
        } catch (IOException e) {
            throw new IllegalStateException("Không đọc được db.properties", e);
        }
        return properties;
    }

    /** Mở file cấu hình chỉ định (nếu có), nếu không thì dùng db.properties trong classpath. */
    private static InputStream openConfigStream(String externalConfigPath) throws IOException {
        if (externalConfigPath != null) {
            return new FileInputStream(externalConfigPath);
        }
        return DBUtil.class.getResourceAsStream("/db.properties");
    }

    private static synchronized HikariDataSource pool() {
        if (pool == null) {
            pool = createPool();
        }
        return pool;
    }

    private static HikariDataSource createPool() {
        HikariConfig config = new HikariConfig();
        config.setPoolName("libman");
        config.setDriverClassName("com.mysql.cj.jdbc.Driver");
        config.setJdbcUrl(PROPS.getProperty("db.url"));
        config.setUsername(PROPS.getProperty("db.username"));
        config.setPassword(PROPS.getProperty("db.password", ""));

        int poolSize = Integer.parseInt(PROPS.getProperty("db.pool.size", "10").trim());
        config.setMaximumPoolSize(poolSize);
        config.setMinimumIdle(Math.min(2, poolSize));

        // Hết thời gian chờ thì ném SQLException để trang báo lỗi, thay vì treo 30 giây
        long timeoutMillis = Long.parseLong(PROPS.getProperty("db.pool.timeout.ms", "5000").trim());
        config.setConnectionTimeout(timeoutMillis);

        // Sai tên đăng nhập hoặc mật khẩu lúc khởi động không được làm hỏng ứng dụng:
        // pool vẫn được tạo, lỗi chỉ xuất hiện khi có yêu cầu lấy kết nối
        // (và trang đăng nhập sẽ báo "không kết nối được cơ sở dữ liệu").
        config.setInitializationFailTimeout(-1);

        return new HikariDataSource(config);
    }

    public static Connection getConnection() throws SQLException {
        return pool().getConnection();
    }

    public static boolean isAutoInit() {
        String value = PROPS.getProperty("db.autoinit", "false");
        return Boolean.parseBoolean(value);
    }

    /** Đóng pool khi ứng dụng dừng (được gọi từ DatabaseInitializer). */
    public static synchronized void shutdown() {
        if (pool != null) {
            pool.close();
            pool = null;
        }
    }
}
