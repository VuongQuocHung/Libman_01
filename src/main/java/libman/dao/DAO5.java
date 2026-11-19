package libman.dao;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Lớp cha của các DAO: giữ kết nối tới CSDL (thuộc tính con).
 * Thông tin kết nối đọc từ file db.properties.
 *
 * Mỗi đối tượng DAO mở một kết nối riêng, nên JSP tạo DAO trong try (...) để kết nối
 * được đóng lại sau khi dùng xong.
 */
public class DAO5 implements AutoCloseable {

    protected Connection con;

    public DAO5() throws SQLException {
        Properties config = new Properties();

        try (InputStream in = DAO5.class.getResourceAsStream("/db.properties")) {
            if (in == null) {
                throw new SQLException("Không tìm thấy file db.properties");
            }
            config.load(new InputStreamReader(in, StandardCharsets.UTF_8));
        } catch (IOException e) {
            throw new SQLException("Không đọc được file db.properties", e);
        }

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("Không tìm thấy driver MySQL", e);
        }

        String url = config.getProperty("db.url");
        String username = config.getProperty("db.username");
        String password = config.getProperty("db.password", "");
        con = DriverManager.getConnection(url, username, password);
    }

    @Override
    public void close() throws SQLException {
        if (con != null) {
            con.close();
        }
    }
}

