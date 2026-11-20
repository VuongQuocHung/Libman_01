<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLEncoder, java.nio.charset.StandardCharsets, java.sql.SQLException, java.util.*, libman.dao.*, libman.model.*" %>
<%@ include file="/WEB-INF/jspf/checkLibrarian.jspf" %>
<%
    String pageTitle = "Quét mã bản tài liệu";
    String base = request.getContextPath();
    String selfUrl = base + "/view/librarian/DocumentCopySelectionView5.jsp";
    String lendingUrl = base + "/view/librarian/DocumentLendingView5.jsp";
    String slipUrl = base + "/view/librarian/BorrowingSlipView5.jsp";

    // Phiếu đã lưu thì không thêm bản nữa: chuyển sang màn phiếu mượn
    if (session.getAttribute("lendSavedSlip") != null) {
        response.sendRedirect(slipUrl);
        return;
    }

    // Phải xác định độc giả trước khi thêm bản
    if (session.getAttribute("lendReader") == null) {
        session.setAttribute("errorMessage", "Hãy xác định độc giả trước khi thêm bản tài liệu.");
        response.sendRedirect(lendingUrl);
        return;
    }

    // Danh sách các bản dự kiến mượn (giữ trong session)
    List<BorrowingDetail5> items = (List<BorrowingDetail5>) session.getAttribute("lendItems");
    if (items == null) {
        items = new ArrayList<>();
        session.setAttribute("lendItems", items);
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
        try (DocumentCopyDAO5 copyDao = new DocumentCopyDAO5()) {
            copy = copyDao.getCopyByCode(code);

            if (copy == null) {
                problems.add("Không tìm thấy bản tài liệu có mã “" + code + "”.");
            } else {
                // Bản tài liệu đã kèm sẵn đầu tài liệu, không cần gọi DocumentDAO5
                document = copy.getDocument();

                if (!"Đang sử dụng".equals(document.getDocumentStatus())) {
                    problems.add("Tài liệu của bản này đã ngừng sử dụng.");
                } else if (!"Sẵn có".equals(copy.getUsageStatus())) {
                    problems.add("Bản này đang ở trạng thái “" + copy.getUsageStatus()
                            + "”, không thể cho mượn.");
                } else if ("Hư hỏng".equals(copy.getCopyCondition())) {
                    problems.add("Bản này đang hư hỏng, không thể cho mượn.");
                }

                // Bản đã có trong danh sách mượn thì không thêm lần nữa
                for (BorrowingDetail5 item : items) {
                    if (item.getDocumentCopy().getCopyCode().equalsIgnoreCase(copy.getCopyCode())) {
                        problems.add("Bản này đã có trong danh sách mượn.");
                    }
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
    String[] conditionChoices = {"Tốt", "Cũ", "Hư hỏng"};

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
            retryUrl = selfUrl + "?copyCode=" + URLEncoder.encode(code, StandardCharsets.UTF_8);
        }

        if (!canAdd) {
            String errorMessage;
            if (problems.isEmpty()) {
                errorMessage = "Hãy tìm bản tài liệu trước khi thêm.";
            } else {
                errorMessage = problems.get(0);
            }
            session.setAttribute("errorMessage", errorMessage);
            response.sendRedirect(retryUrl);

        } else if (!conditionIsValid) {
            session.setAttribute("errorMessage", "Chọn tình trạng vật lí của bản tài liệu.");
            response.sendRedirect(retryUrl);

        } else if ("Hư hỏng".equals(selectedCondition)) {
            session.setAttribute("errorMessage", "Bản " + copy.getCopyCode()
                    + " bị hư hỏng nên không thể cho mượn. Hãy báo nhân viên xử lí.");
            response.sendRedirect(retryUrl);

        } else {
            // Tạo chi tiết phiếu mượn: bản tài liệu và tình trạng vật lí lúc cho mượn
            BorrowingDetail5 detail = new BorrowingDetail5();
            detail.setDocumentCopy(copy);
            detail.setConditionOnBorrowing(selectedCondition);
            items.add(detail);

            session.setAttribute("successMessage", "Đã thêm bản " + copy.getCopyCode()
                    + " (" + document.getTitle() + ") vào danh sách.");
            response.sendRedirect(lendingUrl);
        }
        return;
    }

    // chuẩn bị dữ liệu hiển thị
    String usageBadgeClass = "badge-warn";
    if (copy != null && "Sẵn có".equals(copy.getUsageStatus())) {
        usageBadgeClass = "badge-ok";
    }

    // Ô chọn tình trạng và nút Thêm chỉ dùng được khi bản hợp lệ
    String addDisabled = "";
    if (!canAdd) {
        addDisabled = "disabled";
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <a class="back" href="<%= lendingUrl %>">
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10 3L5 8l5 5"/></svg>
    Quay lại
  </a>
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
    <input class="input" id="copyCode" name="copyCode" type="text" value="<%= esc(code) %>"
           autofocus autocomplete="off"
           placeholder="Quét mã trên bản tài liệu hoặc nhập mã, ví dụ BTL001">
    <button class="btn btn-primary" type="submit">Tìm kiếm</button>
  </div>
  <div class="hint">Mỗi lần chỉ thêm một bản. Sau khi thêm, quay về danh sách và quét bản tiếp theo.</div>
</form>

<% if (searched && !problems.isEmpty()) { %>
  <div class="alert alert-error" style="margin-top:18px" role="alert">
    <% for (String problem : problems) { %>
      <div><%= esc(problem) %></div>
    <% } %>
  </div>
<% } %>

<% if (copy != null && document != null) { %>
<section class="panel" style="margin-top:18px">
  <div class="panel-head">
    <h2>Thông tin bản tài liệu</h2>
    <span class="badge <%= usageBadgeClass %>"><%= esc(copy.getUsageStatus()) %></span>
  </div>
  <dl class="kv" style="grid-template-columns:auto 1fr auto 1fr;gap:8px 20px">
    <dt>Mã bản tài liệu</dt><dd><%= esc(copy.getCopyCode()) %></dd>
    <dt>Mã đầu tài liệu</dt><dd><%= esc(document.getDocumentCode()) %></dd>
    <dt>Tên tài liệu</dt><dd><%= esc(document.getTitle()) %></dd>
    <dt>Loại tài liệu</dt><dd><%= esc(document.getDocumentType()) %></dd>
    <dt>Tác giả</dt><dd><%= esc(document.getAuthor()) %></dd>
    <dt>Nhà xuất bản</dt><dd><%= esc(document.getPublisher()) %></dd>
    <dt>Vị trí lưu trữ</dt><dd><%= esc(copy.getLocation()) %></dd>
    <dt>Tình trạng ghi nhận</dt><dd><%= esc(copy.getCopyCondition()) %></dd>
  </dl>
</section>
<% } %>

<form method="post" action="<%= selfUrl %>" class="panel" style="margin-top:18px">
  <input type="hidden" name="action" value="add">
  <input type="hidden" name="copyCode" value="<%= esc(code) %>">
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
          <option value="<%= esc(choice) %>" <%= selected %>><%= esc(choice) %></option>
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
