package libman.util;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Enumeration;
import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

/**
 * Khi ứng dụng khởi động: nếu db.autoinit=true và chưa có bảng tblMember5
 * thì chạy sql/schema.sql rồi sql/data.sql.
 *
 * Lỗi kết nối chỉ được ghi log, ứng dụng vẫn chạy
 * (trang đăng nhập sẽ báo lỗi cấu hình).
 */
@WebListener
public class DatabaseInitializer implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent event) {
        ServletContext context = event.getServletContext();

        if (!DBUtil.isAutoInit()) {
            return;
        }

        try (Connection c = DBUtil.getConnection()) {
            if (tableExists(c, "tblMember5")) {
                context.log("LibMan: CSDL đã có bảng, bỏ qua khởi tạo.");
                return;
            }

            context.log("LibMan: đang tạo schema và nạp dữ liệu mẫu...");
            runScript(c, "/sql/schema.sql");
            runScript(c, "/sql/data.sql");
            context.log("LibMan: khởi tạo CSDL xong.");
        } catch (Exception e) {
            context.log("LibMan: KHÔNG khởi tạo được CSDL - kiểm tra db.properties. " + e, e);
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        // Đóng connection pool trước, tránh rò rỉ luồng khi triển khai lại
        DBUtil.shutdown();

        // Gỡ JDBC driver của ứng dụng để Tomcat không báo rò rỉ bộ nhớ khi gỡ ứng dụng
        ClassLoader appClassLoader = getClass().getClassLoader();
        Enumeration<Driver> drivers = DriverManager.getDrivers();

        while (drivers.hasMoreElements()) {
            Driver driver = drivers.nextElement();
            if (driver.getClass().getClassLoader() == appClassLoader) {
                deregister(driver);
            }
        }
    }

    private static void deregister(Driver driver) {
        try {
            DriverManager.deregisterDriver(driver);
        } catch (SQLException ignored) {
            // Không làm được thì bỏ qua, ứng dụng đang dừng rồi
        }
    }

    private static boolean tableExists(Connection c, String tableName) throws SQLException {
        String sql = "SELECT COUNT(*) "
                + "FROM information_schema.tables "
                + "WHERE table_schema = DATABASE() AND table_name = ?";

        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, tableName);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                return rs.getInt(1) > 0;
            }
        }
    }

    /**
     * Chạy file script SQL trong thư mục resources.
     * Quy ước: mỗi lệnh kết thúc bằng dấu ; ở cuối dòng, dòng bắt đầu bằng -- là chú thích.
     */
    private static void runScript(Connection c, String resourcePath) throws IOException, SQLException {
        try (InputStream in = DatabaseInitializer.class.getResourceAsStream(resourcePath)) {
            if (in == null) {
                throw new IOException("Không thấy " + resourcePath);
            }

            BufferedReader reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8));
            try (Statement statement = c.createStatement()) {
                executeStatements(statement, reader);
            }
        }
    }

    /** Gom các dòng thành từng câu lệnh (kết thúc bằng dấu ;) rồi chạy lần lượt. */
    private static void executeStatements(Statement statement, BufferedReader reader)
            throws IOException, SQLException {
        StringBuilder currentStatement = new StringBuilder();

        String line = reader.readLine();
        while (line != null) {
            String trimmedLine = line.trim();
            boolean isBlankOrComment = trimmedLine.isEmpty() || trimmedLine.startsWith("--");

            if (!isBlankOrComment) {
                currentStatement.append(line).append('\n');

                if (trimmedLine.endsWith(";")) {
                    String sql = currentStatement.toString().trim();
                    String sqlWithoutSemicolon = sql.substring(0, sql.length() - 1);
                    statement.execute(sqlWithoutSemicolon);
                    currentStatement.setLength(0);
                }
            }

            line = reader.readLine();
        }
    }
}
