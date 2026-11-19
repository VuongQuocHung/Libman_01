<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Date, java.util.List, libman.model.*, libman.util.*" %>
<%
    String pageTitle = "Quản lí mượn tài liệu";
    String base = request.getContextPath();
    String selfUrl = base + "/view/librarian/DocumentLendingView5.jsp";
    String homeUrl = base + "/view/librarian/LibrarianHomeView5.jsp";
    String slipUrl = base + "/view/librarian/BorrowingSlipView5.jsp";

    // Phiếu đã lưu thì không sửa danh sách nữa: chuyển sang màn phiếu mượn
    if (LendingSession.savedSlip(session) != null) {
        response.sendRedirect(slipUrl);
        return;
    }

    Reader5 lendReader = (Reader5) session.getAttribute(LendingSession.READER);
    ReaderCard5 lendCard = (ReaderCard5) session.getAttribute(LendingSession.CARD);
    List<BorrowingDetail5> items = LendingSession.items(session);
    Date today = Html.today();

    // xử lí các nút bấm (POST)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");

        if ("remove".equals(action)) {
            // Bỏ một bản khỏi danh sách tạm
            String copyCode = request.getParameter("copyCode");
            items.removeIf(detail -> detail.getDocumentCopy().getCopyCode().equals(copyCode));
            Flash.info(session, "Đã bỏ bản " + copyCode + " khỏi danh sách.");

        } else if ("cancel".equals(action)) {
            // Hủy cả lượt cho mượn: xóa dữ liệu tạm rồi về trang chủ
            LendingSession.clear(session);
            Flash.info(session, "Đã hủy lượt cho mượn. Chưa có gì được ghi nhận.");
            response.sendRedirect(homeUrl);
            return;

        } else if ("continue".equals(action)) {
            // Đọc hạn trả nhân viên nhập
            Date submittedDueDate = null;
            try {
                String rawDueDate = request.getParameter("dueDate");
                if (rawDueDate != null && !rawDueDate.isBlank()) {
                    submittedDueDate = Date.valueOf(rawDueDate.trim());
                }
            } catch (IllegalArgumentException e) {
                // Nhập sai định dạng ngày thì coi như chưa nhập
            }
            if (submittedDueDate != null) {
                session.setAttribute(LendingSession.DUE, submittedDueDate);
            }

            // Kiểm tra đủ điều kiện sang bước xem phiếu
            if (lendReader == null) {
                Flash.error(session, "Hãy xác định độc giả trước khi tiếp tục.");
            } else if (items.isEmpty()) {
                Flash.error(session, "Danh sách mượn đang trống. Hãy thêm ít nhất một bản tài liệu.");
            } else if (submittedDueDate == null) {
                Flash.error(session, "Nhập hạn trả theo dạng ngày/tháng/năm hợp lệ.");
            } else if (!submittedDueDate.after(today)) {
                Flash.error(session, "Hạn trả phải sau ngày mượn (" + Html.date(today) + ").");
            } else {
                response.sendRedirect(slipUrl);
                return;
            }
        }

        response.sendRedirect(selfUrl);
        return;
    }

    // chuẩn bị dữ liệu hiển thị
    Date dueDate = (Date) session.getAttribute(LendingSession.DUE);
    if (dueDate == null) {
        dueDate = Date.valueOf(today.toLocalDate().plusDays(LendingSession.DEFAULT_LOAN_DAYS));
    }
    Date earliestDueDate = Date.valueOf(today.toLocalDate().plusDays(1));

    boolean readerOk = lendReader != null;
    boolean hasItems = !items.isEmpty();

    // Màu của các bước ở đầu trang
    String stepOneClass;
    if (readerOk) {
        stepOneClass = "done";
    } else {
        stepOneClass = "now";
    }

    String stepTwoClass;
    if (!readerOk) {
        stepTwoClass = "";
    } else if (hasItems) {
        stepTwoClass = "done";
    } else {
        stepTwoClass = "now";
    }

    String emptyListHint;
    if (readerOk) {
        emptyListHint = "Chọn “Quét mã bản tài liệu” rồi quét hoặc nhập mã trên từng bản.";
    } else {
        emptyListHint = "Xác định độc giả trước, sau đó thêm các bản tài liệu họ muốn mượn.";
    }

    // Nút Tiếp tục chỉ bấm được khi đã có độc giả và ít nhất một bản
    String continueDisabled = "";
    if (!readerOk || !hasItems) {
        continueDisabled = "disabled";
    }
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <div class="crumbs">
    <a href="<%= ctx %>/view/librarian/LibrarianHomeView5.jsp">Trang chủ</a> / Quản lí mượn tài liệu
  </div>
  <h1>Cho độc giả mượn tài liệu</h1>
</div>

<ol class="steps" aria-label="Các bước cho mượn">
  <li class="<%= stepOneClass %>"><span>1</span>Xác định độc giả</li>
  <li class="<%= stepTwoClass %>"><span>2</span>Chọn bản tài liệu</li>
  <li><span>3</span>Phiếu mượn</li>
</ol>

<div class="cols">
  <section class="panel" aria-labelledby="h-reader">
    <div class="panel-head"><h2 id="h-reader">Độc giả</h2></div>
    <% if (!readerOk) { %>
      <p class="reader-empty">Chưa có thông tin độc giả.</p>
      <a class="btn btn-primary" href="<%= ctx %>/view/librarian/ReaderIdentificationView5.jsp">
        Xác định độc giả
      </a>
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
        <a class="btn btn-small" href="<%= ctx %>/view/librarian/ReaderIdentificationView5.jsp">
          Đổi độc giả
        </a>
      </div>
    <% } %>
  </section>

  <section class="panel" aria-labelledby="h-list">
    <div class="panel-head">
      <h2 id="h-list">Danh sách tài liệu mượn</h2>
      <% if (readerOk) { %>
        <a class="btn btn-primary btn-small" href="<%= ctx %>/view/librarian/DocumentCopySelectionView5.jsp">
          Quét mã bản tài liệu
        </a>
      <% } else { %>
        <span class="btn btn-small is-disabled" aria-disabled="true">Quét mã bản tài liệu</span>
      <% } %>
    </div>

    <% if (!hasItems) { %>
      <div class="empty">
        <strong>Chưa có tài liệu nào</strong>
        <%= emptyListHint %>
      </div>
    <% } else { %>
      <div class="table-wrap">
        <table class="grid">
          <thead>
            <tr>
              <th>TT</th>
              <th>Mã bản</th>
              <th>Mã tài liệu</th>
              <th>Tên tài liệu</th>
              <th>Tình trạng</th>
              <th><span class="sr-only">Thao tác</span></th>
            </tr>
          </thead>
          <tbody>
          <%
              int rowNumber = 0;
              for (BorrowingDetail5 detail : items) {
                  rowNumber++;
                  DocumentCopy5 copy = detail.getDocumentCopy();

                  String conditionBadge;
                  if (Status5.COND_GOOD.equals(detail.getConditionOnBorrowing())) {
                      conditionBadge = "badge-ok";
                  } else {
                      conditionBadge = "badge-warn";
                  }
          %>
            <tr>
              <td><%= rowNumber %></td>
              <td class="code"><%= Html.esc(copy.getCopyCode()) %></td>
              <td><%= Html.esc(copy.getDocument().getDocumentCode()) %></td>
              <td><%= Html.esc(copy.getDocument().getTitle()) %></td>
              <td>
                <span class="badge <%= conditionBadge %>">
                  <%= Html.esc(detail.getConditionOnBorrowing()) %>
                </span>
              </td>
              <td>
                <form method="post" action="<%= selfUrl %>">
                  <input type="hidden" name="action" value="remove">
                  <input type="hidden" name="copyCode" value="<%= Html.esc(copy.getCopyCode()) %>">
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
        <input class="input" id="dueDate" name="dueDate" type="date"
               value="<%= Html.iso(dueDate) %>" min="<%= Html.iso(earliestDueDate) %>" required>
      </div>
      <div class="hint" style="flex-basis:100%;margin:0">
        Mặc định <%= LendingSession.DEFAULT_LOAN_DAYS %> ngày kể từ hôm nay.
        Mọi bản trong phiếu dùng chung một hạn trả.
      </div>
    </form>
    <form id="cancelForm" method="post" action="<%= selfUrl %>">
      <input type="hidden" name="action" value="cancel">
    </form>

    <div class="actions" style="margin-top:20px">
      <button class="btn btn-danger" type="submit" form="cancelForm"
              onclick="return confirm('Hủy lượt cho mượn này? Danh sách đang chọn sẽ bị bỏ.');">
        Hủy
      </button>
      <span class="spacer"></span>
      <button class="btn btn-primary" type="submit" form="continueForm" <%= continueDisabled %>>
        Tiếp tục
      </button>
    </div>
  </section>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>
