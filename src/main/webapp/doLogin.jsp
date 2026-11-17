<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException, libman.dao.MemberDAO5, libman.model.*, libman.util.PasswordUtil" %>
<%
    String ctx = request.getContextPath();
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }
    String username = request.getParameter("username") == null ? "" : request.getParameter("username").trim();
    String password = request.getParameter("password") == null ? "" : request.getParameter("password");

    String error = null;
    Member5 member = null;
    if (username.isEmpty() || password.isEmpty()) {
        error = "Nhập tên tài khoản và mật khẩu.";
    } else {
        try {
            member = new MemberDAO5().login(username, PasswordUtil.hash(password));
            if (member == null) {
                error = "Tên tài khoản hoặc mật khẩu không đúng.";
            } else if (!member.isAccountActive()) {
                error = "Tài khoản đang bị khóa. Liên hệ thư viện để được hỗ trợ.";
            } else if (!(member instanceof Reader5 || member instanceof Librarian5)) {
                error = "Phiên bản này chỉ hỗ trợ độc giả và nhân viên thư viện.";
            }
        } catch (SQLException e) {
            application.log("Đăng nhập: lỗi CSDL", e);
            error = "Không kết nối được cơ sở dữ liệu. Kiểm tra db.username và db.password trong db.properties.";
        }
    }

    if (error != null) {
        session.setAttribute("loginError", error);
        session.setAttribute("loginUser", username);
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    // Đăng nhập thành công: đổi session id để chống session fixation
    request.changeSessionId();
    member.setPassword(null);
    session.setAttribute("member", member);
    session.setAttribute("role", member instanceof Reader5 ? "READER" : "LIBRARIAN");
    response.sendRedirect(ctx + "/index.jsp");
%>
