<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Date, java.util.List, libman.model.*, libman.util.*" %>
<%
    String base = request.getContextPath();
    String selfUrl = base + "/view/librarian/BorrowingSlipView5.jsp";
    String lendingUrl = base + "/view/librarian/DocumentLendingView5.jsp";
    String homeUrl = base + "/view/librarian/LibrarianHomeView5.jsp";
    String saveUrl = base + "/view/librarian/doSaveBorrowingSlip5.jsp";
    BorrowingSlip5 savedSlip = LendingSession.savedSlip(session);

    // xử lí các nút bấm (POST)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");

        if ("cancel".equals(action) && savedSlip == null) {
            // Hủy khi chưa lưu: bỏ dữ liệu tạm, chưa có gì trong CSDL
            LendingSession.clear(session);
            Flash.info(session, "Đã hủy lượt cho mượn. Chưa có gì được ghi nhận.");
            response.sendRedirect(homeUrl);

        } else if ("finish".equals(action) && savedSlip != null) {
            // Hoàn tất sau khi đã lưu: xóa dữ liệu tạm rồi về trang chủ
            LendingSession.clear(session);
            Flash.success(session, "Đã hoàn tất cho mượn.");
            response.sendRedirect(homeUrl);

        } else {
            response.sendRedirect(selfUrl);
        }
        return;
    }

    // lấy phiếu cần hiển thị
    boolean saved = savedSlip != null;
    boolean printNow = false;
    BorrowingSlip5 slip;

    if (saved) {
        // Hiển thị thẳng phiếu mà saveBorrowingSlip() đã trả về (đã có mã phiếu), không đọc lại CSDL
        slip = savedSlip;

        // Chỉ gửi lệnh in tự động đúng một lần ngay sau khi lưu
        printNow = Boolean.TRUE.equals(session.getAttribute(LendingSession.JUST_SAVED));
        session.removeAttribute(LendingSession.JUST_SAVED);

    } else {
        // Chưa lưu: dựng phiếu tạm từ dữ liệu trong session để nhân viên kiểm tra
        Reader5 reader = (Reader5) session.getAttribute(LendingSession.READER);
        List<BorrowingDetail5> items = LendingSession.items(session);
        Date dueDate = (Date) session.getAttribute(LendingSession.DUE);

        if (reader == null || items.isEmpty() || dueDate == null) {
            Flash.error(session, "Chưa đủ thông tin để lập phiếu. "
                    + "Kiểm tra độc giả, danh sách tài liệu và hạn trả.");
            response.sendRedirect(lendingUrl);
            return;
        }

        slip = new BorrowingSlip5();
        slip.setReader(reader);
        slip.setLibrarian((Librarian5) session.getAttribute("member"));
        slip.setBorrowDate(Html.today());
        slip.setDueDate(dueDate);
        slip.setDetails(items);
    }

    // chuẩn bị dữ liệu hiển thị
    String pageTitle;
    String heading;
    String slipCodeText;
    String stepThreeClass;

    if (saved) {
        pageTitle = "Phiếu mượn đã lưu";
        heading = "Đã lưu phiếu mượn " + Html.esc(slip.getBorrowCode());
        slipCodeText = Html.esc(slip.getBorrowCode());
        stepThreeClass = "done";
    } else {
        pageTitle = "Phiếu mượn";
        heading = "Kiểm tra phiếu mượn";
        slipCodeText = "Chưa lưu";
        stepThreeClass = "now";
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head no-print">
  <div class="crumbs">
    <a href="<%= ctx %>/view/librarian/LibrarianHomeView5.jsp">Trang chủ</a> /
    <a href="<%= lendingUrl %>">Quản lí mượn tài liệu</a> / Phiếu mượn
  </div>
  <h1><%= heading %></h1>
  <% if (!saved) { %>
    <p class="lede">
      Phiếu chỉ được lưu khi bạn bấm “In phiếu”. Kiểm tra lại độc giả, các bản và hạn trả.
    </p>
  <% } %>
</div>

<ol class="steps no-print" aria-label="Các bước cho mượn">
  <li class="done"><span>1</span>Xác định độc giả</li>
  <li class="done"><span>2</span>Chọn bản tài liệu</li>
  <li class="<%= stepThreeClass %>"><span>3</span>Phiếu mượn</li>
</ol>

<% if (saved) { %>
  <div class="alert alert-success no-print" role="status">
    Phiếu <b><%= Html.esc(slip.getBorrowCode()) %></b> đã được lưu và đã gửi lệnh in.
    Các bản tài liệu đã chuyển sang “Đang được mượn”.
    Nếu máy in chưa in được, bấm “In lại phiếu”, hệ thống không tạo thêm giao dịch mượn.
  </div>
<% } %>

<article class="slip">
  <div class="slip-head">
    <div>
      <h2>Phiếu mượn tài liệu</h2>
      <div class="muted">Thư viện trường Đại học · LibMan</div>
    </div>
    <div class="code"><%= slipCodeText %></div>
  </div>
  <dl class="kv">
    <dt>Độc giả</dt>
    <dd>
      <%= Html.esc(slip.getReader().getFullName()) %>
      (<%= Html.esc(slip.getReader().getReaderCode()) %>)
    </dd>
    <dt>Nhân viên thực hiện</dt><dd><%= Html.esc(slip.getLibrarian().getFullName()) %></dd>
    <dt>Ngày mượn</dt><dd><%= Html.date(slip.getBorrowDate()) %></dd>
    <dt>Hạn trả</dt><dd><%= Html.date(slip.getDueDate()) %></dd>
    <dt>Tổng số bản tài liệu</dt><dd><%= slip.getDetails().size() %></dd>
  </dl>
  <table class="grid">
    <thead>
      <tr><th>TT</th><th>Mã bản</th><th>Tên tài liệu</th><th>Tình trạng</th></tr>
    </thead>
    <tbody>
    <%
        int rowNumber = 0;
        for (BorrowingDetail5 detail : slip.getDetails()) {
            rowNumber++;
    %>
      <tr>
        <td><%= rowNumber %></td>
        <td class="code"><%= Html.esc(detail.getDocumentCopy().getCopyCode()) %></td>
        <td><%= Html.esc(detail.getDocumentCopy().getDocument().getTitle()) %></td>
        <td><%= Html.esc(detail.getConditionOnBorrowing()) %></td>
      </tr>
    <% } %>
    </tbody>
  </table>
  <div class="slip-foot">
    <div>Độc giả ký nhận</div>
    <div>Nhân viên thư viện</div>
  </div>
</article>

<div class="actions no-print" style="margin-top:20px">
<% if (!saved) { %>
  <a class="btn" href="<%= lendingUrl %>">Quay lại</a>
  <form method="post" action="<%= selfUrl %>">
    <input type="hidden" name="action" value="cancel">
    <button class="btn btn-danger" type="submit"
            onclick="return confirm('Hủy lượt cho mượn này? Chưa có gì được ghi nhận.');">
      Hủy
    </button>
  </form>
  <span class="spacer"></span>
  <form method="post" action="<%= saveUrl %>">
    <button class="btn btn-primary" type="submit">In phiếu</button>
  </form>
<% } else { %>
  <button class="btn" type="button" onclick="window.print()">In lại phiếu</button>
  <span class="spacer"></span>
  <form method="post" action="<%= selfUrl %>">
    <input type="hidden" name="action" value="finish">
    <button class="btn btn-primary" type="submit">Hoàn tất</button>
  </form>
<% } %>
</div>

<% if (printNow) { %>
<script>
  window.addEventListener('load', function () {
    setTimeout(function () {
      window.print();
    }, 300);
  });
</script>
<% } %>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
