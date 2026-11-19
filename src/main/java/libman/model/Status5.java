package libman.model;

/** Các giá trị trạng thái dùng chung (khớp với dữ liệu trong CSDL). */
public final class Status5 {
    private Status5() {
    }

    public static final String ACTIVE = "Đang hoạt động";
    public static final String LOCKED = "Bị khóa";

    public static final String DOC_ACTIVE = "Đang sử dụng";
    public static final String DOC_INACTIVE = "Ngừng sử dụng";

    public static final String COPY_AVAILABLE = "Sẵn có";
    public static final String COPY_BORROWED = "Đang được mượn";
    public static final String COPY_SUSPENDED = "Tạm ngừng phục vụ";
    public static final String COPY_DISPOSED = "Thanh lí";

    public static final String COND_GOOD = "Tốt";
    public static final String COND_OLD = "Cũ";
    public static final String COND_DAMAGED = "Hư hỏng";
}
