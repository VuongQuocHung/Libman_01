<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException, libman.dao.*, libman.model.*, libman.util.Html" %>
<%
    String pageTitle = "Chi tiết tài liệu";
    String code = request.getParameter("code") == null ? "" : request.getParameter("code").trim();
    String keyword = request.getParameter("keyword") == null ? "" : request.getParameter("keyword").trim();

    Document5 doc = null;
    CopyStatistics5 stats = null;
    String message = null;
    try {
        if (!code.isEmpty()) doc = new DocumentDAO5().getDocumentByCode(code);
        if (doc == null || !doc.isInUse()) {
            message = "Tài liệu này không còn khả dụng để tra cứu.";
            doc = null;
        } else {
            stats = new DocumentCopyDAO5().getCopyStatistics(doc.getId());
        }
    } catch (SQLException e) {
        application.log("DocumentDetailView5: lỗi CSDL", e);
        message = "Hệ thống chưa tải được thông tin tài liệu. Hãy thử lại sau ít phút.";
        doc = null;
    }

    // Quay lại danh sách kết quả, giữ nguyên từ khóa
    String searchUrl = request.getContextPath() + "/view/reader/DocumentSearchView5.jsp";
    String backHref = keyword.isEmpty() ? searchUrl : searchUrl + "?keyword=" + Html.url(keyword);
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <div class="crumbs">
    <a href="<%= ctx %>/view/reader/ReaderHomeView5.jsp">Trang chủ</a> /
    <a href="<%= backHref %>">Tìm tài liệu</a> / Chi tiết
  </div>
</div>

<% if (doc == null) { %>
  <div class="alert alert-error" role="alert"><%= Html.esc(message) %></div>
<% } else { %>
  <article class="catcard">
    <span class="callno"><%= Html.esc(doc.getDocumentCode()) %></span>
    <h1><%= Html.esc(doc.getTitle()) %></h1>
    <p class="byline"><b><%= Html.esc(doc.getAuthor()) %></b><%= doc.getPublisher() == null ? "" : " — " + Html.esc(doc.getPublisher()) %><%= doc.getYear() == null ? "" : ", " + doc.getYear() %></p>

    <dl class="facts">
      <div><dt>Mã tài liệu</dt><dd><%= Html.esc(doc.getDocumentCode()) %></dd></div>
      <div><dt>Loại tài liệu</dt><dd><%= Html.esc(doc.getDocumentType()) %></dd></div>
      <div><dt>Tác giả</dt><dd><%= Html.esc(doc.getAuthor()) %></dd></div>
      <div><dt>Năm xuất bản</dt><dd><%= doc.getYear() == null ? "" : doc.getYear() %></dd></div>
      <div><dt>Nhà xuất bản</dt><dd><%= Html.esc(doc.getPublisher()) %></dd></div>
      <% if (doc.getLanguage() != null) { %><div><dt>Ngôn ngữ</dt><dd><%= Html.esc(doc.getLanguage()) %></dd></div><% } %>
      <% if (doc.getPageCount() != null) { %><div><dt>Số trang</dt><dd><%= doc.getPageCount() %></dd></div><% } %>
    </dl>

    <% if (doc.getDescription() != null && !doc.getDescription().isBlank()) { %>
      <p class="desc"><%= Html.esc(doc.getDescription()) %></p>
    <% } %>

    <div class="holdings">
      <div class="count"><small>Tổng số bản đang có</small><b><%= stats.getTotalCount() %></b></div>
      <div class="count"><small>Số bản có thể mượn</small><b><%= stats.getAvailableCount() %></b></div>
      <% if (stats.getTotalCount() > 0) { %>
      <div>
        <span class="meter" role="img" aria-label="<%= stats.getAvailableCount() %> trên <%= stats.getTotalCount() %> bản có thể mượn"><%
          for (int k = 0; k < stats.getTotalCount(); k++) { %><i class="<%= k < stats.getAvailableCount() ? "" : "off" %>"></i><% } %></span>
        <small style="margin-top:4px">Ô màu xanh là bản có thể mượn ngay</small>
      </div>
      <% } else { %>
      <div><small>Thư viện chưa nhập bản vật lí nào của tài liệu này.</small></div>
      <% } %>
    </div>
  </article>
<% } %>

<div class="actions" style="margin-top:20px">
  <a class="btn" href="<%= backHref %>">Quay lại</a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
