<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Date, java.sql.SQLException, java.time.LocalDate, java.util.*, libman.dao.*, libman.model.*" %>
<%@ include file="/WEB-INF/jspf/checkLibrarian.jspf" %>
<%
    // Lưu phiếu mượn: lấy dữ liệu lập phiếu từ session, rồi gọi BorrowingSlipDAO5 lưu phiếu,
    // các chi tiết mượn và cập nhật trạng thái các bản trong một giao dịch.
    String base = request.getContextPath();
    String lendingUrl = base + "/view/librarian/DocumentLendingView5.jsp";
    String slipUrl = base + "/view/librarian/BorrowingSlipView5.jsp";

    // Chỉ nhận yêu cầu POST (bấm nút In phiếu)
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(lendingUrl);
        return;
    }

    // Bấm lại hoặc tải lại sau khi đã lưu: không lưu lần hai
    if (session.getAttribute("lendSavedSlip") != null) {
        response.sendRedirect(slipUrl);
        return;
    }

    // Lấy dữ liệu lập phiếu từ session
    Reader5 reader = (Reader5) session.getAttribute("lendReader");
    Librarian5 librarian = (Librarian5) session.getAttribute("member");
    Date dueDate = (Date) session.getAttribute("lendDueDate");
    List<BorrowingDetail5> items = (List<BorrowingDetail5>) session.getAttribute("lendItems");

    if (reader == null || items == null || items.isEmpty() || dueDate == null) {
        session.setAttribute("errorMessage", "Chưa đủ thông tin để lập phiếu. "
                + "Kiểm tra độc giả, danh sách tài liệu và hạn trả.");
        response.sendRedirect(lendingUrl);
        return;
    }

    // Thiết lập phiếu mượn. Các chi tiết phiếu mượn đã được tạo lúc thêm từng bản
    // vào danh sách, ở đây chỉ cần gắn vào phiếu.
    BorrowingSlip5 slip = new BorrowingSlip5();
    slip.setReader(reader);
    slip.setLibrarian(librarian);
    slip.setBorrowDate(Date.valueOf(LocalDate.now()));
    slip.setDueDate(dueDate);
    slip.setDetails(new ArrayList<>(items));

    try (BorrowingSlipDAO5 slipDao = new BorrowingSlipDAO5()) {
        BorrowingSlip5 savedSlip = slipDao.saveBorrowingSlip(slip);

        // Giữ chính phiếu đã lưu để hiển thị và in, không đọc lại CSDL
        session.setAttribute("lendSavedSlip", savedSlip);
        session.setAttribute("lendJustSaved", true);
        session.removeAttribute("lendItems");
        session.removeAttribute("lendDueDate");
        response.sendRedirect(slipUrl);

    } catch (SQLException e) {
        // Lỗi CSDL (mất kết nối...): giao dịch đã hoàn tác
        application.log("doSaveBorrowingSlip5: lỗi CSDL", e);
        session.setAttribute("errorMessage", "Không lưu được phiếu do lỗi cơ sở dữ liệu. "
                + "Chưa có giao dịch nào được ghi nhận, hãy thử lại.");
        response.sendRedirect(lendingUrl);

    } catch (Exception e) {
        // Lỗi nghiệp vụ (bản không còn sẵn có...): giao dịch đã hoàn tác,
        // danh sách tạm vẫn còn để nhân viên chỉnh
        session.setAttribute("errorMessage", "Không lưu được phiếu: " + e.getMessage());
        response.sendRedirect(lendingUrl);
    }
%>
