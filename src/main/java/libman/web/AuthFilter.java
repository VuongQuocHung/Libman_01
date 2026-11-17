package libman.web;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Bảo vệ toàn bộ /view/*: phải đăng nhập, và đúng vai trò với từng khu vực
 * (/view/reader/* cho độc giả, /view/librarian/* cho nhân viên thư viện).
 */
@WebFilter("/view/*")
public class AuthFilter implements Filter {

    public static final String ROLE_READER = "READER";
    public static final String ROLE_LIBRARIAN = "LIBRARIAN";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        String ctx = req.getContextPath();

        // Không cho trình duyệt cache trang đã đăng nhập (tránh bấm Back sau khi đăng xuất)
        res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setDateHeader("Expires", 0);

        HttpSession session = req.getSession(false);
        String role = session == null ? null : (String) session.getAttribute("role");
        if (role == null) {
            res.sendRedirect(ctx + "/login.jsp");
            return;
        }

        String path = req.getRequestURI().substring(ctx.length());
        boolean readerArea = path.startsWith("/view/reader/");
        boolean librarianArea = path.startsWith("/view/librarian/");
        if ((readerArea && !ROLE_READER.equals(role)) || (librarianArea && !ROLE_LIBRARIAN.equals(role))) {
            res.sendRedirect(ctx + "/index.jsp");
            return;
        }
        chain.doFilter(request, response);
    }
}
