package libman.util;

import java.util.ArrayList;
import java.util.List;
import javax.servlet.http.HttpSession;
import libman.model.BorrowingDetail5;

/** Dữ liệu tạm của một lượt cho mượn, giữ trong session cho đến khi hoàn tất hoặc hủy. */
public final class LendingSession {
    private LendingSession() {}

    public static final String READER = "lendReader";          // Reader5 đã xác nhận
    public static final String CARD = "lendCard";              // ReaderCard5 của độc giả đó
    public static final String ITEMS = "lendItems";            // List<BorrowingDetail5> dự kiến mượn
    public static final String DUE = "lendDueDate";            // java.sql.Date hạn trả chung
    public static final String SAVED = "lendSavedSlipId";      // Integer id phiếu đã lưu
    public static final String JUST_SAVED = "lendJustSaved";   // Boolean: vừa lưu, cần gửi lệnh in một lần

    /** Số ngày mượn mặc định gợi ý cho hạn trả (nhân viên vẫn sửa được). */
    public static final int DEFAULT_LOAN_DAYS = 30;

    @SuppressWarnings("unchecked")
    public static List<BorrowingDetail5> items(HttpSession s) {
        List<BorrowingDetail5> list = (List<BorrowingDetail5>) s.getAttribute(ITEMS);
        if (list == null) {
            list = new ArrayList<>();
            s.setAttribute(ITEMS, list);
        }
        return list;
    }

    public static boolean hasCopy(HttpSession s, String copyCode) {
        for (BorrowingDetail5 d : items(s)) {
            if (d.getDocumentCopy().getCopyCode().equalsIgnoreCase(copyCode)) return true;
        }
        return false;
    }

    public static Integer savedSlipId(HttpSession s) {
        return (Integer) s.getAttribute(SAVED);
    }

    public static void clear(HttpSession s) {
        s.removeAttribute(READER);
        s.removeAttribute(CARD);
        s.removeAttribute(ITEMS);
        s.removeAttribute(DUE);
        s.removeAttribute(SAVED);
        s.removeAttribute(JUST_SAVED);
    }
}
