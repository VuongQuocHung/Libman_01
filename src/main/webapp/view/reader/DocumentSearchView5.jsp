<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException, java.util.*, libman.dao.*, libman.model.*, libman.util.Html" %>
<%
    String pageTitle = "Tìm tài liệu";

    // Từ khóa đi theo URL (GET) để nút "Quay lại" từ trang chi tiết giữ nguyên kết quả
    String rawKeyword = request.getParameter("keyword");
    boolean submitted = rawKeyword != null;
    String keyword = submitted ? rawKeyword.trim() : "";

    String message = null;           // lỗi nhập liệu hoặc không có kết quả
    String messageType = "info";
    List<Document5> docs = new ArrayList<>();
    Map<Integer, int[]> stats = new HashMap<>();   // {tổng số bản, số bản có thể mượn} theo id tài liệu

    // Phân trang: ?page=2 (đếm từ 1); giá trị lạ thì coi như trang 1
    int pageSize = DocumentDAO5.PAGE_SIZE;
    int totalDocs = 0, totalPages = 1, currentPage = 1;
    try {
        currentPage = Math.max(1, Integer.parseInt(request.getParameter("page").trim()));
    } catch (RuntimeException ignored) { }

    if (submitted) {
        if (keyword.isEmpty()) {
            message = "Hãy nhập tên tài liệu cần tìm.";
            messageType = "error";
        } else {
            try {
                DocumentDAO5 docDao = new DocumentDAO5();
                totalDocs = docDao.countDocumentByTitle(keyword);
                totalPages = Math.max(1, (totalDocs + pageSize - 1) / pageSize);
                currentPage = Math.min(currentPage, totalPages);   // trang vượt quá thì lùi về trang cuối
                if (totalDocs > 0) {
                    docs = docDao.getDocumentByTitle(keyword, currentPage, pageSize);
                    // Một truy vấn đếm bản cho cả trang, không gọi riêng từng tài liệu
                    List<Integer> ids = new ArrayList<>();
                    for (Document5 d : docs) ids.add(d.getId());
                    stats = new DocumentCopyDAO5().getCopyStatistics(ids);
                } else {
                    message = "Không tìm thấy tài liệu phù hợp. Thử từ khóa ngắn hơn hoặc viết khác đi.";
                }
            } catch (SQLException e) {
                application.log("DocumentSearchView5: lỗi CSDL", e);
                message = "Hệ thống chưa tra cứu được lúc này. Hãy thử lại sau ít phút.";
                messageType = "error";
            }
        }
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <div class="crumbs"><a href="<%= ctx %>/view/reader/ReaderHomeView5.jsp">Trang chủ</a> / Tìm tài liệu</div>
  <h1>Tìm tài liệu</h1>
</div>

<form class="panel" method="get" action="<%= ctx %>/view/reader/DocumentSearchView5.jsp" role="search">
  <label class="lbl" for="keyword">Tên tài liệu</label>
  <div class="searchbar">
    <input class="input" id="keyword" name="keyword" type="search" value="<%= Html.esc(keyword) %>"
           placeholder="Ví dụ: Cơ sở dữ liệu" autofocus>
    <button class="btn btn-primary" type="submit">Tìm kiếm</button>
  </div>
  <div class="hint">Nhập một phần tên cũng được. Không cần gõ dấu tiếng Việt.</div>
</form>

<% if (message != null) { %>
  <div class="alert alert-<%= messageType %>" style="margin-top:18px" role="<%= "error".equals(messageType) ? "alert" : "status" %>"><%= Html.esc(message) %></div>
<% } %>

<% if (!docs.isEmpty()) { %>
<div class="panel" style="margin-top:18px">
  <div class="panel-head">
    <h2>Kết quả cho “<%= Html.esc(keyword) %>”</h2>
    <span class="muted">
      <% int from = (currentPage - 1) * pageSize + 1; int to = from + docs.size() - 1; %>
      <%= totalDocs <= pageSize ? totalDocs + " tài liệu" : "Hiển thị " + from + "–" + to + " trong " + totalDocs + " tài liệu" %>
    </span>
  </div>
  <div class="table-wrap">
    <table class="grid">
      <thead>
        <tr><th>TT</th><th>Mã tài liệu</th><th>Tên tài liệu</th><th>Loại</th><th class="num">Năm xuất bản</th><th>Số bản có thể mượn</th></tr>
      </thead>
      <tbody>
      <%
        int i = (currentPage - 1) * pageSize;   // số thứ tự tiếp nối giữa các trang
        for (Document5 d : docs) {
            i++;
            int totalCount = stats.get(d.getId())[DocumentCopyDAO5.TOTAL];
            int availableCount = stats.get(d.getId())[DocumentCopyDAO5.AVAILABLE];
            String href = ctx + "/view/reader/DocumentDetailView5.jsp?code=" + Html.url(d.getDocumentCode())
                    + "&keyword=" + Html.url(keyword);
      %>
        <tr>
          <td><%= i %></td>
          <td class="code"><%= Html.esc(d.getDocumentCode()) %></td>
          <td><a class="title" href="<%= href %>"><%= Html.esc(d.getTitle()) %></a></td>
          <td><%= Html.esc(d.getDocumentType()) %></td>
          <td class="num"><%= d.getYear() == null ? "" : d.getYear() %></td>
          <td>
            <span class="avail">
              <span class="meter" aria-hidden="true"><%
                for (int k = 0; k < totalCount; k++) { %><i class="<%= k < availableCount ? "" : "off" %>"></i><% } %></span>
              <span><b><%= availableCount %></b> / <%= totalCount %> bản</span>
            </span>
          </td>
        </tr>
      <% } %>
      </tbody>
    </table>
  </div>
  <% if (totalPages > 1) {
       String pageBase = ctx + "/view/reader/DocumentSearchView5.jsp?keyword=" + Html.url(keyword) + "&page="; %>
  <nav class="pager" aria-label="Chuyển trang kết quả">
    <% if (currentPage > 1) { %><a class="btn btn-small" href="<%= pageBase + (currentPage - 1) %>">Trang trước</a>
    <% } else { %><span class="btn btn-small is-disabled" aria-disabled="true">Trang trước</span><% } %>
    <span class="muted">Trang <b><%= currentPage %></b> / <%= totalPages %></span>
    <% if (currentPage < totalPages) { %><a class="btn btn-small" href="<%= pageBase + (currentPage + 1) %>">Trang sau</a>
    <% } else { %><span class="btn btn-small is-disabled" aria-disabled="true">Trang sau</span><% } %>
  </nav>
  <% } %>
</div>
<% } %>

<div class="actions" style="margin-top:20px">
  <a class="btn" href="<%= ctx %>/view/reader/ReaderHomeView5.jsp">Quay lại</a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
