<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Date, java.util.List, libman.model.*, libman.util.*" %>
<%
    String pageTitle = "Quản lí mượn tài liệu";
    String base = request.getContextPath();
    String selfUrl = base + "/view/librarian/DocumentLendingView5.jsp";

    // Phiếu đã lưu thì không sửa danh sách nữa: chuyển sang màn phiếu mượn
    if (LendingSession.savedSlip(session) != null) {
        response.sendRedirect(base + "/view/librarian/BorrowingSlipView5.jsp");
        return;
    }

    Reader5 lendReader = (Reader5) session.getAttribute(LendingSession.READER);
    ReaderCard5 lendCard = (ReaderCard5) session.getAttribute(LendingSession.CARD);
    List<BorrowingDetail5> items = LendingSession.items(session);
    Date today = Html.today();

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        if ("remove".equals(action)) {
            String copyCode = request.getParameter("copyCode");
            items.removeIf(d -> d.getDocumentCopy().getCopyCode().equals(copyCode));
            Flash.info(session, "Đã bỏ bản " + copyCode + " khỏi danh sách.");
        } else if ("cancel".equals(action)) {
            LendingSession.clear(session);
            Flash.info(session, "Đã hủy lượt cho mượn. Chưa có gì được ghi nhận.");
            response.sendRedirect(base + "/view/librarian/LibrarianHomeView5.jsp");
            return;
        } else if ("continue".equals(action)) {
            Date due = null;
            try {
                String raw = request.getParameter("dueDate");
                if (raw != null && !raw.isBlank()) due = Date.valueOf(raw.trim());
            } catch (IllegalArgumentException ignored) { }
            if (due != null) session.setAttribute(LendingSession.DUE, due);

            if (lendReader == null) {
                Flash.error(session, "Hãy xác định độc giả trước khi tiếp tục.");
            } else if (items.isEmpty()) {
                Flash.error(session, "Danh sách mượn đang trống. Hãy thêm ít nhất một bản tài liệu.");
            } else if (due == null) {
                Flash.error(session, "Nhập hạn trả theo dạng ngày/tháng/năm hợp lệ.");
            } else if (!due.after(today)) {
                Flash.error(session, "Hạn trả phải sau ngày mượn (" + Html.date(today) + ").");
            } else {
                response.sendRedirect(base + "/view/librarian/BorrowingSlipView5.jsp");
                return;
            }
        }
        response.sendRedirect(selfUrl);
        return;
    }

    Date due = (Date) session.getAttribute(LendingSession.DUE);
    if (due == null) due = Date.valueOf(today.toLocalDate().plusDays(LendingSession.DEFAULT_LOAN_DAYS));
    boolean readerOk = lendReader != null;
    boolean hasItems = !items.isEmpty();
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <div class="crumbs"><a href="<%= ctx %>/view/librarian/LibrarianHomeView5.jsp">Trang chủ</a> / Quản lí mượn tài liệu</div>
  <h1>Cho độc giả mượn tài liệu</h1>
</div>

<ol class="steps" aria-label="Các bước cho mượn">
  <li class="<%= readerOk ? "done" : "now" %>"><span>1</span>Xác định độc giả</li>
  <li class="<%= !readerOk ? "" : (hasItems ? "done" : "now") %>"><span>2</span>Chọn bản tài liệu</li>
  <li><span>3</span>Phiếu mượn</li>
</ol>

<div class="cols">
  <section class="panel" aria-labelledby="h-reader">
    <div class="panel-head"><h2 id="h-reader">Độc giả</h2></div>
    <% if (!readerOk) { %>
      <p class="reader-empty">Chưa có thông tin độc giả.</p>
      <a class="btn btn-primary" href="<%= ctx %>/view/librarian/ReaderIdentificationView5.jsp">Xác định độc giả</a>
    <% } else { %>
      <dl class="kv">
        <dt>Mã độc giả</dt><dd><%= Html.esc(lendReader.getReaderCode()) %></dd>
        <dt>Họ và tên</dt><dd><%= Html.esc(lendReader.getFullName()) %></dd>
        <% if (lendCard != null) { %>
        <dt>Mã thẻ</dt><dd><%= Html.esc(lendCard.getCardCode()) %></dd>
        <dt>Hết hạn thẻ</dt><dd><%= Html.date(lendCard.getExpiryDate()) %></dd>
        <% } %>
      </dl>
      <div class="actions" style="margin-top:16px">
        <a class="btn btn-small" href="<%= ctx %>/view/librarian/ReaderIdentificationView5.jsp">Đổi độc giả</a>
      </div>
    <% } %>
  </section>

  <section class="panel" aria-labelledby="h-list">
    <div class="panel-head">
      <h2 id="h-list">Danh sách tài liệu mượn</h2>
      <% if (readerOk) { %>
        <a class="btn btn-primary btn-small" href="<%= ctx %>/view/librarian/DocumentCopySelectionView5.jsp">Quét mã bản tài liệu</a>
      <% } else { %>
        <span class="btn btn-small is-disabled" aria-disabled="true">Quét mã bản tài liệu</span>
      <% } %>
    </div>

    <% if (!hasItems) { %>
      <div class="empty">
        <strong>Chưa có tài liệu nào</strong>
        <%= readerOk ? "Chọn “Quét mã bản tài liệu” rồi quét hoặc nhập mã trên từng bản." : "Xác định độc giả trước, sau đó thêm các bản tài liệu họ muốn mượn." %>
      </div>
    <% } else { %>
      <div class="table-wrap">
        <table class="grid">
          <thead><tr><th>TT</th><th>Mã bản</th><th>Mã tài liệu</th><th>Tên tài liệu</th><th>Tình trạng</th><th><span class="sr-only">Thao tác</span></th></tr></thead>
          <tbody>
          <% int i = 0; for (BorrowingDetail5 d : items) { i++; DocumentCopy5 cp = d.getDocumentCopy(); %>
            <tr>
              <td><%= i %></td>
              <td class="code"><%= Html.esc(cp.getCopyCode()) %></td>
              <td><%= Html.esc(cp.getDocument().getDocumentCode()) %></td>
              <td><%= Html.esc(cp.getDocument().getTitle()) %></td>
              <td><span class="badge <%= Status5.COND_GOOD.equals(d.getConditionOnBorrowing()) ? "badge-ok" : "badge-warn" %>"><%= Html.esc(d.getConditionOnBorrowing()) %></span></td>
              <td>
                <form method="post" action="<%= selfUrl %>">
                  <input type="hidden" name="action" value="remove">
                  <input type="hidden" name="copyCode" value="<%= Html.esc(cp.getCopyCode()) %>">
                  <button class="btn btn-small btn-danger" type="submit">Bỏ chọn</button>
                </form>
              </td>
            </tr>
          <% } %>
          </tbody>
        </table>
      </div>
    <% } %>

    <form id="continueForm" class="dueform" method="post" action="<%= selfUrl %>">
      <input type="hidden" name="action" value="continue">
      <div class="field">
        <label class="lbl" for="borrowDate">Ngày mượn</label>
        <input class="input" id="borrowDate" type="text" value="<%= Html.date(today) %>" readonly>
      </div>
      <div class="field">
        <label class="lbl" for="dueDate">Hạn trả chung</label>
        <input class="input" id="dueDate" name="dueDate" type="date" value="<%= Html.iso(due) %>" min="<%= Html.iso(Date.valueOf(today.toLocalDate().plusDays(1))) %>" required>
      </div>
      <div class="hint" style="flex-basis:100%;margin:0">Mặc định <%= LendingSession.DEFAULT_LOAN_DAYS %> ngày kể từ hôm nay. Mọi bản trong phiếu dùng chung một hạn trả.</div>
    </form>
    <form id="cancelForm" method="post" action="<%= selfUrl %>"><input type="hidden" name="action" value="cancel"></form>

    <div class="actions" style="margin-top:20px">
      <button class="btn btn-danger" type="submit" form="cancelForm"
              onclick="return confirm('Hủy lượt cho mượn này? Danh sách đang chọn sẽ bị bỏ.');">Hủy</button>
      <span class="spacer"></span>
      <button class="btn btn-primary" type="submit" form="continueForm" <%= (readerOk && hasItems) ? "" : "disabled" %>>Tiếp tục</button>
    </div>
  </section>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
