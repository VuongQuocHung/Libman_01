package libman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import libman.model.Document5;
import libman.model.Status5;
import libman.util.DBUtil;

public class DocumentDAO5 {

    private static final String SELECT =
            "SELECT id, documentCode, title, documentType, author, publisher, `year`, description, "
            + "language, pageCount, documentStatus FROM tblDocument5 ";

    /**
     * Tìm các đầu tài liệu đang sử dụng có tên chứa từ khóa.
     * (Collation utf8mb4_0900_ai_ci nên không phân biệt hoa/thường và dấu tiếng Việt.)
     */
    public List<Document5> getDocumentByTitle(String keyword) throws SQLException {
        String sql = SELECT + "WHERE documentStatus = ? AND title LIKE ? ORDER BY title, documentCode";
        List<Document5> list = new ArrayList<>();
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, Status5.DOC_ACTIVE);
            ps.setString(2, "%" + escapeLike(keyword) + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        }
        return list;
    }

    /** Lấy đầu tài liệu theo mã (kể cả đã ngừng sử dụng); null nếu không có. */
    public Document5 getDocumentByCode(String documentCode) throws SQLException {
        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(SELECT + "WHERE documentCode = ?")) {
            ps.setString(1, documentCode);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    private static String escapeLike(String s) {
        return s.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
    }

    private static Document5 map(ResultSet rs) throws SQLException {
        Document5 d = new Document5();
        d.setId(rs.getInt("id"));
        d.setDocumentCode(rs.getString("documentCode"));
        d.setTitle(rs.getString("title"));
        d.setDocumentType(rs.getString("documentType"));
        d.setAuthor(rs.getString("author"));
        d.setPublisher(rs.getString("publisher"));
        int year = rs.getInt("year");
        d.setYear(rs.wasNull() ? null : year);
        d.setDescription(rs.getString("description"));
        d.setLanguage(rs.getString("language"));
        int pages = rs.getInt("pageCount");
        d.setPageCount(rs.wasNull() ? null : pages);
        d.setDocumentStatus(rs.getString("documentStatus"));
        return d;
    }
}
