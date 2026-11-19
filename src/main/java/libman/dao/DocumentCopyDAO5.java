package libman.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import libman.model.Document5;
import libman.model.DocumentCopy5;
import libman.model.Status5;
import libman.util.DBUtil;

public class DocumentCopyDAO5 {

    /** Chỉ số trong mảng kết quả của getCopyStatistics(). */
    public static final int TOTAL = 0;       // tổng số bản đang quản lí (không tính bản đã thanh lí)
    public static final int AVAILABLE = 1;   // số bản có thể cho mượn

    /**
     * Thống kê các bản của một đầu tài liệu, trả về mảng {tổng số bản, số bản có thể mượn}
     * (đọc bằng các chỉ số TOTAL và AVAILABLE). Bản có thể mượn là bản "Sẵn có" và không hư hỏng.
     */
    public int[] getCopyStatistics(int documentId) throws SQLException {
        return getCopyStatistics(List.of(documentId)).get(documentId);
    }

    /**
     * Thống kê cho nhiều đầu tài liệu bằng MỘT câu truy vấn (tránh gọi CSDL riêng cho từng tài liệu).
     * Kết quả: id tài liệu -> {tổng số bản, số bản có thể mượn}. Tài liệu chưa có bản nào cho {0, 0}.
     */
    public Map<Integer, int[]> getCopyStatistics(Collection<Integer> documentIds) throws SQLException {
        Map<Integer, int[]> result = new HashMap<>();
        if (documentIds.isEmpty()) return result;
        for (Integer id : documentIds) result.put(id, new int[] { 0, 0 });

        String marks = String.join(",", Collections.nCopies(documentIds.size(), "?"));
        String sql = "SELECT documentId, "
                + "COUNT(CASE WHEN usageStatus <> ? THEN 1 END) AS total, "
                + "COUNT(CASE WHEN usageStatus = ? AND copyCondition <> ? THEN 1 END) AS available "
                + "FROM tblDocumentCopy5 WHERE documentId IN (" + marks + ") GROUP BY documentId";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, Status5.COPY_DISPOSED);
            ps.setString(2, Status5.COPY_AVAILABLE);
            ps.setString(3, Status5.COND_DAMAGED);
            int idx = 4;
            for (Integer id : documentIds) ps.setInt(idx++, id);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.put(rs.getInt("documentId"), new int[] { rs.getInt("total"), rs.getInt("available") });
                }
            }
        }
        return result;
    }

    /**
     * Tìm bản tài liệu theo mã bản (quét mã), kèm đầy đủ thông tin đầu tài liệu, trong một truy vấn;
     * null nếu không có. cp.id đặt bí danh copyId để không trùng với cột d.id của đầu tài liệu.
     */
    public DocumentCopy5 getCopyByCode(String copyCode) throws SQLException {
        String sql = "SELECT cp.id AS copyId, cp.copyCode, cp.location, cp.copyCondition, cp.usageStatus, "
                + DocumentDAO5.DOCUMENT_COLUMNS + " "
                + "FROM tblDocumentCopy5 cp JOIN tblDocument5 d ON d.id = cp.documentId WHERE cp.copyCode = ?";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, copyCode);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                // Đóng gói bản tài liệu trước, sau đó đóng gói đầu tài liệu rồi gắn vào bản
                DocumentCopy5 cp = new DocumentCopy5();
                cp.setId(rs.getInt("copyId"));
                cp.setCopyCode(rs.getString("copyCode"));
                cp.setLocation(rs.getString("location"));
                cp.setCopyCondition(rs.getString("copyCondition"));
                cp.setUsageStatus(rs.getString("usageStatus"));

                Document5 document = DocumentDAO5.map(rs);
                cp.setDocument(document);
                return cp;
            }
        }
    }
}
