<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // Điều hướng theo vai trò sau đăng nhập
    String role = (String) session.getAttribute("role");
    String ctx = request.getContextPath();
    if ("READER".equals(role)) {
        response.sendRedirect(ctx + "/view/reader/ReaderHomeView5.jsp");
    } else if ("LIBRARIAN".equals(role)) {
        response.sendRedirect(ctx + "/view/librarian/LibrarianHomeView5.jsp");
    } else {
        response.sendRedirect(ctx + "/login.jsp");
    }
%>
