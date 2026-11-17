<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException, libman.dao.ReaderCardDAO5, libman.model.*, libman.util.Html" %>
<%
    String pageTitle = "Trang chủ độc giả";
    Reader5 reader = (Reader5) session.getAttribute("member");

    // Thông tin thẻ hiện tại (chỉ để hiển thị; lỗi CSDL không làm hỏng trang chủ)
    ReaderCard5 card = null;
    try {
        card = new ReaderCardDAO5().getCardByReaderCode(reader.getReaderCode());
    } catch (SQLException e) {
        application.log("ReaderHomeView5: không đọc được thẻ độc giả", e);
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <h1>Xin chào, <%= Html.esc(reader.getFullName()) %></h1>
  <p class="lede">Tra cứu tài liệu của thư viện trước khi đến quầy mượn.</p>
</div>

<div class="tiles">
  <a class="tile" href="<%= ctx %>/view/reader/DocumentSearchView5.jsp">
    <svg viewBox="0 0 40 40" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <circle cx="17" cy="17" r="10"/><path d="M25 25l9 9"/><path d="M12 17h10M12 13h7"/>
    </svg>
    <div>
      <h3>Tìm tài liệu</h3>
      <p>Nhập tên sách, giáo trình hoặc tạp chí để xem còn bao nhiêu bản có thể mượn.</p>
    </div>
  </a>
</div>

<div class="panel" style="margin-top:22px">
  <div class="panel-head"><h2>Thẻ độc giả</h2></div>
  <% if (card == null) { %>
    <p class="muted" style="margin:0">Bạn chưa có thẻ độc giả. Hãy liên hệ thư viện để được cấp thẻ trước khi mượn tài liệu.</p>
  <% } else {
       boolean valid = card.isValidOn(Html.today());
       String badgeClass = valid ? "badge-ok" : "badge-bad";
       String badgeText = valid ? "Đang dùng được" : (card.isExpiredOn(Html.today()) ? "Đã hết hạn" : card.getCardStatus());
  %>
    <dl class="kv" style="grid-template-columns:repeat(4,auto);justify-content:start;gap:6px 36px">
      <div><dt>Mã độc giả</dt><dd><%= Html.esc(reader.getReaderCode()) %></dd></div>
      <div><dt>Mã thẻ</dt><dd><%= Html.esc(card.getCardCode()) %></dd></div>
      <div><dt>Hết hạn</dt><dd><%= Html.date(card.getExpiryDate()) %></dd></div>
      <div><dt>Trạng thái</dt><dd><span class="badge <%= badgeClass %>"><%= Html.esc(badgeText) %></span></dd></div>
    </dl>
  <% } %>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
