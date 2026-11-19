<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Date, java.sql.SQLException, java.util.*, libman.dao.*, libman.model.*, libman.util.*" %>
<%
    String pageTitle = "Xác định độc giả";
    String base = request.getContextPath();
    String selfUrl = base + "/view/librarian/ReaderIdentificationView5.jsp";
    String lendingUrl = base + "/view/librarian/DocumentLendingView5.jsp";

    if (LendingSession.savedSlip(session) != null) {
        response.sendRedirect(base + "/view/librarian/BorrowingSlipView5.jsp");
        return;
    }

    boolean isPost = "POST".equalsIgnoreCase(request.getMethod());
    // Mã nhập tay hoặc do đầu đọc quét vào. Chấp nhận mã thẻ (THE001) hoặc mã độc giả (BD001).
    String code = request.getParameter(isPost ? "cardCode" : "code");
    code = code == null ? "" : code.trim();

    ReaderCard5 card = null;
    Reader5 reader = null;
    List<String> problems = new ArrayList<>();
    boolean searched = !code.isEmpty();
    Date today = Html.today();

    if (searched) {
        try {
            // Thẻ trả về đã kèm đầy đủ thông tin độc giả, không cần gọi ReaderDAO5 thêm
            ReaderCardDAO5 cardDao = new ReaderCardDAO5();
            card = cardDao.getCardByCode(code);
            if (card == null) card = cardDao.getCardByReaderCode(code);   // mã nhập có thể là mã độc giả
            if (card != null) {
                reader = card.getReader();
            } else {
                // Không có thẻ nào: tra xem có phải độc giả chưa được cấp thẻ để báo đúng lí do
                reader = new ReaderDAO5().getReaderByCode(code);
            }

            if (reader == null) {
                problems.add("Không tìm thấy thẻ hoặc độc giả có mã “" + code + "”.");
            } else {
                if (!reader.isActive())
                    problems.add("Độc giả đang bị ngừng quyền mượn.");
                if (card == null) {
                    problems.add("Độc giả chưa có thẻ nên chưa thể mượn tài liệu.");
                } else if (!Status5.ACTIVE.equals(card.getCardStatus())) {
                    problems.add("Thẻ đang ở trạng thái “" + card.getCardStatus() + "”.");
                } else if (card.isExpiredOn(today)) {
                    problems.add("Thẻ đã hết hạn từ " + Html.date(card.getExpiryDate()) + ".");
                }
            }
        } catch (SQLException e) {
            application.log("ReaderIdentificationView5: lỗi CSDL", e);
            problems.add("Hệ thống chưa tra cứu được lúc này. Hãy thử lại sau ít phút.");
            reader = null;
        }
    }
    boolean eligible = searched && reader != null && card != null && problems.isEmpty();

    // Xác nhận: lưu độc giả + thẻ vào session rồi quay về màn quản lí mượn
    if (isPost && "confirm".equals(request.getParameter("action"))) {
        if (eligible) {
            session.setAttribute(LendingSession.READER, reader);
            session.setAttribute(LendingSession.CARD, card);
            Flash.success(session, "Đã chọn độc giả " + reader.getFullName() + ".");
            response.sendRedirect(lendingUrl);
        } else {
            Flash.error(session, problems.isEmpty() ? "Hãy tìm độc giả trước khi xác nhận." : problems.get(0));
            response.sendRedirect(selfUrl + (code.isEmpty() ? "" : "?code=" + Html.url(code)));
        }
        return;
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <div class="crumbs"><a href="<%= ctx %>/view/librarian/LibrarianHomeView5.jsp">Trang chủ</a> / <a href="<%= lendingUrl %>">Quản lí mượn tài liệu</a> / Xác định độc giả</div>
  <h1>Xác định độc giả</h1>
</div>

<ol class="steps" aria-label="Các bước cho mượn">
  <li class="now"><span>1</span>Xác định độc giả</li>
  <li><span>2</span>Chọn bản tài liệu</li>
  <li><span>3</span>Phiếu mượn</li>
</ol>

<form class="panel" method="get" action="<%= selfUrl %>" role="search">
  <label class="lbl" for="code">Mã thẻ hoặc mã độc giả</label>
  <div class="searchbar">
    <input class="input" id="code" name="code" type="text" value="<%= Html.esc(code) %>" autofocus autocomplete="off"
           placeholder="Quét thẻ độc giả hoặc nhập mã, ví dụ THE001">
    <button class="btn btn-primary" type="submit">Tìm kiếm</button>
  </div>
  <div class="hint">Đầu đọc mã vạch sẽ tự điền mã vào ô này rồi tìm.</div>
</form>

<% if (searched && !problems.isEmpty()) { %>
  <div class="alert alert-error" style="margin-top:18px" role="alert">
    <% for (String p : problems) { %><div><%= Html.esc(p) %></div><% } %>
    <% if (reader != null) { %><div style="margin-top:4px">Không thể cho độc giả này mượn tài liệu.</div><% } %>
  </div>
<% } %>

<% if (reader != null) { %>
<div class="cols" style="margin-top:18px;grid-template-columns:1fr 1fr">
  <section class="panel">
    <div class="panel-head"><h2>Thông tin độc giả</h2></div>
    <dl class="kv">
      <dt>Mã độc giả</dt><dd><%= Html.esc(reader.getReaderCode()) %></dd>
      <dt>Họ và tên</dt><dd><%= Html.esc(reader.getFullName()) %></dd>
      <dt>Ngày sinh</dt><dd><%= Html.date(reader.getBirthDate()) %></dd>
      <dt>Email</dt><dd><%= Html.esc(reader.getEmail()) %></dd>
      <dt>Số điện thoại</dt><dd><%= Html.esc(reader.getPhone()) %></dd>
      <dt>Địa chỉ</dt><dd><%= Html.esc(reader.getAddress()) %></dd>
    </dl>
  </section>
  <section class="panel">
    <div class="panel-head"><h2>Thẻ độc giả</h2></div>
    <% if (card == null) { %>
      <p class="muted" style="margin:0">Chưa có thẻ.</p>
    <% } else {
         boolean cardOk = card.isValidOn(today); %>
      <dl class="kv">
        <dt>Mã thẻ</dt><dd><%= Html.esc(card.getCardCode()) %></dd>
        <dt>Ngày đăng kí thẻ</dt><dd><%= Html.date(card.getRegistrationDate()) %></dd>
        <dt>Ngày hết hạn thẻ</dt><dd><%= Html.date(card.getExpiryDate()) %></dd>
        <dt>Trạng thái</dt>
        <dd><span class="badge <%= cardOk ? "badge-ok" : "badge-bad" %>"><%= cardOk ? "Đang dùng được" : (card.isExpiredOn(today) ? "Đã hết hạn" : Html.esc(card.getCardStatus())) %></span></dd>
      </dl>
    <% } %>
  </section>
</div>
<% } %>

<div class="actions" style="margin-top:20px">
  <a class="btn" href="<%= lendingUrl %>">Quay lại</a>
  <span class="spacer"></span>
  <% if (eligible) { %>
  <form method="post" action="<%= selfUrl %>">
    <input type="hidden" name="action" value="confirm">
    <input type="hidden" name="cardCode" value="<%= Html.esc(card.getCardCode()) %>">
    <button class="btn btn-primary" type="submit">Xác nhận độc giả</button>
  </form>
  <% } else { %>
    <span class="btn btn-primary is-disabled" aria-disabled="true">Xác nhận độc giả</span>
  <% } %>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
