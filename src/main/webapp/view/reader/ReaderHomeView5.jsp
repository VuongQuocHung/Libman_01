<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="libman.model.*, libman.util.Html" %>
<%
    String pageTitle = "Trang chủ độc giả";
    Reader5 reader = (Reader5) session.getAttribute("member");
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <h1>Xin chào, <%= Html.esc(reader.getFullName()) %></h1>
  <p class="lede">Tra cứu tài liệu của thư viện trước khi đến quầy mượn.</p>
</div>

<div class="tiles">
  <a class="tile" href="<%= ctx %>/view/reader/DocumentSearchView5.jsp">
    <svg viewBox="0 0 40 40" fill="none" stroke="currentColor" stroke-width="2.2"
         stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <circle cx="17" cy="17" r="10"/>
      <path d="M25 25l9 9"/>
      <path d="M12 17h10M12 13h7"/>
    </svg>
    <div>
      <h3>Tìm tài liệu</h3>
      <p>Nhập tên sách, giáo trình hoặc tạp chí để xem còn bao nhiêu bản có thể mượn.</p>
    </div>
  </a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
