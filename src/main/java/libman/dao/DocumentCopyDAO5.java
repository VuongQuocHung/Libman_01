package libman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.CopyStatistics5;
import libman.model.Document5;
import libman.model.DocumentCopy5;
import libman.model.Status5;
import libman.util.DBUtil;

public class DocumentCopyDAO5 {

    /**
     * Thống kê các bản của một đầu tài liệu:
     * tổng số bản đang quản lí (không tính bản đã thanh lí) và số bản có thể cho mượn
     * (trạng thái "Sẵn có" và không hư hỏng).
     */
    public CopyStatistics5 getCopyStatistics(int documentId) throws SQLException {
        String sql = "SELECT "
                + "COUNT(CASE WHEN usageStatus <> ? THEN 1 END) AS total, "
                + "COUNT(CASE WHEN usageStatus = ? AND copyCondition <> ? THEN 1 END) AS available "
                + "FROM tblDocumentCopy5 WHERE documentId = ?";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, Status5.COPY_DISPOSED);
            ps.setString(2, Status5.COPY_AVAILABLE);
            ps.setString(3, Status5.COND_DAMAGED);
            ps.setInt(4, documentId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return new CopyStatistics5(rs.getInt("total"), rs.getInt("available"));
            }
        }
    }

    /** Tìm bản tài liệu theo mã bản (quét mã); Document5 bên trong chỉ có id và mã đầu tài liệu. */
    public DocumentCopy5 getCopyByCode(String copyCode) throws SQLException {
        String sql = "SELECT cp.id, cp.copyCode, cp.location, cp.copyCondition, cp.usageStatus, "
                + "d.id AS documentId, d.documentCode "
                + "FROM tblDocumentCopy5 cp JOIN tblDocument5 d ON d.id = cp.documentId WHERE cp.copyCode = ?";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, copyCode);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                DocumentCopy5 cp = new DocumentCopy5();
                cp.setId(rs.getInt("id"));
                cp.setCopyCode(rs.getString("copyCode"));
                cp.setLocation(rs.getString("location"));
                cp.setCopyCondition(rs.getString("copyCondition"));
                cp.setUsageStatus(rs.getString("usageStatus"));
                Document5 d = new Document5();
                d.setId(rs.getInt("documentId"));
                d.setDocumentCode(rs.getString("documentCode"));
                cp.setDocument(d);
                return cp;
            }
        }
    }
}
