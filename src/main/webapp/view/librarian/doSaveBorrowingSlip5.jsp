<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Date, java.sql.SQLException, java.util.ArrayList, java.util.List, libman.dao.*, libman.model.*, libman.util.*" %>
<%
    // Lưu phiếu mượn: lấy dữ liệu lập phiếu từ session, rồi ghi phiếu, chi tiết
    // và đổi trạng thái các bản trong một giao dịch.
    String base = request.getContextPath();
    String lendingUrl = base + "/view/librarian/DocumentLendingView5.jsp";
    String slipUrl = base + "/view/librarian/BorrowingSlipView5.jsp";

    // Chỉ nhận yêu cầu POST (bấm nút In phiếu)
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(lendingUrl);
        return;
    }

    // Bấm lại hoặc tải lại sau khi đã lưu: không lưu lần hai
    if (LendingSession.savedSlip(session) != null) {
        response.sendRedirect(slipUrl);
        return;
    }

    // Lấy dữ liệu lập phiếu từ session
    Reader5 reader = (Reader5) session.getAttribute(LendingSession.READER);
    Librarian5 librarian = (Librarian5) session.getAttribute("member");
    Date dueDate = (Date) session.getAttribute(LendingSession.DUE);
    List<BorrowingDetail5> items = LendingSession.items(session);

    if (reader == null || items.isEmpty() || dueDate == null) {
        Flash.error(session, "Chưa đủ thông tin để lập phiếu. "
                + "Kiểm tra độc giả, danh sách tài liệu và hạn trả.");
        response.sendRedirect(lendingUrl);
        return;
    }

    // Thiết lập phiếu mượn. Các chi tiết phiếu mượn đã được tạo lúc thêm từng bản
    // vào danh sách, ở đây chỉ cần gắn vào phiếu.
    BorrowingSlip5 slip = new BorrowingSlip5();
    slip.setReader(reader);
    slip.setLibrarian(librarian);
    slip.setBorrowDate(Html.today());
    slip.setDueDate(dueDate);
    slip.setDetails(new ArrayList<>(items));

    try {
        BorrowingSlip5 savedSlip = new BorrowingSlipDAO5().saveBorrowingSlip(slip);

        // Giữ chính phiếu đã lưu để hiển thị, không đọc lại CSDL
        session.setAttribute(LendingSession.SAVED, savedSlip);
        session.setAttribute(LendingSession.JUST_SAVED, Boolean.TRUE);
        session.removeAttribute(LendingSession.ITEMS);
        session.removeAttribute(LendingSession.DUE);
        response.sendRedirect(slipUrl);

    } catch (BorrowException e) {
        // Giao dịch đã hoàn tác, danh sách tạm vẫn còn để nhân viên chỉnh
        Flash.error(session, "Không lưu được phiếu: " + e.getMessage());
        response.sendRedirect(lendingUrl);

    } catch (SQLException e) {
        application.log("doSaveBorrowingSlip5: lỗi CSDL", e);
        Flash.error(session, "Không lưu được phiếu do lỗi cơ sở dữ liệu. "
                + "Chưa có giao dịch nào được ghi nhận, hãy thử lại.");
        response.sendRedirect(lendingUrl);
    }
%>
