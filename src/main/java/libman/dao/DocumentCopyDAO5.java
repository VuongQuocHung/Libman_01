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

    /** Chỉ số trong mảng kết quả của getCopyStatistics(): tổng số bản đang quản lí (không tính bản đã thanh lí). */
    public static final int TOTAL = 0;

    /** Chỉ số trong mảng kết quả của getCopyStatistics(): số bản có thể cho mượn. */
    public static final int AVAILABLE = 1;

    /**
     * Thống kê các bản của một đầu tài liệu, trả về mảng {tổng số bản, số bản có thể mượn}
     * (đọc bằng các chỉ số TOTAL và AVAILABLE).
     * Bản có thể mượn là bản "Sẵn có" và không hư hỏng.
     */
    public int[] getCopyStatistics(int documentId) throws SQLException {
        Map<Integer, int[]> statistics = getCopyStatistics(List.of(documentId));
        return statistics.get(documentId);
    }

    /**
     * Thống kê cho nhiều đầu tài liệu bằng MỘT câu truy vấn (không gọi CSDL riêng cho từng tài liệu).
     * Kết quả: id tài liệu -> {tổng số bản, số bản có thể mượn}.
     * Tài liệu chưa có bản nào cho kết quả {0, 0}.
     */
    public Map<Integer, int[]> getCopyStatistics(Collection<Integer> documentIds) throws SQLException {
        Map<Integer, int[]> statistics = new HashMap<>();
        if (documentIds.isEmpty()) {
            return statistics;
        }

        // Mặc định {0, 0}: tài liệu chưa có bản nào sẽ không xuất hiện trong kết quả truy vấn
        for (Integer documentId : documentIds) {
            statistics.put(documentId, new int[] {0, 0});
        }

        // Tạo chuỗi "?,?,?" với số dấu ? bằng số tài liệu cần thống kê
        String placeholders = String.join(",", Collections.nCopies(documentIds.size(), "?"));
        String sql = "SELECT documentId, "
                + "COUNT(CASE WHEN usageStatus <> ? THEN 1 END) AS total, "
                + "COUNT(CASE WHEN usageStatus = ? AND copyCondition <> ? THEN 1 END) AS available "
                + "FROM tblDocumentCopy5 "
                + "WHERE documentId IN (" + placeholders + ") "
                + "GROUP BY documentId";

        try (Connection c = DBUtil.getConnection();
            PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, Status5.COPY_DISPOSED);
            ps.setString(2, Status5.COPY_AVAILABLE);
            ps.setString(3, Status5.COND_DAMAGED);

            int parameterIndex = 4;
            for (Integer documentId : documentIds) {
                ps.setInt(parameterIndex, documentId);
                parameterIndex++;
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int documentId = rs.getInt("documentId");
                    int total = rs.getInt("total");
                    int available = rs.getInt("available");
                    statistics.put(documentId, new int[] {total, available});
                }
            }
        }
        return statistics;
    }

    /**
     * Tìm bản tài liệu theo mã bản (quét mã), kèm đầy đủ thông tin đầu tài liệu, trong một truy vấn;
     * null nếu không có.
     * Cột cp.id được đặt bí danh copyId để không trùng với cột d.id của đầu tài liệu.
     */
    public DocumentCopy5 getCopyByCode(String copyCode) throws SQLException {
        String sql = "SELECT cp.id AS copyId, cp.copyCode, cp.location, cp.copyCondition, cp.usageStatus, "
                + DocumentDAO5.DOCUMENT_COLUMNS + " "
                + "FROM tblDocumentCopy5 cp "
                + "JOIN tblDocument5 d ON d.id = cp.documentId "
                + "WHERE cp.copyCode = ?";

        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
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

                // Sau đó đóng gói đầu tài liệu rồi gắn vào bản.
                // Năm xuất bản và số trang có thể để trống trong CSDL (NULL).
                Document5 document = new Document5();
                document.setId(rs.getInt("id"));
                document.setDocumentCode(rs.getString("documentCode"));
                document.setTitle(rs.getString("title"));
                document.setDocumentType(rs.getString("documentType"));
                document.setAuthor(rs.getString("author"));
                document.setPublisher(rs.getString("publisher"));

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
                copy.setDocument(document);
                return copy;
            }
        }
    }
}
