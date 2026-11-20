<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="libman.model.*" %>
<%@ include file="/WEB-INF/jspf/checkLibrarian.jspf" %>
<%
    String pageTitle = "Trang chủ nhân viên thư viện";
    Librarian5 librarian = (Librarian5) session.getAttribute("member");

    // Nếu có một lượt cho mượn đang dở thì hiện đường dẫn để nhân viên làm tiếp
    Reader5 lendingReader = (Reader5) session.getAttribute("lendReader");
    boolean hasSavedSlip = session.getAttribute("lendSavedSlip") != null;

    String continuePage;
    if (hasSavedSlip) {
        continuePage = "BorrowingSlipView5.jsp";
    } else {
        continuePage = "DocumentLendingView5.jsp";
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="hero">
  <div class="hero-text">
    <h1>Xin chào, <%= esc(librarian.getFullName()) %></h1>
    <p class="lede">Làm thủ tục cho độc giả mượn tài liệu tại quầy.</p>
  </div>
</div>

<% if (lendingReader != null) { %>
  <div class="alert alert-warn">
    Đang có một lượt cho mượn chưa xong, độc giả <b><%= esc(lendingReader.getFullName()) %></b>.
    <a href="<%= ctx %>/view/librarian/<%= continuePage %>">Tiếp tục</a>
  </div>
<% } %>

<div class="tiles">
  <a class="tile" href="<%= ctx %>/view/librarian/DocumentLendingView5.jsp">
    <svg viewBox="0 0 40 40" fill="none" stroke="currentColor" stroke-width="2.2"
         stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M6 9h10a4 4 0 0 1 4 4v18a3 3 0 0 0-3-3H6z"/>
      <path d="M34 9H24a4 4 0 0 0-4 4v18a3 3 0 0 1 3-3h11z"/>
      <path d="M26 17h5M26 22h5"/>
    </svg>
    <div>
      <h3>Quản lí mượn tài liệu</h3>
      <p>Xác định độc giả bằng thẻ, quét mã từng bản tài liệu rồi in phiếu mượn.</p>
    </div>
  </a>
</div>

<div class="infostrip">
  <div><small>Mã nhân viên</small><b><%= esc(librarian.getStaffCode()) %></b></div>
  <div><small>Vị trí</small><b><%= esc(librarian.getPosition()) %></b></div>
  <div><small>Ca làm việc</small><b><%= esc(librarian.getSchedule()) %></b></div>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
