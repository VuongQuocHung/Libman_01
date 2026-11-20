<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/helpers.jspf" %>
<%
    String ctx = request.getContextPath();
    if (session.getAttribute("member") != null) {
        response.sendRedirect(ctx + "/index.jsp");
        return;
    }
    String error = (String) session.getAttribute("loginError");
    String lastUser = (String) session.getAttribute("loginUser");
    session.removeAttribute("loginError");
    session.removeAttribute("loginUser");
    boolean loggedOut = "1".equals(request.getParameter("out"));
%>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Đăng nhập · LibMan</title>
  <link rel="icon" href="<%= ctx %>/assets/images/ptit-logo.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700&family=Newsreader:opsz,wght@6..72,500;6..72,600&display=swap&subset=vietnamese" rel="stylesheet">
  <link rel="stylesheet" href="<%= ctx %>/assets/css/libman.css">
</head>
<body>
<div class="login-page">
  <aside class="login-aside">
    <div>
      <div class="login-logo">
        <img src="<%= ctx %>/assets/images/ptit-logo.png" alt="Logo PTIT">
        <span class="brand-name" style="font-family:var(--serif);font-weight:600">LibMan</span>
      </div>
      <p style="margin-top:14px">Thư viện Học viện Công nghệ Bưu chính Viễn thông: tra cứu tài liệu và làm thủ tục mượn tại quầy.</p>
    </div>
    <div class="demo">
      <b>Tài khoản dùng thử</b> (mật khẩu chung: 123456)
      <table>
        <tr><td>hung</td><td>Độc giả, tìm tài liệu</td></tr>
        <tr><td>mai</td><td>Nhân viên thư viện, cho mượn</td></tr>
      </table>
      <p style="margin:10px 0 0;font-size:.8rem;color:#fde3e7">Thẻ để thử cho mượn: THE001 (hợp lệ), THE002 (hết hạn), THE003 (bị khóa), THE004 (hợp lệ).</p>
    </div>
  </aside>
  <section class="login-main">
    <form class="login-box" method="post" action="<%= ctx %>/doLogin.jsp" autocomplete="on">
      <h1>Đăng nhập</h1>
      <p class="muted">Dùng tài khoản do thư viện cấp.</p>
      <% if (error != null) { %>
        <div class="alert alert-error" role="alert" style="margin-top:14px"><%= esc(error) %></div>
      <% } else if (loggedOut) { %>
        <div class="alert alert-info" role="status" style="margin-top:14px">Bạn đã đăng xuất.</div>
      <% } %>
      <div class="field">
        <label class="lbl" for="username">Tên tài khoản</label>
        <input class="input" id="username" name="username" type="text" required autofocus autocomplete="username"
               value="<%= esc(lastUser) %>">
      </div>
      <div class="field">
        <label class="lbl" for="password">Mật khẩu</label>
        <input class="input" id="password" name="password" type="password" required autocomplete="current-password">
      </div>
      <button class="btn btn-primary" type="submit">Đăng nhập</button>
    </form>
  </section>
</div>
</body>
</html>
