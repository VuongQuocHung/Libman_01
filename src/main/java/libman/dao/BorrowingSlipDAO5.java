package libman.dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import libman.model.BorrowingDetail5;
import libman.model.BorrowingSlip5;
import libman.model.Document5;
import libman.model.DocumentCopy5;
import libman.model.Librarian5;
import libman.model.Reader5;
import libman.model.Status5;
import libman.util.DBUtil;
import libman.util.Html;

public class BorrowingSlipDAO5 {

    /**
     * Lưu phiếu mượn + các chi tiết và chuyển các bản sang "Đang được mượn" trong MỘT giao dịch.
     * Kiểm tra lại toàn bộ điều kiện tại thời điểm lưu; nếu có lỗi thì rollback, không để lại giao dịch dở dang.
     *
     * @return phiếu đã lưu (có id và mã phiếu)
     * @throws BorrowException lỗi nghiệp vụ (độc giả/thẻ không hợp lệ, bản đã bị mượn...)
     */
    public BorrowingSlip5 saveBorrowingSlip(BorrowingSlip5 slip) throws BorrowException, SQLException {
        if (slip.getReader() == null) throw new BorrowException("Chưa xác định độc giả.");
        if (slip.getLibrarian() == null) throw new BorrowException("Không xác định được nhân viên thực hiện.");
        if (slip.getDetails() == null || slip.getDetails().isEmpty())
            throw new BorrowException("Danh sách mượn đang trống. Hãy thêm ít nhất một bản tài liệu.");
        Date today = Html.today();
        if (slip.getDueDate() == null || !slip.getDueDate().after(slip.getBorrowDate()))
            throw new BorrowException("Hạn trả phải sau ngày mượn.");

        try (Connection c = DBUtil.getConnection()) {
            c.setAutoCommit(false);
            try {
                checkReaderEligible(c, slip.getReader().getId(), today);

                // Khóa các bản theo thứ tự id để tránh deadlock khi hai nhân viên cùng thao tác
                List<BorrowingDetail5> sorted = new ArrayList<>(slip.getDetails());
                sorted.sort(Comparator.comparing(d -> d.getDocumentCopy().getId()));
                Set<Integer> seen = new HashSet<>();
                for (BorrowingDetail5 d : sorted) {
                    DocumentCopy5 cp = d.getDocumentCopy();
                    if (!seen.add(cp.getId()))
                        throw new BorrowException("Bản " + cp.getCopyCode() + " bị thêm trùng trong phiếu.");
                    lockAndCheckCopy(c, cp);
                }

                int slipId = insertSlip(c, slip);
                String code = String.format("PM%03d", slipId);
                try (PreparedStatement ps = c.prepareStatement("UPDATE tblBorrowingSlip5 SET borrowCode = ? WHERE id = ?")) {
                    ps.setString(1, code);
                    ps.setInt(2, slipId);
                    ps.executeUpdate();
                }
                slip.setId(slipId);
                slip.setBorrowCode(code);

                try (PreparedStatement insDetail = c.prepareStatement(
                        "INSERT INTO tblBorrowingDetail5 (conditionOnBorrowing, borrowingSlipId, documentCopyId) VALUES (?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS);
                     PreparedStatement updCopy = c.prepareStatement(
                        "UPDATE tblDocumentCopy5 SET usageStatus = ? WHERE id = ? AND usageStatus = ?")) {
                    for (BorrowingDetail5 d : slip.getDetails()) {
                        insDetail.setString(1, d.getConditionOnBorrowing());
                        insDetail.setInt(2, slipId);
                        insDetail.setInt(3, d.getDocumentCopy().getId());
                        insDetail.executeUpdate();
                        try (ResultSet keys = insDetail.getGeneratedKeys()) {
                            if (keys.next()) d.setId(keys.getInt(1));
                        }
                        updCopy.setString(1, Status5.COPY_BORROWED);
                        updCopy.setInt(2, d.getDocumentCopy().getId());
                        updCopy.setString(3, Status5.COPY_AVAILABLE);
                        if (updCopy.executeUpdate() != 1)
                            throw new BorrowException("Bản " + d.getDocumentCopy().getCopyCode() + " vừa được người khác mượn.");
                        d.getDocumentCopy().setUsageStatus(Status5.COPY_BORROWED);
                    }
                }
                c.commit();
                return slip;
            } catch (BorrowException | SQLException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        }
    }

    /** Đọc lại phiếu mượn đã lưu để hiển thị/in (kèm độc giả, nhân viên, các bản và tên tài liệu). */
    public BorrowingSlip5 getBorrowingSlipById(int id) throws SQLException {
        String sql = "SELECT s.id, s.borrowCode, s.borrowDate, s.dueDate, "
                + "rm.fullName AS readerName, r.readerCode, lm.fullName AS librarianName, st.staffCode "
                + "FROM tblBorrowingSlip5 s "
                + "JOIN tblReader5 r ON r.id = s.readerId JOIN tblMember5 rm ON rm.id = r.id "
                + "JOIN tblLibrarian5 l ON l.id = s.librarianId JOIN tblStaff5 st ON st.id = l.id "
                + "JOIN tblMember5 lm ON lm.id = l.id WHERE s.id = ?";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            BorrowingSlip5 slip;
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                slip = new BorrowingSlip5();
                slip.setId(rs.getInt("id"));
                slip.setBorrowCode(rs.getString("borrowCode"));
                slip.setBorrowDate(rs.getDate("borrowDate"));
                slip.setDueDate(rs.getDate("dueDate"));
                Reader5 reader = new Reader5();
                reader.setFullName(rs.getString("readerName"));
                reader.setReaderCode(rs.getString("readerCode"));
                slip.setReader(reader);
                Librarian5 lib = new Librarian5();
                lib.setFullName(rs.getString("librarianName"));
                lib.setStaffCode(rs.getString("staffCode"));
                slip.setLibrarian(lib);
            }
            String dsql = "SELECT bd.id, bd.conditionOnBorrowing, cp.id AS copyId, cp.copyCode, cp.usageStatus, "
                    + "d.documentCode, d.title "
                    + "FROM tblBorrowingDetail5 bd JOIN tblDocumentCopy5 cp ON cp.id = bd.documentCopyId "
                    + "JOIN tblDocument5 d ON d.id = cp.documentId WHERE bd.borrowingSlipId = ? ORDER BY bd.id";
            try (PreparedStatement dps = c.prepareStatement(dsql)) {
                dps.setInt(1, id);
                try (ResultSet rs = dps.executeQuery()) {
                    while (rs.next()) {
                        DocumentCopy5 cp = new DocumentCopy5();
                        cp.setId(rs.getInt("copyId"));
                        cp.setCopyCode(rs.getString("copyCode"));
                        cp.setUsageStatus(rs.getString("usageStatus"));
                        Document5 doc = new Document5();
                        doc.setDocumentCode(rs.getString("documentCode"));
                        doc.setTitle(rs.getString("title"));
                        cp.setDocument(doc);
                        BorrowingDetail5 d = new BorrowingDetail5(cp, rs.getString("conditionOnBorrowing"));
                        d.setId(rs.getInt("id"));
                        slip.getDetails().add(d);
                    }
                }
            }
            return slip;
        }
    }

    // ---------------------------------------------------------------- helpers

    private static void checkReaderEligible(Connection c, int readerId, Date today) throws SQLException, BorrowException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT m.accountStatus, r.readerStatus FROM tblReader5 r JOIN tblMember5 m ON m.id = r.id WHERE r.id = ?")) {
            ps.setInt(1, readerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new BorrowException("Không tìm thấy độc giả.");
                if (!Status5.ACTIVE.equals(rs.getString("accountStatus")) || !Status5.ACTIVE.equals(rs.getString("readerStatus")))
                    throw new BorrowException("Độc giả đang bị ngừng quyền mượn.");
            }
        }
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT COUNT(*) FROM tblReaderCard5 WHERE readerId = ? AND cardStatus = ? AND expiryDate >= ?")) {
            ps.setInt(1, readerId);
            ps.setString(2, Status5.ACTIVE);
            ps.setDate(3, today);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                if (rs.getInt(1) == 0) throw new BorrowException("Thẻ độc giả không còn hiệu lực (hết hạn, bị khóa hoặc chưa có thẻ).");
            }
        }
    }

    private static void lockAndCheckCopy(Connection c, DocumentCopy5 cp) throws SQLException, BorrowException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT usageStatus, copyCondition FROM tblDocumentCopy5 WHERE id = ? FOR UPDATE")) {
            ps.setInt(1, cp.getId());
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) throw new BorrowException("Bản " + cp.getCopyCode() + " không còn tồn tại.");
                String status = rs.getString("usageStatus");
                if (!Status5.COPY_AVAILABLE.equals(status))
                    throw new BorrowException("Bản " + cp.getCopyCode() + " không thể cho mượn (" + status + ").");
                if (Status5.COND_DAMAGED.equals(rs.getString("copyCondition")))
                    throw new BorrowException("Bản " + cp.getCopyCode() + " đang hư hỏng nên không thể cho mượn.");
            }
        }
    }

    private static int insertSlip(Connection c, BorrowingSlip5 slip) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO tblBorrowingSlip5 (borrowDate, dueDate, readerId, librarianId) VALUES (?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setDate(1, slip.getBorrowDate());
            ps.setDate(2, slip.getDueDate());
            ps.setInt(3, slip.getReader().getId());
            ps.setInt(4, slip.getLibrarian().getId());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }
}
