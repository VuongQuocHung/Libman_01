<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLEncoder, java.nio.charset.StandardCharsets, java.sql.Date, java.sql.SQLException, java.time.LocalDate, java.util.*, libman.dao.*, libman.model.*" %>
<%@ include file="/WEB-INF/jspf/checkLibrarian.jspf" %>
<%
    String pageTitle = "Xác định độc giả";
    String base = request.getContextPath();
    String selfUrl = base + "/view/librarian/ReaderIdentificationView5.jsp";
    String lendingUrl = base + "/view/librarian/DocumentLendingView5.jsp";
    String slipUrl = base + "/view/librarian/BorrowingSlipView5.jsp";

    // Phiếu đã lưu thì không đổi độc giả nữa: chuyển sang màn phiếu mượn
    if (session.getAttribute("lendSavedSlip") != null) {
        response.sendRedirect(slipUrl);
        return;
    }

    // Mã thẻ độc giả (THE001) do nhân viên nhập tay hoặc do đầu đọc quét vào.
    boolean isPost = "POST".equalsIgnoreCase(request.getMethod());
    String requestedCode;
    if (isPost) {
        requestedCode = request.getParameter("cardCode");
    } else {
        requestedCode = request.getParameter("code");
    }

    String code = "";
    if (requestedCode != null) {
        code = requestedCode.trim();
    }

    ReaderCard5 card = null;
    Reader5 reader = null;
    List<String> problems = new ArrayList<>();
    boolean searched = !code.isEmpty();
    Date today = Date.valueOf(LocalDate.now());

    // tìm thẻ và độc giả
    if (searched) {
        try (ReaderCardDAO5 cardDao = new ReaderCardDAO5()) {
            // Thẻ trả về đã kèm đầy đủ thông tin độc giả
            card = cardDao.getCardByCode(code);

            // Kiểm tra điều kiện được mượn
            if (card == null) {
                problems.add("Không tìm thấy thẻ độc giả có mã “" + code + "”.");
            } else {
                reader = card.getReader();

                if (!reader.isActive()) {
                    problems.add("Độc giả đang bị ngừng quyền mượn.");
                }

                if (!"Đang hoạt động".equals(card.getCardStatus())) {
                    problems.add("Thẻ đang ở trạng thái “" + card.getCardStatus() + "”.");
                } else if (card.getExpiryDate().before(today)) {
                    problems.add("Thẻ đã hết hạn từ " + date(card.getExpiryDate()) + ".");
                }
            }
        } catch (SQLException e) {
            application.log("ReaderIdentificationView5: lỗi CSDL", e);
            problems.add("Hệ thống chưa tra cứu được lúc này. Hãy thử lại sau ít phút.");
            reader = null;
        }
    }

    boolean eligible = searched && reader != null && card != null && problems.isEmpty();

    // bấm Xác nhận độc giả (POST)
    // Lưu độc giả và thẻ vào session rồi quay về màn quản lí mượn
    if (isPost && "confirm".equals(request.getParameter("action"))) {
        if (eligible) {
            session.setAttribute("lendReader", reader);
            session.setAttribute("lendCard", card);
            session.setAttribute("successMessage", "Đã chọn độc giả " + reader.getFullName() + ".");
            response.sendRedirect(lendingUrl);
        } else {
            String errorMessage;
            if (problems.isEmpty()) {
                errorMessage = "Hãy tìm độc giả trước khi xác nhận.";
            } else {
                errorMessage = problems.get(0);
            }
            session.setAttribute("errorMessage", errorMessage);

            String backUrl = selfUrl;
            if (!code.isEmpty()) {
                backUrl = selfUrl + "?code=" + URLEncoder.encode(code, StandardCharsets.UTF_8);
            }
            response.sendRedirect(backUrl);
        }
        return;
    }

    // chuẩn bị dữ liệu hiển thị
    // Nhãn trạng thái của thẻ
    String cardBadgeClass = "badge-bad";
    String cardBadgeText = "";
    if (card != null) {
        boolean expired = card.getExpiryDate().before(today);
        if ("Đang hoạt động".equals(card.getCardStatus()) && !expired) {
            cardBadgeClass = "badge-ok";
            cardBadgeText = "Đang dùng được";
        } else if (expired) {
            cardBadgeText = "Đã hết hạn";
        } else {
            cardBadgeText = card.getCardStatus();
        }
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <a class="back" href="<%= lendingUrl %>">
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10 3L5 8l5 5"/></svg>
    Quay lại
  </a>
  <div class="crumbs">
    <a href="<%= ctx %>/view/librarian/LibrarianHomeView5.jsp">Trang chủ</a> /
    <a href="<%= lendingUrl %>">Quản lí mượn tài liệu</a> / Xác định độc giả
  </div>
  <h1>Xác định độc giả</h1>
</div>

<ol class="steps" aria-label="Các bước cho mượn">
  <li class="now"><span>1</span>Xác định độc giả</li>
  <li><span>2</span>Chọn bản tài liệu</li>
  <li><span>3</span>Phiếu mượn</li>
</ol>

<form class="panel" method="get" action="<%= selfUrl %>" role="search">
  <label class="lbl" for="code">Mã thẻ độc giả</label>
  <div class="searchbar">
    <input class="input" id="code" name="code" type="text" value="<%= esc(code) %>"
           autofocus autocomplete="off"
           placeholder="Quét thẻ độc giả hoặc nhập mã thẻ, ví dụ THE001">
    <button class="btn btn-primary" type="submit">Tìm kiếm</button>
  </div>
  <div class="hint">Đầu đọc mã vạch sẽ tự điền mã vào ô này rồi tìm.</div>
</form>

<% if (searched && !problems.isEmpty()) { %>
  <div class="alert alert-error" style="margin-top:18px" role="alert">
    <% for (String problem : problems) { %>
      <div><%= esc(problem) %></div>
    <% } %>
    <% if (reader != null) { %>
      <div style="margin-top:4px">Không thể cho độc giả này mượn tài liệu.</div>
    <% } %>
  </div>
<% } %>

<% if (reader != null) { %>
<div class="cols" style="margin-top:18px;grid-template-columns:1fr 1fr">
  <section class="panel">
    <div class="panel-head"><h2>Thông tin độc giả</h2></div>
    <dl class="kv">
      <dt>Mã độc giả</dt><dd><%= esc(reader.getReaderCode()) %></dd>
      <dt>Họ và tên</dt><dd><%= esc(reader.getFullName()) %></dd>
      <dt>Ngày sinh</dt><dd><%= date(reader.getBirthDate()) %></dd>
      <dt>Email</dt><dd><%= esc(reader.getEmail()) %></dd>
      <dt>Số điện thoại</dt><dd><%= esc(reader.getPhone()) %></dd>
      <dt>Địa chỉ</dt><dd><%= esc(reader.getAddress()) %></dd>
    </dl>
  </section>

  <section class="panel">
    <div class="panel-head"><h2>Thẻ độc giả</h2></div>
    <dl class="kv">
      <dt>Mã thẻ</dt><dd><%= esc(card.getCardCode()) %></dd>
      <dt>Ngày đăng kí thẻ</dt><dd><%= date(card.getRegistrationDate()) %></dd>
      <dt>Ngày hết hạn thẻ</dt><dd><%= date(card.getExpiryDate()) %></dd>
      <dt>Trạng thái</dt>
      <dd>
        <span class="badge <%= cardBadgeClass %>"><%= esc(cardBadgeText) %></span>
      </dd>
    </dl>
  </section>
</div>
<% } %>

<div class="actions" style="margin-top:20px">
  <a class="btn" href="<%= lendingUrl %>">Quay lại</a>
  <span class="spacer"></span>
  <% if (eligible) { %>
    <form method="post" action="<%= selfUrl %>">
      <input type="hidden" name="action" value="confirm">
      <input type="hidden" name="cardCode" value="<%= esc(card.getCardCode()) %>">
      <button class="btn btn-primary" type="submit">Xác nhận độc giả</button>
    </form>
  <% } else { %>
    <span class="btn btn-primary is-disabled" aria-disabled="true">Xác nhận độc giả</span>
  <% } %>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
