<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.SQLException, java.util.*, libman.dao.*, libman.model.*, libman.util.*" %>
<%
    String pageTitle = "Quét mã bản tài liệu";
    String base = request.getContextPath();
    String selfUrl = base + "/view/librarian/DocumentCopySelectionView5.jsp";
    String lendingUrl = base + "/view/librarian/DocumentLendingView5.jsp";
    String slipUrl = base + "/view/librarian/BorrowingSlipView5.jsp";

    // Phiếu đã lưu thì không thêm bản nữa: chuyển sang màn phiếu mượn
    if (LendingSession.savedSlip(session) != null) {
        response.sendRedirect(slipUrl);
        return;
    }

    // Phải xác định độc giả trước khi thêm bản
    if (session.getAttribute(LendingSession.READER) == null) {
        Flash.error(session, "Hãy xác định độc giả trước khi thêm bản tài liệu.");
        response.sendRedirect(lendingUrl);
        return;
    }

    boolean isPost = "POST".equalsIgnoreCase(request.getMethod());
    String requestedCode = request.getParameter("copyCode");
    String code = "";
    if (requestedCode != null) {
        code = requestedCode.trim();
    }

    DocumentCopy5 copy = null;
    Document5 document = null;
    List<String> problems = new ArrayList<>();
    boolean searched = !code.isEmpty();

    // tìm bản tài liệu và kiểm tra
    if (searched) {
        try {
            copy = new DocumentCopyDAO5().getCopyByCode(code);

            if (copy == null) {
                problems.add("Không tìm thấy bản tài liệu có mã “" + code + "”.");
            } else {
                // Bản tài liệu đã kèm sẵn đầu tài liệu, không cần gọi DocumentDAO5
                document = copy.getDocument();

                if (document == null || !document.isInUse()) {
                    problems.add("Tài liệu của bản này đã ngừng sử dụng.");
                } else if (!Status5.COPY_AVAILABLE.equals(copy.getUsageStatus())) {
                    problems.add("Bản này đang ở trạng thái “" + copy.getUsageStatus()
                            + "”, không thể cho mượn.");
                } else if (Status5.COND_DAMAGED.equals(copy.getCopyCondition())) {
                    problems.add("Bản này đang hư hỏng, không thể cho mượn.");
                }

                if (LendingSession.hasCopy(session, copy.getCopyCode())) {
                    problems.add("Bản này đã có trong danh sách mượn.");
                }
            }
        } catch (SQLException e) {
            application.log("DocumentCopySelectionView5: lỗi CSDL", e);
            problems.add("Hệ thống chưa tra cứu được lúc này. Hãy thử lại sau ít phút.");
            copy = null;
        }
    }

    boolean canAdd = searched && copy != null && document != null && problems.isEmpty();

    // Các tình trạng vật lí nhân viên có thể chọn
    String[] conditionChoices = {Status5.COND_GOOD, Status5.COND_OLD, Status5.COND_DAMAGED};

    // bấm Thêm vào danh sách (POST)
    // Kiểm tra lại ở phía máy chủ, không tin dữ liệu gửi từ form
    if (isPost && "add".equals(request.getParameter("action"))) {
        String selectedCondition = request.getParameter("condition");

        boolean conditionIsValid = false;
        for (String choice : conditionChoices) {
            if (choice.equals(selectedCondition)) {
                conditionIsValid = true;
            }
        }

        String retryUrl = selfUrl;
        if (!code.isEmpty()) {
            retryUrl = selfUrl + "?copyCode=" + Html.url(code);
        }

        if (!canAdd) {
            String errorMessage;
            if (problems.isEmpty()) {
                errorMessage = "Hãy tìm bản tài liệu trước khi thêm.";
            } else {
                errorMessage = problems.get(0);
            }
            Flash.error(session, errorMessage);
            response.sendRedirect(retryUrl);

        } else if (!conditionIsValid) {
            Flash.error(session, "Chọn tình trạng vật lí của bản tài liệu.");
            response.sendRedirect(retryUrl);

        } else if (Status5.COND_DAMAGED.equals(selectedCondition)) {
            Flash.error(session, "Bản " + copy.getCopyCode()
                    + " bị hư hỏng nên không thể cho mượn. Hãy báo nhân viên xử lí.");
            response.sendRedirect(retryUrl);

        } else {
            BorrowingDetail5 detail = new BorrowingDetail5(copy, selectedCondition);
            LendingSession.items(session).add(detail);
            Flash.success(session, "Đã thêm bản " + copy.getCopyCode()
                    + " (" + document.getTitle() + ") vào danh sách.");
            response.sendRedirect(lendingUrl);
        }
        return;
    }

    // chuẩn bị dữ liệu hiển thị
    String usageBadgeClass = "badge-warn";
    String pageCountText = "";
    if (copy != null && document != null) {
        if (Status5.COPY_AVAILABLE.equals(copy.getUsageStatus())) {
            usageBadgeClass = "badge-ok";
        }
        if (document.getPageCount() != null) {
            pageCountText = String.valueOf(document.getPageCount());
        }
    }

    // Ô chọn tình trạng và nút Thêm chỉ dùng được khi bản hợp lệ
    String addDisabled = "";
    if (!canAdd) {
        addDisabled = "disabled";
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <div class="crumbs">
    <a href="<%= ctx %>/view/librarian/LibrarianHomeView5.jsp">Trang chủ</a> /
    <a href="<%= lendingUrl %>">Quản lí mượn tài liệu</a> / Quét mã bản tài liệu
  </div>
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
    <input class="input" id="copyCode" name="copyCode" type="text" value="<%= Html.esc(code) %>"
           autofocus autocomplete="off"
           placeholder="Quét mã trên bản tài liệu hoặc nhập mã, ví dụ BTL001">
    <button class="btn btn-primary" type="submit">Tìm kiếm</button>
  </div>
  <div class="hint">Mỗi lần chỉ thêm một bản. Sau khi thêm, quay về danh sách và quét bản tiếp theo.</div>
</form>

<% if (searched && !problems.isEmpty()) { %>
  <div class="alert alert-error" style="margin-top:18px" role="alert">
    <% for (String problem : problems) { %>
      <div><%= Html.esc(problem) %></div>
    <% } %>
  </div>
<% } %>

<% if (copy != null && document != null) { %>
<section class="panel" style="margin-top:18px">
  <div class="panel-head">
    <h2>Thông tin bản tài liệu</h2>
    <span class="badge <%= usageBadgeClass %>"><%= Html.esc(copy.getUsageStatus()) %></span>
  </div>
  <dl class="kv" style="grid-template-columns:auto 1fr auto 1fr;gap:8px 20px">
    <dt>Mã bản tài liệu</dt><dd><%= Html.esc(copy.getCopyCode()) %></dd>
    <dt>Mã đầu tài liệu</dt><dd><%= Html.esc(document.getDocumentCode()) %></dd>
    <dt>Tên tài liệu</dt><dd><%= Html.esc(document.getTitle()) %></dd>
    <dt>Loại tài liệu</dt><dd><%= Html.esc(document.getDocumentType()) %></dd>
    <dt>Ngôn ngữ</dt><dd><%= Html.esc(document.getLanguage()) %></dd>
    <dt>Số trang</dt><dd><%= pageCountText %></dd>
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
      <select class="input" id="condition" name="condition" <%= addDisabled %>>
        <%
            for (String choice : conditionChoices) {
                String selected = "";
                if (copy != null && choice.equals(copy.getCopyCondition())) {
                    selected = "selected";
                }
        %>
          <option value="<%= Html.esc(choice) %>" <%= selected %>><%= Html.esc(choice) %></option>
        <% } %>
      </select>
    </div>
    <span class="spacer"></span>
    <a class="btn" href="<%= lendingUrl %>">Quay lại</a>
    <button class="btn btn-primary" type="submit" <%= addDisabled %>>Thêm vào danh sách</button>
  </div>
  <% if (!canAdd && !searched) { %>
    <div class="hint" style="margin-top:10px">Nút thêm sẽ sáng lên khi bản tài liệu hợp lệ.</div>
  <% } %>
</form>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
