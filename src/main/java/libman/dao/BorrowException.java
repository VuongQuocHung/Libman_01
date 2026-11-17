package libman.dao;

/** Lỗi nghiệp vụ khi lưu phiếu mượn (thông điệp hiển thị trực tiếp cho nhân viên). */
public class BorrowException extends Exception {
    public BorrowException(String message) {
        super(message);
    }
}
