<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException, java.util.*, libman.dao.*, libman.model.*, libman.util.*" %>
<%
    String pageTitle = "Quét mã bản tài liệu";
    String base = request.getContextPath();
    String selfUrl = base + "/view/librarian/DocumentCopySelectionView5.jsp";
    String lendingUrl = base + "/view/librarian/DocumentLendingView5.jsp";

    if (LendingSession.savedSlipId(session) != null) {
        response.sendRedirect(base + "/view/librarian/BorrowingSlipView5.jsp");
        return;
    }
    // Phải xác định độc giả trước khi thêm bản
    if (session.getAttribute(LendingSession.READER) == null) {
        Flash.error(session, "Hãy xác định độc giả trước khi thêm bản tài liệu.");
        response.sendRedirect(lendingUrl);
        return;
    }

    boolean isPost = "POST".equalsIgnoreCase(request.getMethod());
    String code = request.getParameter("copyCode");
    code = code == null ? "" : code.trim();

    DocumentCopy5 copy = null;
    Document5 doc = null;
    List<String> problems = new ArrayList<>();
    boolean searched = !code.isEmpty();

    if (searched) {
        try {
            copy = new DocumentCopyDAO5().getCopyByCode(code);
            if (copy == null) {
                problems.add("Không tìm thấy bản tài liệu có mã “" + code + "”.");
            } else {
                doc = new DocumentDAO5().getDocumentByCode(copy.getDocument().getDocumentCode());
                if (doc == null || !doc.isInUse()) {
                    problems.add("Tài liệu của bản này đã ngừng sử dụng.");
                } else if (!Status5.COPY_AVAILABLE.equals(copy.getUsageStatus())) {
                    problems.add("Bản này đang ở trạng thái “" + copy.getUsageStatus() + "”, không thể cho mượn.");
                } else if (Status5.COND_DAMAGED.equals(copy.getCopyCondition())) {
                    problems.add("Bản này đang hư hỏng, không thể cho mượn.");
                }
                if (LendingSession.hasCopy(session, copy.getCopyCode()))
                    problems.add("Bản này đã có trong danh sách mượn.");
            }
        } catch (SQLException e) {
            application.log("DocumentCopySelectionView5: lỗi CSDL", e);
            problems.add("Hệ thống chưa tra cứu được lúc này. Hãy thử lại sau ít phút.");
            copy = null;
        }
    }
    boolean canAdd = searched && copy != null && doc != null && problems.isEmpty();

    String[] CONDITIONS = { Status5.COND_GOOD, Status5.COND_OLD, Status5.COND_DAMAGED };

    // Thêm vào danh sách tạm (kiểm tra lại phía máy chủ, không tin dữ liệu form)
    if (isPost && "add".equals(request.getParameter("action"))) {
        String cond = request.getParameter("condition");
        boolean condOk = false;
        for (String c : CONDITIONS) if (c.equals(cond)) condOk = true;

        if (!canAdd) {
            Flash.error(session, problems.isEmpty() ? "Hãy tìm bản tài liệu trước khi thêm." : problems.get(0));
            response.sendRedirect(selfUrl + (code.isEmpty() ? "" : "?copyCode=" + Html.url(code)));
        } else if (!condOk) {
            Flash.error(session, "Chọn tình trạng vật lí của bản tài liệu.");
            response.sendRedirect(selfUrl + "?copyCode=" + Html.url(code));
        } else if (Status5.COND_DAMAGED.equals(cond)) {
            Flash.error(session, "Bản " + copy.getCopyCode() + " bị hư hỏng nên không thể cho mượn. Hãy báo nhân viên xử lí.");
            response.sendRedirect(selfUrl + "?copyCode=" + Html.url(code));
        } else {
            copy.setDocument(doc);   // giữ tên và mã tài liệu để hiển thị trong danh sách
            LendingSession.items(session).add(new BorrowingDetail5(copy, cond));
            Flash.success(session, "Đã thêm bản " + copy.getCopyCode() + " (" + doc.getTitle() + ") vào danh sách.");
            response.sendRedirect(lendingUrl);
        }
        return;
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <div class="crumbs"><a href="<%= ctx %>/view/librarian/LibrarianHomeView5.jsp">Trang chủ</a> / <a href="<%= lendingUrl %>">Quản lí mượn tài liệu</a> / Quét mã bản tài liệu</div>
  <h1>Quét mã bản tài liệu</h1>
</div>

<ol class="steps" aria-label="Các bước cho mượn">
  <li class="done"><span>1</span>Xác định độc giả</li>
  <li class="now"><span>2</span>Chọn bản tài liệu</li>
  <li><span>3</span>Phiếu mượn</li>
</ol>

<form class="panel" method="get" action="<%= selfUrl %>" role="search">
  <label class="lbl" for="copyCode">Mã bản tài liệu</label>
  <div class="searchbar">
    <input class="input" id="copyCode" name="copyCode" type="text" value="<%= Html.esc(code) %>" autofocus autocomplete="off"
           placeholder="Quét mã trên bản tài liệu hoặc nhập mã, ví dụ BTL001">
    <button class="btn btn-primary" type="submit">Tìm kiếm</button>
  </div>
  <div class="hint">Mỗi lần chỉ thêm một bản. Sau khi thêm, quay về danh sách và quét bản tiếp theo.</div>
</form>

<% if (searched && !problems.isEmpty()) { %>
  <div class="alert alert-error" style="margin-top:18px" role="alert">
    <% for (String p : problems) { %><div><%= Html.esc(p) %></div><% } %>
  </div>
<% } %>

<% if (copy != null && doc != null) { %>
<section class="panel" style="margin-top:18px">
  <div class="panel-head"><h2>Thông tin bản tài liệu</h2>
    <span class="badge <%= Status5.COPY_AVAILABLE.equals(copy.getUsageStatus()) ? "badge-ok" : "badge-warn" %>"><%= Html.esc(copy.getUsageStatus()) %></span>
  </div>
  <dl class="kv" style="grid-template-columns:auto 1fr auto 1fr;gap:8px 20px">
    <dt>Mã bản tài liệu</dt><dd><%= Html.esc(copy.getCopyCode()) %></dd>
    <dt>Mã đầu tài liệu</dt><dd><%= Html.esc(doc.getDocumentCode()) %></dd>
    <dt>Tên tài liệu</dt><dd><%= Html.esc(doc.getTitle()) %></dd>
    <dt>Loại tài liệu</dt><dd><%= Html.esc(doc.getDocumentType()) %></dd>
    <dt>Ngôn ngữ</dt><dd><%= Html.esc(doc.getLanguage()) %></dd>
    <dt>Số trang</dt><dd><%= doc.getPageCount() == null ? "" : doc.getPageCount() %></dd>
    <dt>Vị trí lưu trữ</dt><dd><%= Html.esc(copy.getLocation()) %></dd>
    <dt>Tình trạng ghi nhận</dt><dd><%= Html.esc(copy.getCopyCondition()) %></dd>
  </dl>
</section>
<% } %>

<form method="post" action="<%= selfUrl %>" class="panel" style="margin-top:18px">
  <input type="hidden" name="action" value="add">
  <input type="hidden" name="copyCode" value="<%= Html.esc(code) %>">
  <div class="actions">
    <div class="field" style="min-width:220px">
      <label class="lbl" for="condition">Tình trạng vật lí lúc cho mượn</label>
      <select class="input" id="condition" name="condition" <%= canAdd ? "" : "disabled" %>>
        <% for (String c : CONDITIONS) { %>
          <option value="<%= Html.esc(c) %>" <%= (copy != null && c.equals(copy.getCopyCondition())) ? "selected" : "" %>><%= Html.esc(c) %></option>
        <% } %>
      </select>
    </div>
    <span class="spacer"></span>
    <a class="btn" href="<%= lendingUrl %>">Quay lại</a>
    <button class="btn btn-primary" type="submit" <%= canAdd ? "" : "disabled" %>>Thêm vào danh sách</button>
  </div>
  <% if (!canAdd && !searched) { %><div class="hint" style="margin-top:10px">Nút thêm sẽ sáng lên khi bản tài liệu hợp lệ.</div><% } %>
</form>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
