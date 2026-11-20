<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLEncoder, java.nio.charset.StandardCharsets, java.sql.SQLException, java.util.*, libman.dao.*, libman.model.*" %>
<%@ include file="/WEB-INF/jspf/checkReader.jspf" %>
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

    // statistics.get(i) là {tổng số bản, số bản có thể mượn} của documents.get(i)
    List<int[]> statistics = new ArrayList<>();

    // tìm kiếm
    if (submitted) {
        if (keyword.isEmpty()) {
            message = "Hãy nhập tên tài liệu cần tìm.";
            messageType = "error";
        } else {
            try (DocumentDAO5 documentDao = new DocumentDAO5();
                 DocumentCopyDAO5 copyDao = new DocumentCopyDAO5()) {
                documents = documentDao.getDocumentByTitle(keyword);

                // Với mỗi tài liệu tìm được, thống kê các bản của tài liệu đó
                for (Document5 document : documents) {
                    statistics.add(copyDao.getCopyStatistics(document.getId()));
                }

                if (documents.isEmpty()) {
                    message = "Không tìm thấy tài liệu phù hợp. Thử từ khóa ngắn hơn hoặc viết khác đi.";
                }
            } catch (SQLException e) {
                application.log("DocumentSearchView5: lỗi CSDL", e);
                message = "Hệ thống chưa tra cứu được lúc này. Hãy thử lại sau ít phút.";
                messageType = "error";
                documents = new ArrayList<>();
            }
        }
    }

    // chuẩn bị dữ liệu hiển thị
    String messageRole = "status";
    if ("error".equals(messageType)) {
        messageRole = "alert";
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
    <input class="input" id="keyword" name="keyword" type="search" value="<%= esc(keyword) %>"
           placeholder="Ví dụ: Cơ sở dữ liệu" autofocus>
    <button class="btn btn-primary" type="submit">Tìm kiếm</button>
  </div>
</form>

<% if (message != null) { %>
  <div class="alert alert-<%= messageType %>" style="margin-top:18px" role="<%= messageRole %>">
    <%= esc(message) %>
  </div>
<% } %>

<% if (!documents.isEmpty()) { %>
<div class="panel" style="margin-top:18px">
  <div class="panel-head">
    <h2>Kết quả cho “<%= esc(keyword) %>”</h2>
    <span class="muted"><%= documents.size() %> tài liệu</span>
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
          for (int i = 0; i < documents.size(); i++) {
              Document5 document = documents.get(i);

              // copyCounts = {tổng số bản, số bản có thể mượn}
              int[] copyCounts = statistics.get(i);
              int totalCount = copyCounts[0];
              int availableCount = copyCounts[1];

              String yearText = "";
              if (document.getYear() != null) {
                  yearText = String.valueOf(document.getYear());
              }

              String detailUrl = ctx + "/view/reader/DocumentDetailView5.jsp"
                      + "?code=" + URLEncoder.encode(document.getDocumentCode(), StandardCharsets.UTF_8)
                      + "&keyword=" + URLEncoder.encode(keyword, StandardCharsets.UTF_8);
      %>
        <tr>
          <td><%= i + 1 %></td>
          <td class="code"><%= esc(document.getDocumentCode()) %></td>
          <td><a class="title" href="<%= detailUrl %>"><%= esc(document.getTitle()) %></a></td>
          <td><%= esc(document.getDocumentType()) %></td>
          <td class="num"><%= yearText %></td>
          <td>
            <span class="avail">
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
