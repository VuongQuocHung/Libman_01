package libman.dao;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import libman.model.BorrowingDetail5;
import libman.model.BorrowingSlip5;
import libman.model.DocumentCopy5;

public class BorrowingSlipDAO5 extends DAO5 {

    public BorrowingSlipDAO5() throws SQLException {
        super();
    }

    /**
     * Lưu phiếu mượn và các chi tiết mượn, cập nhật trạng thái các bản tài liệu thành "Đang được mượn".
     * Tất cả nằm trong MỘT giao dịch: hoặc ghi hết, hoặc không ghi gì.
     *
     * @return phiếu đã lưu (đã có id và mã phiếu)
     * @throws Exception nếu có bản không còn "Sẵn có" (ví dụ vừa được người khác mượn)
     */
    public BorrowingSlip5 saveBorrowingSlip(BorrowingSlip5 slip) throws Exception {
        String slipSql = "INSERT INTO tblBorrowingSlip5 "
                + "(borrowDate, dueDate, tblReader5tblMember5id, tblLibrarian5tblStaff5Member5id) "
                + "VALUES (?, ?, ?, ?)";
        String codeSql = "UPDATE tblBorrowingSlip5 SET borrowCode = ? WHERE id = ?";
        String detailSql = "INSERT INTO tblBorrowingDetail5 "
                + "(conditionOnBorrowing, tblBorrowingSlip5id, tblDocumentCopy5id) "
                + "VALUES (?, ?, ?)";
        String copySql = "UPDATE tblDocumentCopy5 SET usageStatus = 'Đang được mượn' "
                + "WHERE id = ? AND usageStatus = 'Sẵn có'";

        int slipId;
        String borrowCode;

        // Mở giao dịch: chưa ghi thật vào CSDL cho đến khi commit
        con.setAutoCommit(false);
        try {
            // 1. Lưu phiếu mượn
            try (PreparedStatement ps = con.prepareStatement(slipSql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setDate(1, slip.getBorrowDate());
                ps.setDate(2, slip.getDueDate());
                ps.setInt(3, slip.getReader().getId());
                ps.setInt(4, slip.getLibrarian().getId());
                ps.executeUpdate();

                try (ResultSet keys = ps.getGeneratedKeys()) {
                    keys.next();
                    slipId = keys.getInt(1);
                }
            }

            // Mã phiếu sinh từ id vừa tạo: PM001, PM002...
            borrowCode = String.format("PM%03d", slipId);
            try (PreparedStatement ps = con.prepareStatement(codeSql)) {
                ps.setString(1, borrowCode);
                ps.setInt(2, slipId);
                ps.executeUpdate();
            }

            // 2. Với từng bản: lưu chi tiết mượn, rồi cập nhật trạng thái bản thành "Đang được mượn"
            for (BorrowingDetail5 detail : slip.getDetails()) {
                DocumentCopy5 copy = detail.getDocumentCopy();

                try (PreparedStatement ps = con.prepareStatement(detailSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, detail.getConditionOnBorrowing());
                    ps.setInt(2, slipId);
                    ps.setInt(3, copy.getId());
                    ps.executeUpdate();

                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        keys.next();
                        detail.setId(keys.getInt(1));
                    }
                }

                // Chỉ cập nhật được khi bản còn "Sẵn có"; nếu bản vừa được người khác mượn
                // thì không có dòng nào thay đổi, báo lỗi để hủy cả phiếu
                try (PreparedStatement ps = con.prepareStatement(copySql)) {
                    ps.setInt(1, copy.getId());
                    int updatedRows = ps.executeUpdate();
                    if (updatedRows == 0) {
                        throw new Exception("Bản " + copy.getCopyCode() + " không còn sẵn có để cho mượn.");
                    }
                }
            }

            // 3. Xác nhận giao dịch
            con.commit();
        } catch (Exception e) {
            // Có lỗi ở bất kì bước nào thì hoàn tác toàn bộ
            con.rollback();
            throw e;
        } finally {
            con.setAutoCommit(true);
        }

        // Ghi CSDL xong: cập nhật lại các đối tượng để phiếu hiển thị khớp với CSDL
        slip.setId(slipId);
        slip.setBorrowCode(borrowCode);
        for (BorrowingDetail5 detail : slip.getDetails()) {
            detail.getDocumentCopy().setUsageStatus("Đang được mượn");
        }
        return slip;
    }
}
