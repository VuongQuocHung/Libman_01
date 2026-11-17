<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%
    response.setStatus(response.getStatus() == 200 ? 500 : response.getStatus());
    String pageTitle = "Có lỗi xảy ra";
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <h1>Không mở được trang này</h1>
  <p class="lede">Trang bạn cần không tồn tại hoặc hệ thống gặp sự cố. Hãy quay về trang chủ và thử lại.</p>
</div>
<div class="actions"><a class="btn btn-primary" href="<%= ctx %>/index.jsp">Về trang chủ</a></div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
