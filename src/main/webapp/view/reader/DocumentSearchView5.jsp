<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException, java.util.*, libman.dao.*, libman.model.*, libman.util.Html" %>
<%
    String pageTitle = "Tìm tài liệu";

    // Từ khóa đi theo URL (GET) để nút "Quay lại" từ trang chi tiết giữ nguyên kết quả
    String rawKeyword = request.getParameter("keyword");
    boolean submitted = rawKeyword != null;
    String keyword = "";
    if (submitted) {
        keyword = rawKeyword.trim();
    }

    // Thông báo hiển thị dưới ô tìm kiếm (lỗi nhập liệu hoặc không có kết quả)
    String message = null;
    String messageType = "info";

    List<Document5> documents = new ArrayList<>();

    // {tổng số bản, số bản có thể mượn} theo id tài liệu
    Map<Integer, int[]> statistics = new HashMap<>();

    // Phân trang: ?page=2 (đếm từ 1); giá trị lạ thì coi như trang 1
    int pageSize = DocumentDAO5.PAGE_SIZE;
    int totalDocuments = 0;
    int totalPages = 1;
    int currentPage = 1;
    try {
        int requestedPage = Integer.parseInt(request.getParameter("page").trim());
        currentPage = Math.max(1, requestedPage);
    } catch (RuntimeException e) {
        // Không có tham số page hoặc không phải số: giữ trang 1
    }

    // tìm kiếm
    if (submitted) {
        if (keyword.isEmpty()) {
            message = "Hãy nhập tên tài liệu cần tìm.";
            messageType = "error";
        } else {
            try {
                DocumentDAO5 documentDao = new DocumentDAO5();
                totalDocuments = documentDao.countDocumentByTitle(keyword);
                totalPages = Math.max(1, (totalDocuments + pageSize - 1) / pageSize);

                // Trang vượt quá thì lùi về trang cuối
                currentPage = Math.min(currentPage, totalPages);

                if (totalDocuments > 0) {
                    documents = documentDao.getDocumentByTitle(keyword, currentPage, pageSize);

                    // Một truy vấn đếm bản cho cả trang, không gọi riêng từng tài liệu
                    List<Integer> documentIds = new ArrayList<>();
                    for (Document5 document : documents) {
                        documentIds.add(document.getId());
                    }
                    statistics = new DocumentCopyDAO5().getCopyStatistics(documentIds);
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

    // chuẩn bị dữ liệu hiển thị
    String messageRole = "status";
    if ("error".equals(messageType)) {
        messageRole = "alert";
    }

    // Dòng tóm tắt bên cạnh tiêu đề kết quả: "3 tài liệu" hoặc "Hiển thị 11–20 trong 47 tài liệu"
    int firstResult = (currentPage - 1) * pageSize + 1;
    int lastResult = firstResult + documents.size() - 1;
    String resultSummary;
    if (totalDocuments <= pageSize) {
        resultSummary = totalDocuments + " tài liệu";
    } else {
        resultSummary = "Hiển thị " + firstResult + "–" + lastResult + " trong " + totalDocuments + " tài liệu";
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <div class="crumbs">
    <a href="<%= ctx %>/view/reader/ReaderHomeView5.jsp">Trang chủ</a> / Tìm tài liệu
  </div>
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
  <div class="alert alert-<%= messageType %>" style="margin-top:18px" role="<%= messageRole %>">
    <%= Html.esc(message) %>
  </div>
<% } %>

<% if (!documents.isEmpty()) { %>
<div class="panel" style="margin-top:18px">
  <div class="panel-head">
    <h2>Kết quả cho “<%= Html.esc(keyword) %>”</h2>
    <span class="muted"><%= resultSummary %></span>
  </div>
  <div class="table-wrap">
    <table class="grid">
      <thead>
        <tr>
          <th>TT</th>
          <th>Mã tài liệu</th>
          <th>Tên tài liệu</th>
          <th>Loại</th>
          <th class="num">Năm xuất bản</th>
          <th>Số bản có thể mượn</th>
        </tr>
      </thead>
      <tbody>
      <%
          // Số thứ tự tiếp nối giữa các trang
          int rowNumber = (currentPage - 1) * pageSize;

          for (Document5 document : documents) {
              rowNumber++;

              int[] copyCounts = statistics.get(document.getId());
              int totalCount = copyCounts[DocumentCopyDAO5.TOTAL];
              int availableCount = copyCounts[DocumentCopyDAO5.AVAILABLE];

              String yearText = "";
              if (document.getYear() != null) {
                  yearText = String.valueOf(document.getYear());
              }

              String detailUrl = ctx + "/view/reader/DocumentDetailView5.jsp"
                      + "?code=" + Html.url(document.getDocumentCode())
                      + "&keyword=" + Html.url(keyword);
      %>
        <tr>
          <td><%= rowNumber %></td>
          <td class="code"><%= Html.esc(document.getDocumentCode()) %></td>
          <td><a class="title" href="<%= detailUrl %>"><%= Html.esc(document.getTitle()) %></a></td>
          <td><%= Html.esc(document.getDocumentType()) %></td>
          <td class="num"><%= yearText %></td>
          <td>
            <span class="avail">
              <span class="meter" aria-hidden="true">
                <%-- Mỗi ô là một bản; ô xanh là bản có thể mượn, ô xám là bản đang bận --%>
                <%
                    for (int copyIndex = 0; copyIndex < totalCount; copyIndex++) {
                        String boxClass = "off";
                        if (copyIndex < availableCount) {
                            boxClass = "";
                        }
                %>
                  <i class="<%= boxClass %>"></i>
                <% } %>
              </span>
              <span><b><%= availableCount %></b> / <%= totalCount %> bản</span>
            </span>
          </td>
        </tr>
      <% } %>
      </tbody>
    </table>
  </div>

  <% if (totalPages > 1) {
         String pageUrlBase = ctx + "/view/reader/DocumentSearchView5.jsp"
                 + "?keyword=" + Html.url(keyword) + "&page=";
  %>
  <nav class="pager" aria-label="Chuyển trang kết quả">
    <% if (currentPage > 1) { %>
      <a class="btn btn-small" href="<%= pageUrlBase + (currentPage - 1) %>">Trang trước</a>
    <% } else { %>
      <span class="btn btn-small is-disabled" aria-disabled="true">Trang trước</span>
    <% } %>

    <span class="muted">Trang <b><%= currentPage %></b> / <%= totalPages %></span>

    <% if (currentPage < totalPages) { %>
      <a class="btn btn-small" href="<%= pageUrlBase + (currentPage + 1) %>">Trang sau</a>
    <% } else { %>
      <span class="btn btn-small is-disabled" aria-disabled="true">Trang sau</span>
    <% } %>
  </nav>
  <% } %>
</div>
<% } %>

<div class="actions" style="margin-top:20px">
  <a class="btn" href="<%= ctx %>/view/reader/ReaderHomeView5.jsp">Quay lại</a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
