<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%
    // Lỗi 404 giữ nguyên mã 404; các lỗi khác (kể cả lỗi chưa có mã) báo là 500
    int statusCode = response.getStatus();
    if (statusCode == 200) {
        statusCode = 500;
    }
    response.setStatus(statusCode);

    String pageTitle = "Có lỗi xảy ra";
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <h1>Không mở được trang này</h1>
  <p class="lede">
    Trang bạn cần không tồn tại hoặc hệ thống gặp sự cố. Hãy quay về trang chủ và thử lại.
  </p>
</div>
<div class="actions">
  <a class="btn btn-primary" href="<%= ctx %>/index.jsp">Về trang chủ</a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
