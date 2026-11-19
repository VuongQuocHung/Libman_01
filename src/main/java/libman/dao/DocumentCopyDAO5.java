package libman.dao;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Document5;
import libman.model.DocumentCopy5;

public class DocumentCopyDAO5 extends DAO5 {

    public DocumentCopyDAO5() throws SQLException {
        super();
    }

    /**
     * Thống kê các bản của một đầu tài liệu.
     * Trả về mảng {tổng số bản, số bản có thể mượn}:
     * - tổng số bản: không tính bản đã thanh lí;
     * - số bản có thể mượn: bản "Sẵn có" và không hư hỏng.
     */
    public int[] getCopyStatistics(int documentId) throws SQLException {
        String sql = "SELECT "
                + "COUNT(CASE WHEN usageStatus <> 'Thanh lí' THEN 1 END) AS total, "
                + "COUNT(CASE WHEN usageStatus = 'Sẵn có' AND copyCondition <> 'Hư hỏng' THEN 1 END) AS available "
                + "FROM tblDocumentCopy5 "
                + "WHERE documentId = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, documentId);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                int total = rs.getInt("total");
                int available = rs.getInt("available");
                return new int[] {total, available};
            }
        }
    }

    /**
     * Tìm bản tài liệu theo mã bản (quét mã), kèm thông tin đầu tài liệu; null nếu không có.
     * Cột cp.id đặt bí danh copyId để không trùng với cột d.id của đầu tài liệu.
     */
    public DocumentCopy5 getCopyByCode(String copyCode) throws SQLException {
        String sql = "SELECT cp.id AS copyId, cp.copyCode, cp.location, cp.copyCondition, cp.usageStatus, d.* "
                + "FROM tblDocumentCopy5 cp "
                + "JOIN tblDocument5 d ON d.id = cp.documentId "
                + "WHERE cp.copyCode = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, copyCode);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                // Đóng gói bản tài liệu trước
                DocumentCopy5 copy = new DocumentCopy5();
                copy.setId(rs.getInt("copyId"));
                copy.setCopyCode(rs.getString("copyCode"));
                copy.setLocation(rs.getString("location"));
                copy.setCopyCondition(rs.getString("copyCondition"));
                copy.setUsageStatus(rs.getString("usageStatus"));

                // Sau đó đóng gói đầu tài liệu rồi gắn vào bản
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

                copy.setDocument(document);
                return copy;
            }
        }
    }
}
