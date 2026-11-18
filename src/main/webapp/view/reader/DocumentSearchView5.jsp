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

    if (submitted) {
        if (keyword.isEmpty()) {
            message = "Hãy nhập tên tài liệu cần tìm.";
            messageType = "error";
        } else {
            try {
                docs = new DocumentDAO5().getDocumentByTitle(keyword);
                DocumentCopyDAO5 copyDao = new DocumentCopyDAO5();
                for (Document5 d : docs) stats.put(d.getId(), copyDao.getCopyStatistics(d.getId()));
                if (docs.isEmpty()) message = "Không tìm thấy tài liệu phù hợp. Thử từ khóa ngắn hơn hoặc viết khác đi.";
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
    <span class="muted"><%= docs.size() %> tài liệu</span>
  </div>
  <div class="table-wrap">
    <table class="grid">
      <thead>
        <tr><th>TT</th><th>Mã tài liệu</th><th>Tên tài liệu</th><th>Loại</th><th class="num">Năm xuất bản</th><th>Số bản có thể mượn</th></tr>
      </thead>
      <tbody>
      <%
        int i = 0;
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
</div>
<% } %>

<div class="actions" style="margin-top:20px">
  <a class="btn" href="<%= ctx %>/view/reader/ReaderHomeView5.jsp">Quay lại</a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
