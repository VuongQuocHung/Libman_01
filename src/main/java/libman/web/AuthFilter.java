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
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        String contextPath = httpRequest.getContextPath();

        disableBrowserCache(httpResponse);

        // Chưa đăng nhập thì chuyển về trang đăng nhập
        String role = getRole(httpRequest);
        if (role == null) {
            httpResponse.sendRedirect(contextPath + "/login.jsp");
            return;
        }

        // Đăng nhập rồi nhưng vào sai khu vực thì đưa về trang chủ của đúng vai trò
        String path = getNormalizedPath(httpRequest);
        if (!isAllowed(path, role)) {
            httpResponse.sendRedirect(contextPath + "/index.jsp");
            return;
        }

        chain.doFilter(request, response);
    }

    /** Không cho trình duyệt lưu lại trang đã đăng nhập (tránh bấm Back sau khi đăng xuất vẫn thấy trang). */
    private static void disableBrowserCache(HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
    }

    /** Vai trò của người dùng đang đăng nhập; null nếu chưa đăng nhập. */
    private static String getRole(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }
        return (String) session.getAttribute("role");
    }

    /**
     * Đường dẫn đã được container chuẩn hóa (bỏ "//", "/./", "/../", ";param").
     * Không dùng getRequestURI() vì đó là chuỗi thô: "/view//librarian/..." sẽ lọt qua phép so tiền tố.
     */
    private static String getNormalizedPath(HttpServletRequest request) {
        String path = request.getServletPath();
        String pathInfo = request.getPathInfo();
        if (pathInfo != null) {
            path = path + pathInfo;
        }
        return path;
    }

    /** Đóng mặc định: chỉ cho qua đúng cặp (khu vực, vai trò); mọi đường dẫn /view/* khác đều bị từ chối. */
    private static boolean isAllowed(String path, String role) {
        boolean isReaderArea = path.startsWith("/view/reader/");
        boolean isLibrarianArea = path.startsWith("/view/librarian/");

        if (isReaderArea && ROLE_READER.equals(role)) {
            return true;
        }
        if (isLibrarianArea && ROLE_LIBRARIAN.equals(role)) {
            return true;
        }
        return false;
    }
}
