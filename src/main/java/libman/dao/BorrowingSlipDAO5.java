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
import libman.model.DocumentCopy5;
import libman.model.Status5;
import libman.util.DBUtil;
import libman.util.Html;

public class BorrowingSlipDAO5 {

    /**
     * Lưu phiếu mượn cùng các chi tiết và chuyển các bản sang "Đang được mượn"
     * trong MỘT giao dịch: hoặc ghi hết, hoặc không ghi gì.
     *
     * @return phiếu đã lưu (đã có id và mã phiếu)
     * @throws BorrowException lỗi nghiệp vụ (độc giả hoặc thẻ không hợp lệ, bản đã bị mượn...)
     */
    public BorrowingSlip5 saveBorrowingSlip(BorrowingSlip5 slip) throws BorrowException, SQLException {

        // ---------- Bước 1: kiểm tra dữ liệu đầu vào
        if (slip.getReader() == null) {
            throw new BorrowException("Chưa xác định độc giả.");
        }
        if (slip.getLibrarian() == null) {
            throw new BorrowException("Không xác định được nhân viên thực hiện.");
        }
        if (slip.getDetails() == null || slip.getDetails().isEmpty()) {
            throw new BorrowException("Danh sách mượn đang trống. Hãy thêm ít nhất một bản tài liệu.");
        }
        if (slip.getDueDate() == null || !slip.getDueDate().after(slip.getBorrowDate())) {
            throw new BorrowException("Hạn trả phải sau ngày mượn.");
        }

        Date today = Html.today();
        int readerId = slip.getReader().getId();

        try (Connection c = DBUtil.getConnection()) {
            // ---------- Bước 2: mở giao dịch (chưa ghi thật vào CSDL cho đến khi commit)
            c.setAutoCommit(false);

            try {
                // ---------- Bước 3: kiểm tra lại độc giả ngay tại thời điểm lưu
                // 3a. Độc giả phải còn được phép mượn
                String readerSql = "SELECT m.is_active "
                        + "FROM tblReader5 r "
                        + "JOIN tblMember5 m ON m.id = r.id "
                        + "WHERE r.id = ?";
                try (PreparedStatement ps = c.prepareStatement(readerSql)) {
                    ps.setInt(1, readerId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new BorrowException("Không tìm thấy độc giả.");
                        }
                        if (!rs.getBoolean("is_active")) {
                            throw new BorrowException("Độc giả đang bị ngừng quyền mượn.");
                        }
                    }
                }

                // 3b. Độc giả phải có ít nhất một thẻ còn hiệu lực
                String cardSql = "SELECT COUNT(*) "
                        + "FROM tblReaderCard5 "
                        + "WHERE readerId = ? AND cardStatus = ? AND expiryDate >= ?";
                try (PreparedStatement ps = c.prepareStatement(cardSql)) {
                    ps.setInt(1, readerId);
                    ps.setString(2, Status5.ACTIVE);
                    ps.setDate(3, today);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        int validCardCount = rs.getInt(1);
                        if (validCardCount == 0) {
                            throw new BorrowException(
                                    "Thẻ độc giả không còn hiệu lực (hết hạn, bị khóa hoặc chưa có thẻ).");
                        }
                    }
                }

                // ---------- Bước 4: khóa và kiểm tra từng bản tài liệu
                // Khóa theo thứ tự id tăng dần để hai nhân viên cùng thao tác không bị kẹt nhau
                List<BorrowingDetail5> sortedDetails = new ArrayList<>(slip.getDetails());
                sortedDetails.sort(Comparator.comparing(detail -> detail.getDocumentCopy().getId()));

                Set<Integer> checkedCopyIds = new HashSet<>();
                String lockSql = "SELECT usageStatus, copyCondition "
                        + "FROM tblDocumentCopy5 "
                        + "WHERE id = ? "
                        + "FOR UPDATE";

                for (BorrowingDetail5 detail : sortedDetails) {
                    DocumentCopy5 copy = detail.getDocumentCopy();

                    boolean isNewCopy = checkedCopyIds.add(copy.getId());
                    if (!isNewCopy) {
                        throw new BorrowException("Bản " + copy.getCopyCode() + " bị thêm trùng trong phiếu.");
                    }

                    try (PreparedStatement ps = c.prepareStatement(lockSql)) {
                        ps.setInt(1, copy.getId());
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                throw new BorrowException("Bản " + copy.getCopyCode() + " không còn tồn tại.");
                            }

                            String usageStatus = rs.getString("usageStatus");
                            if (!Status5.COPY_AVAILABLE.equals(usageStatus)) {
                                throw new BorrowException("Bản " + copy.getCopyCode()
                                        + " không thể cho mượn (" + usageStatus + ").");
                            }

                            String copyCondition = rs.getString("copyCondition");
                            if (Status5.COND_DAMAGED.equals(copyCondition)) {
                                throw new BorrowException("Bản " + copy.getCopyCode()
                                        + " đang hư hỏng nên không thể cho mượn.");
                            }
                        }
                    }
                }

                // ---------- Bước 5: ghi phiếu mượn
                String slipSql = "INSERT INTO tblBorrowingSlip5 (borrowDate, dueDate, readerId, librarianId) "
                        + "VALUES (?, ?, ?, ?)";
                int slipId;
                try (PreparedStatement ps = c.prepareStatement(slipSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setDate(1, slip.getBorrowDate());
                    ps.setDate(2, slip.getDueDate());
                    ps.setInt(3, readerId);
                    ps.setInt(4, slip.getLibrarian().getId());
                    ps.executeUpdate();

                    try (ResultSet generatedKeys = ps.getGeneratedKeys()) {
                        generatedKeys.next();
                        slipId = generatedKeys.getInt(1);
                    }
                }

                // Sinh mã phiếu (PM001, PM002...) từ id vừa tạo
                String borrowCode = String.format("PM%03d", slipId);
                String codeSql = "UPDATE tblBorrowingSlip5 SET borrowCode = ? WHERE id = ?";
                try (PreparedStatement ps = c.prepareStatement(codeSql)) {
                    ps.setString(1, borrowCode);
                    ps.setInt(2, slipId);
                    ps.executeUpdate();
                }
                slip.setId(slipId);
                slip.setBorrowCode(borrowCode);

                // ---------- Bước 6: với từng bản, ghi chi tiết phiếu mượn rồi đổi bản sang "Đang được mượn"
                String detailSql = "INSERT INTO tblBorrowingDetail5 "
                        + "(conditionOnBorrowing, borrowingSlipId, documentCopyId) "
                        + "VALUES (?, ?, ?)";
                String updateCopySql = "UPDATE tblDocumentCopy5 SET usageStatus = ? "
                        + "WHERE id = ? AND usageStatus = ?";

                for (BorrowingDetail5 detail : slip.getDetails()) {
                    DocumentCopy5 copy = detail.getDocumentCopy();

                    try (PreparedStatement ps = c.prepareStatement(detailSql, Statement.RETURN_GENERATED_KEYS)) {
                        ps.setString(1, detail.getConditionOnBorrowing());
                        ps.setInt(2, slipId);
                        ps.setInt(3, copy.getId());
                        ps.executeUpdate();

                        try (ResultSet generatedKeys = ps.getGeneratedKeys()) {
                            if (generatedKeys.next()) {
                                detail.setId(generatedKeys.getInt(1));
                            }
                        }
                    }

                    // Câu UPDATE chỉ có tác dụng khi bản còn "Sẵn có"; nếu bản vừa bị người khác
                    // mượn thì không sửa được dòng nào và báo lỗi
                    try (PreparedStatement ps = c.prepareStatement(updateCopySql)) {
                        ps.setString(1, Status5.COPY_BORROWED);
                        ps.setInt(2, copy.getId());
                        ps.setString(3, Status5.COPY_AVAILABLE);

                        int updatedRows = ps.executeUpdate();
                        if (updatedRows != 1) {
                            throw new BorrowException("Bản " + copy.getCopyCode() + " vừa được người khác mượn.");
                        }
                    }

                    // Cập nhật luôn đối tượng trong bộ nhớ để phiếu hiển thị khớp với CSDL
                    copy.setUsageStatus(Status5.COPY_BORROWED);
                }

                // ---------- Bước 7: xác nhận giao dịch. Có lỗi ở bất kì bước nào thì hoàn tác (rollback)
                c.commit();
                return slip;

            } catch (BorrowException | SQLException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        }
    }
}
