package libman.model;

/** Kết quả thống kê bản của một đầu tài liệu (giá trị dẫn xuất, không lưu trong CSDL). */
public class CopyStatistics5 {
    private final int totalCount;
    private final int availableCount;

    public CopyStatistics5(int totalCount, int availableCount) {
        this.totalCount = totalCount;
        this.availableCount = availableCount;
    }

    /** Tổng số bản thư viện đang quản lí (không tính bản đã thanh lí). */
    public int getTotalCount() { return totalCount; }

    /** Số bản có thể cho mượn ngay. */
    public int getAvailableCount() { return availableCount; }
}
