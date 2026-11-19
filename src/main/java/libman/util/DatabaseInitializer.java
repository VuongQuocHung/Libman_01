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
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

/**
 * Khi ứng dụng khởi động: nếu db.autoinit=true và chưa có bảng tblMember5
 * thì chạy sql/schema.sql rồi sql/data.sql. Lỗi kết nối chỉ được ghi log,
 * ứng dụng vẫn chạy (trang đăng nhập sẽ báo lỗi cấu hình).
 */
@WebListener
public class DatabaseInitializer implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        if (!DBUtil.isAutoInit()) return;
        try (Connection c = DBUtil.getConnection()) {
            if (tableExists(c, "tblMember5")) {
                sce.getServletContext().log("LibMan: CSDL đã có bảng, bỏ qua khởi tạo.");
                return;
            }
            sce.getServletContext().log("LibMan: đang tạo schema và nạp dữ liệu mẫu...");
            runScript(c, "/sql/schema.sql");
            runScript(c, "/sql/data.sql");
            sce.getServletContext().log("LibMan: khởi tạo CSDL xong.");
        } catch (Exception e) {
            sce.getServletContext().log("LibMan: KHÔNG khởi tạo được CSDL - kiểm tra db.properties. " + e, e);
        }
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        DBUtil.shutdown();   // đóng connection pool trước, tránh rò rỉ luồng khi redeploy
        // Gỡ JDBC driver của ứng dụng để Tomcat không báo rò rỉ bộ nhớ khi undeploy
        ClassLoader cl = getClass().getClassLoader();
        Enumeration<Driver> drivers = DriverManager.getDrivers();
        while (drivers.hasMoreElements()) {
            Driver d = drivers.nextElement();
            if (d.getClass().getClassLoader() == cl) {
                try { DriverManager.deregisterDriver(d); } catch (SQLException ignored) { }
            }
        }
    }

    private static boolean tableExists(Connection c, String table) throws SQLException {
        String sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, table);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    /** Mỗi lệnh kết thúc bằng ';' ở cuối dòng; bỏ qua dòng chú thích '--'. */
    private static void runScript(Connection c, String resource) throws IOException, SQLException {
        try (InputStream in = DatabaseInitializer.class.getResourceAsStream(resource)) {
            if (in == null) throw new IOException("Không thấy " + resource);
            BufferedReader br = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8));
            StringBuilder stmt = new StringBuilder();
            String line;
            try (Statement st = c.createStatement()) {
                while ((line = br.readLine()) != null) {
                    String t = line.trim();
                    if (t.isEmpty() || t.startsWith("--")) continue;
                    stmt.append(line).append('\n');
                    if (t.endsWith(";")) {
                        String sql = stmt.toString().trim();
                        st.execute(sql.substring(0, sql.length() - 1));
                        stmt.setLength(0);
                    }
                }
            }
        }
    }
}
