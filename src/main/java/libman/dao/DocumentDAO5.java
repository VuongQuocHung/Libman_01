package libman.dao;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import libman.model.Document5;

public class DocumentDAO5 extends DAO5 {

    public DocumentDAO5() throws SQLException {
        super();
    }

    /**
     * Tìm các đầu tài liệu đang sử dụng có tên chứa từ khóa.
     * (Collation utf8mb4_0900_ai_ci nên không phân biệt hoa/thường và dấu tiếng Việt.)
     */
    public List<Document5> getDocumentByTitle(String keyword) throws SQLException {
        String sql = "SELECT * FROM tblDocument5 "
                + "WHERE documentStatus = 'Đang sử dụng' AND title LIKE ? "
                + "ORDER BY title, documentCode";

        List<Document5> documents = new ArrayList<>();
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, "%" + keyword + "%");

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Document5 document = new Document5();
                    document.setId(rs.getInt("id"));
                    document.setDocumentCode(rs.getString("documentCode"));
                    document.setTitle(rs.getString("title"));
                    document.setDocumentType(rs.getString("documentType"));
                    document.setAuthor(rs.getString("author"));
                    document.setPublisher(rs.getString("publisher"));
                    document.setYear(rs.getObject("year", Integer.class));
                    document.setDescription(rs.getString("description"));
                    document.setLanguage(rs.getString("language"));
                    document.setPageCount(rs.getObject("pageCount", Integer.class));
                    document.setDocumentStatus(rs.getString("documentStatus"));
                    documents.add(document);
                }
            }
        }
        return documents;
    }

    /** Lấy đầu tài liệu theo mã tài liệu; null nếu không có. */
    public Document5 getDocumentByCode(String documentCode) throws SQLException {
        String sql = "SELECT * FROM tblDocument5 WHERE documentCode = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, documentCode);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                Document5 document = new Document5();
                document.setId(rs.getInt("id"));
                document.setDocumentCode(rs.getString("documentCode"));
                document.setTitle(rs.getString("title"));
                document.setDocumentType(rs.getString("documentType"));
                document.setAuthor(rs.getString("author"));
                document.setPublisher(rs.getString("publisher"));
                document.setYear(rs.getObject("year", Integer.class));
                document.setDescription(rs.getString("description"));
                document.setLanguage(rs.getString("language"));
                document.setPageCount(rs.getObject("pageCount", Integer.class));
                document.setDocumentStatus(rs.getString("documentStatus"));
                return document;
            }
        }
    }
}
