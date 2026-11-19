<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException, libman.dao.*, libman.model.*, libman.util.Html" %>
<%
    String pageTitle = "Chi tiết tài liệu";

    String code = "";
    if (request.getParameter("code") != null) {
        code = request.getParameter("code").trim();
    }

    String keyword = "";
    if (request.getParameter("keyword") != null) {
        keyword = request.getParameter("keyword").trim();
    }

    Document5 document = null;
    int totalCount = 0;
    int availableCount = 0;
    String message = null;

    // lấy tài liệu và thống kê bản
    try {
        if (!code.isEmpty()) {
            document = new DocumentDAO5().getDocumentByCode(code);
        }

        if (document == null || !document.isInUse()) {
            message = "Tài liệu này không còn khả dụng để tra cứu.";
            document = null;
        } else {
            int[] copyCounts = new DocumentCopyDAO5().getCopyStatistics(document.getId());
            totalCount = copyCounts[DocumentCopyDAO5.TOTAL];
            availableCount = copyCounts[DocumentCopyDAO5.AVAILABLE];
        }
    } catch (SQLException e) {
        application.log("DocumentDetailView5: lỗi CSDL", e);
        message = "Hệ thống chưa tải được thông tin tài liệu. Hãy thử lại sau ít phút.";
        document = null;
    }

    // Quay lại danh sách kết quả, giữ nguyên từ khóa
    String searchUrl = request.getContextPath() + "/view/reader/DocumentSearchView5.jsp";
    String backUrl = searchUrl;
    if (!keyword.isEmpty()) {
        backUrl = searchUrl + "?keyword=" + Html.url(keyword);
    }

    // chuẩn bị dữ liệu hiển thị
    // Dòng "Tác giả — Nhà xuất bản, Năm" dưới tên tài liệu; các phần có thể để trống
    String publisherPart = "";
    String yearText = "";
    String yearPart = "";
    if (document != null) {
        if (document.getPublisher() != null) {
            publisherPart = " — " + Html.esc(document.getPublisher());
        }
        if (document.getYear() != null) {
            yearText = String.valueOf(document.getYear());
            yearPart = ", " + document.getYear();
        }
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <div class="crumbs">
    <a href="<%= ctx %>/view/reader/ReaderHomeView5.jsp">Trang chủ</a> /
    <a href="<%= backUrl %>">Tìm tài liệu</a> / Chi tiết
  </div>
</div>

<% if (document == null) { %>
  <div class="alert alert-error" role="alert"><%= Html.esc(message) %></div>
<% } else { %>
  <article class="catcard">
    <span class="callno"><%= Html.esc(document.getDocumentCode()) %></span>
    <h1><%= Html.esc(document.getTitle()) %></h1>
    <p class="byline">
      <b><%= Html.esc(document.getAuthor()) %></b><%= publisherPart %><%= yearPart %>
    </p>

    <dl class="facts">
      <div><dt>Mã tài liệu</dt><dd><%= Html.esc(document.getDocumentCode()) %></dd></div>
      <div><dt>Loại tài liệu</dt><dd><%= Html.esc(document.getDocumentType()) %></dd></div>
      <div><dt>Tác giả</dt><dd><%= Html.esc(document.getAuthor()) %></dd></div>
      <div><dt>Năm xuất bản</dt><dd><%= yearText %></dd></div>
      <div><dt>Nhà xuất bản</dt><dd><%= Html.esc(document.getPublisher()) %></dd></div>
      <% if (document.getLanguage() != null) { %>
        <div><dt>Ngôn ngữ</dt><dd><%= Html.esc(document.getLanguage()) %></dd></div>
      <% } %>
      <% if (document.getPageCount() != null) { %>
        <div><dt>Số trang</dt><dd><%= document.getPageCount() %></dd></div>
      <% } %>
    </dl>

    <% if (document.getDescription() != null && !document.getDescription().isBlank()) { %>
      <p class="desc"><%= Html.esc(document.getDescription()) %></p>
    <% } %>

    <div class="holdings">
      <div class="count"><small>Tổng số bản đang có</small><b><%= totalCount %></b></div>
      <div class="count"><small>Số bản có thể mượn</small><b><%= availableCount %></b></div>

      <% if (totalCount > 0) { %>
      <div>
        <span class="meter" role="img"
              aria-label="<%= availableCount %> trên <%= totalCount %> bản có thể mượn">
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
        <small style="margin-top:4px">Ô màu xanh là bản có thể mượn ngay</small>
      </div>
      <% } else { %>
      <div><small>Thư viện chưa nhập bản vật lí nào của tài liệu này.</small></div>
      <% } %>
    </div>
  </article>
<% } %>

<div class="actions" style="margin-top:20px">
  <a class="btn" href="<%= backUrl %>">Quay lại</a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
