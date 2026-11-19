<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException, libman.dao.MemberDAO5, libman.model.*" %>
<%
    String ctx = request.getContextPath();

    // Chỉ nhận yêu cầu POST từ form đăng nhập
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    // Đọc tên tài khoản và mật khẩu người dùng nhập
    String username = "";
    if (request.getParameter("username") != null) {
        username = request.getParameter("username").trim();
    }

    String password = "";
    if (request.getParameter("password") != null) {
        password = request.getParameter("password");
    }

    // kiểm tra tài khoản
    String error = null;
    Member5 member = null;

    if (username.isEmpty() || password.isEmpty()) {
        error = "Nhập tên tài khoản và mật khẩu.";
    } else {
        try (MemberDAO5 memberDao = new MemberDAO5()) {
            member = memberDao.login(username, password);

            if (member == null) {
                error = "Tên tài khoản hoặc mật khẩu không đúng.";
            } else if (!member.isActive()) {
                error = "Tài khoản đang bị khóa. Liên hệ thư viện để được hỗ trợ.";
            } else if (!(member instanceof Reader5 || member instanceof Librarian5)) {
                error = "Phiên bản này chỉ hỗ trợ độc giả và nhân viên thư viện.";
            }
        } catch (SQLException e) {
            application.log("Đăng nhập: lỗi CSDL", e);
            error = "Không kết nối được cơ sở dữ liệu. "
                    + "Kiểm tra db.username và db.password trong db.properties.";
        }
    }

    // Có lỗi thì quay lại trang đăng nhập, giữ lại tên tài khoản đã nhập
    if (error != null) {
        session.setAttribute("loginError", error);
        session.setAttribute("loginUser", username);
        response.sendRedirect(ctx + "/login.jsp");
        return;
    }

    // đăng nhập thành công
    // Đổi session id để chống tấn công cố định phiên (session fixation)
    request.changeSessionId();
    member.setPassword(null);

    String role;
    if (member instanceof Reader5) {
        role = "READER";
    } else {
        role = "LIBRARIAN";
    }

    session.setAttribute("member", member);
    session.setAttribute("role", role);
    response.sendRedirect(ctx + "/index.jsp");
%>
