<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Date, java.sql.SQLException, java.util.List, libman.dao.BorrowingSlipDAO5, libman.model.*, libman.util.*" %>
<%
    String base = request.getContextPath();
    String selfUrl = base + "/view/librarian/BorrowingSlipView5.jsp";
    String lendingUrl = base + "/view/librarian/DocumentLendingView5.jsp";
    String homeUrl = base + "/view/librarian/LibrarianHomeView5.jsp";
    Integer savedId = LendingSession.savedSlipId(session);

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        if ("cancel".equals(action) && savedId == null) {
            LendingSession.clear(session);
            Flash.info(session, "Đã hủy lượt cho mượn. Chưa có gì được ghi nhận.");
            response.sendRedirect(homeUrl);
        } else if ("finish".equals(action) && savedId != null) {
            LendingSession.clear(session);
            Flash.success(session, "Đã hoàn tất cho mượn.");
            response.sendRedirect(homeUrl);
        } else {
            response.sendRedirect(selfUrl);
        }
        return;
    }

    BorrowingSlip5 slip;
    boolean saved = savedId != null;
    boolean printNow = false;
    if (saved) {
        try {
            slip = new BorrowingSlipDAO5().getBorrowingSlipById(savedId);
        } catch (SQLException e) {
            application.log("BorrowingSlipView5: lỗi CSDL", e);
            slip = null;
        }
        if (slip == null) {
            LendingSession.clear(session);
            Flash.error(session, "Không đọc lại được phiếu mượn vừa lưu. Phiếu đã được ghi nhận, hãy kiểm tra lại trong hệ thống.");
            response.sendRedirect(homeUrl);
            return;
        }
        // Chỉ gửi lệnh in tự động đúng một lần ngay sau khi lưu
        printNow = Boolean.TRUE.equals(session.getAttribute(LendingSession.JUST_SAVED));
        session.removeAttribute(LendingSession.JUST_SAVED);
    } else {
        Reader5 reader = (Reader5) session.getAttribute(LendingSession.READER);
        List<BorrowingDetail5> items = LendingSession.items(session);
        Date due = (Date) session.getAttribute(LendingSession.DUE);
        if (reader == null || items.isEmpty() || due == null) {
            Flash.error(session, "Chưa đủ thông tin để lập phiếu. Kiểm tra độc giả, danh sách tài liệu và hạn trả.");
            response.sendRedirect(lendingUrl);
            return;
        }
        slip = new BorrowingSlip5();
        slip.setReader(reader);
        slip.setLibrarian((Librarian5) session.getAttribute("member"));
        slip.setBorrowDate(Html.today());
        slip.setDueDate(due);
        slip.setDetails(items);
    }
    String pageTitle = saved ? "Phiếu mượn đã lưu" : "Phiếu mượn";
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head no-print">
  <div class="crumbs"><a href="<%= ctx %>/view/librarian/LibrarianHomeView5.jsp">Trang chủ</a> / <a href="<%= lendingUrl %>">Quản lí mượn tài liệu</a> / Phiếu mượn</div>
  <h1><%= saved ? "Đã lưu phiếu mượn " + Html.esc(slip.getBorrowCode()) : "Kiểm tra phiếu mượn" %></h1>
  <% if (!saved) { %><p class="lede">Phiếu chỉ được lưu khi bạn bấm “In phiếu”. Kiểm tra lại độc giả, các bản và hạn trả.</p><% } %>
</div>

<ol class="steps no-print" aria-label="Các bước cho mượn">
  <li class="done"><span>1</span>Xác định độc giả</li>
  <li class="done"><span>2</span>Chọn bản tài liệu</li>
  <li class="<%= saved ? "done" : "now" %>"><span>3</span>Phiếu mượn</li>
</ol>

<% if (saved) { %>
  <div class="alert alert-success no-print" role="status">Phiếu <b><%= Html.esc(slip.getBorrowCode()) %></b> đã được lưu và đã gửi lệnh in. Các bản tài liệu đã chuyển sang “Đang được mượn”. Nếu máy in chưa in được, bấm “In lại phiếu”, hệ thống không tạo thêm giao dịch mượn.</div>
<% } %>

<article class="slip">
  <div class="slip-head">
    <div>
      <h2>Phiếu mượn tài liệu</h2>
      <div class="muted">Thư viện trường Đại học · LibMan</div>
    </div>
    <div class="code"><%= saved ? Html.esc(slip.getBorrowCode()) : "Chưa lưu" %></div>
  </div>
  <dl class="kv">
    <dt>Độc giả</dt><dd><%= Html.esc(slip.getReader().getFullName()) %> (<%= Html.esc(slip.getReader().getReaderCode()) %>)</dd>
    <dt>Nhân viên thực hiện</dt><dd><%= Html.esc(slip.getLibrarian().getFullName()) %></dd>
    <dt>Ngày mượn</dt><dd><%= Html.date(slip.getBorrowDate()) %></dd>
    <dt>Hạn trả</dt><dd><%= Html.date(slip.getDueDate()) %></dd>
    <dt>Tổng số bản tài liệu</dt><dd><%= slip.getDetails().size() %></dd>
  </dl>
  <table class="grid">
    <thead><tr><th>TT</th><th>Mã bản</th><th>Tên tài liệu</th><th>Tình trạng</th></tr></thead>
    <tbody>
    <% int i = 0; for (BorrowingDetail5 d : slip.getDetails()) { i++; %>
      <tr>
        <td><%= i %></td>
        <td class="code"><%= Html.esc(d.getDocumentCopy().getCopyCode()) %></td>
        <td><%= Html.esc(d.getDocumentCopy().getDocument().getTitle()) %></td>
        <td><%= Html.esc(d.getConditionOnBorrowing()) %></td>
      </tr>
    <% } %>
    </tbody>
  </table>
  <div class="slip-foot"><div>Độc giả ký nhận</div><div>Nhân viên thư viện</div></div>
</article>

<div class="actions no-print" style="margin-top:20px">
<% if (!saved) { %>
  <a class="btn" href="<%= lendingUrl %>">Quay lại</a>
  <form method="post" action="<%= selfUrl %>">
    <input type="hidden" name="action" value="cancel">
    <button class="btn btn-danger" type="submit" onclick="return confirm('Hủy lượt cho mượn này? Chưa có gì được ghi nhận.');">Hủy</button>
  </form>
  <span class="spacer"></span>
  <form method="post" action="<%= ctx %>/view/librarian/doSaveBorrowingSlip5.jsp">
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
<script>window.addEventListener('load', function () { setTimeout(function () { window.print(); }, 300); });</script>
<% } %>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
