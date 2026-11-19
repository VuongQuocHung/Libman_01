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

    /** Các cột của tblDocument5 (bí danh d), dùng chung với DocumentCopyDAO5 khi JOIN. */
    static final String DOCUMENT_COLUMNS = "d.id, d.documentCode, d.title, d.documentType, "
            + "d.author, d.publisher, d.`year`, d.description, "
            + "d.language, d.pageCount, d.documentStatus";

    private static final String SELECT = "SELECT " + DOCUMENT_COLUMNS + " FROM tblDocument5 d ";

    /** Số tài liệu mỗi trang kết quả tìm kiếm. */
    public static final int PAGE_SIZE = 10;

    /** Đếm các đầu tài liệu đang sử dụng có tên chứa từ khóa (để tính số trang). */
    public int countDocumentByTitle(String keyword) throws SQLException {
        String sql = "SELECT COUNT(*) "
                + "FROM tblDocument5 "
                + "WHERE documentStatus = ? AND title LIKE ?";

        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, Status5.DOC_ACTIVE);
            ps.setString(2, "%" + escapeLike(keyword) + "%");

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    /**
     * Tìm các đầu tài liệu đang sử dụng có tên chứa từ khóa, lấy một trang kết quả.
     * (Collation utf8mb4_0900_ai_ci nên không phân biệt hoa/thường và dấu tiếng Việt.)
     *
     * @param page     số trang, đếm từ 1
     * @param pageSize số tài liệu mỗi trang
     */
    public List<Document5> getDocumentByTitle(String keyword, int page, int pageSize) throws SQLException {
        String sql = SELECT
                + "WHERE documentStatus = ? AND title LIKE ? "
                + "ORDER BY title, documentCode "
                + "LIMIT ? OFFSET ?";
        int offset = (Math.max(page, 1) - 1) * pageSize;

        List<Document5> documents = new ArrayList<>();
        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, Status5.DOC_ACTIVE);
            ps.setString(2, "%" + escapeLike(keyword) + "%");
            ps.setInt(3, pageSize);
            ps.setInt(4, offset);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    documents.add(map(rs));
                }
            }
        }
        return documents;
    }

    /** Lấy đầu tài liệu theo mã (kể cả đã ngừng sử dụng); null nếu không có. */
    public Document5 getDocumentByCode(String documentCode) throws SQLException {
        String sql = SELECT + "WHERE documentCode = ?";

        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, documentCode);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return map(rs);
                }
                return null;
            }
        }
    }

    /** Thêm dấu \ trước các ký tự đặc biệt của LIKE (\, %, _) để chúng được hiểu là ký tự thường. */
    private static String escapeLike(String text) {
        String escaped = text.replace("\\", "\\\\");
        escaped = escaped.replace("%", "\\%");
        escaped = escaped.replace("_", "\\_");
        return escaped;
    }

    /** Đóng gói Document5 từ các cột DOCUMENT_COLUMNS. */
    private static Document5 map(ResultSet rs) throws SQLException {
        Document5 document = new Document5();
        document.setId(rs.getInt("id"));
        document.setDocumentCode(rs.getString("documentCode"));
        document.setTitle(rs.getString("title"));
        document.setDocumentType(rs.getString("documentType"));
        document.setAuthor(rs.getString("author"));
        document.setPublisher(rs.getString("publisher"));

        // Năm xuất bản và số trang có thể để trống trong CSDL (NULL)
        int year = rs.getInt("year");
        if (rs.wasNull()) {
            document.setYear(null);
        } else {
            document.setYear(year);
        }

        document.setDescription(rs.getString("description"));
        document.setLanguage(rs.getString("language"));

        int pageCount = rs.getInt("pageCount");
        if (rs.wasNull()) {
            document.setPageCount(null);
        } else {
            document.setPageCount(pageCount);
        }

        document.setDocumentStatus(rs.getString("documentStatus"));
        return document;
    }
}
