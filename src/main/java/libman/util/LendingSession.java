package libman.util;

import java.util.ArrayList;
import java.util.List;
import javax.servlet.http.HttpSession;
import libman.model.BorrowingDetail5;
import libman.model.BorrowingSlip5;

/** Dữ liệu tạm của một lượt cho mượn, giữ trong session cho đến khi hoàn tất hoặc hủy. */
public final class LendingSession {

    private LendingSession() {
    }

    /** Reader5 đã được nhân viên xác nhận. */
    public static final String READER = "lendReader";

    /** ReaderCard5 của độc giả đó. */
    public static final String CARD = "lendCard";

    /** List<BorrowingDetail5>: các bản dự kiến mượn. */
    public static final String ITEMS = "lendItems";

    /** java.sql.Date: hạn trả chung của cả phiếu. */
    public static final String DUE = "lendDueDate";

    /** BorrowingSlip5 đã lưu (để hiển thị và in lại). */
    public static final String SAVED = "lendSavedSlip";

    /** Boolean: vừa lưu xong, cần gửi lệnh in đúng một lần. */
    public static final String JUST_SAVED = "lendJustSaved";

    /** Số ngày mượn mặc định gợi ý cho hạn trả (nhân viên vẫn sửa được). */
    public static final int DEFAULT_LOAN_DAYS = 30;

    /** Danh sách các bản dự kiến mượn; tạo danh sách rỗng nếu chưa có. */
    @SuppressWarnings("unchecked")
    public static List<BorrowingDetail5> items(HttpSession session) {
        List<BorrowingDetail5> items = (List<BorrowingDetail5>) session.getAttribute(ITEMS);
        if (items == null) {
            items = new ArrayList<>();
            session.setAttribute(ITEMS, items);
        }
        return items;
    }

    /** Bản có mã copyCode đã nằm trong danh sách dự kiến mượn chưa. */
    public static boolean hasCopy(HttpSession session, String copyCode) {
        for (BorrowingDetail5 detail : items(session)) {
            String existingCode = detail.getDocumentCopy().getCopyCode();
            if (existingCode.equalsIgnoreCase(copyCode)) {
                return true;
            }
        }
        return false;
    }

    /** Phiếu mượn vừa lưu trong lượt này; null nếu chưa lưu. */
    public static BorrowingSlip5 savedSlip(HttpSession session) {
        return (BorrowingSlip5) session.getAttribute(SAVED);
    }

    /** Xóa toàn bộ dữ liệu tạm của lượt cho mượn. */
    public static void clear(HttpSession session) {
        session.removeAttribute(READER);
        session.removeAttribute(CARD);
        session.removeAttribute(ITEMS);
        session.removeAttribute(DUE);
        session.removeAttribute(SAVED);
        session.removeAttribute(JUST_SAVED);
    }
}
