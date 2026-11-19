# LibMan: quản lí thư viện (JSP)

Bài tập lớn Phân tích thiết kế hệ thống thông tin, đề số 1. Cài đặt 2 module:

1. **Độc giả tìm tài liệu**: đăng nhập, tìm theo tên (không cần gõ dấu), xem chi tiết kèm số bản có thể mượn.
2. **Nhân viên thư viện cho độc giả mượn tài liệu**: xác định độc giả bằng mã thẻ, thêm từng bản tài liệu, nhập hạn trả chung, xem phiếu, **In phiếu** để lưu và in.

## Chạy

1. Sao chép `src/main/resources/db.properties.example` thành `src/main/resources/db.properties`,
   rồi điền `db.username` và `db.password` của MySQL. File `db.properties` đã nằm trong `.gitignore`
   nên mật khẩu không bị đưa lên Git.
2. Build: `mvn clean package` (ra `target/libman-01.war`), hoặc để IntelliJ build.
3. Chạy trên **Tomcat 9** (dùng `javax.servlet`; Tomcat 10 trở lên sẽ không chạy).
   Cách nhanh: chép `target/libman-01.war` vào `webapps` của Tomcat rồi mở `http://localhost:8080/libman-01/`.
4. Lần chạy đầu, ứng dụng tự tạo database `libman`, 17 bảng và nạp dữ liệu mẫu
   (`src/main/resources/sql/schema.sql`, `data.sql`). Đặt `db.autoinit=false` để tắt.
   Muốn nạp lại từ đầu: `DROP DATABASE libman;` rồi khởi động lại ứng dụng.

## Tài khoản mẫu (mật khẩu chung `123456`)

| Tài khoản | Vai trò |
|---|---|
| `hung` | Độc giả Vương Quốc Hưng (BD001, thẻ THE001) |
| `mai` | Nhân viên thư viện Trần Thị Mai |

Thẻ để thử: `THE001` hợp lệ, `THE002` hết hạn, `THE003` bị khóa, `THE004` hợp lệ.
Mã bản để thử: `BTL001`–`BTL013` (BTL004, 005, 008 đang được mượn; BTL012 tạm ngừng phục vụ).

## Cấu trúc (theo package diagram trong báo cáo)

```
src/main/java/libman/
  model/   Member5, Reader5, Staff5, Librarian5, Document5, DocumentCopy5, ReaderCard5,
           BorrowingSlip5, BorrowingDetail5 ...
  dao/     MemberDAO5, ReaderDAO5, ReaderCardDAO5, DocumentDAO5, DocumentCopyDAO5, BorrowingSlipDAO5
  util/    DBUtil, DatabaseInitializer, LendingSession, Html, Flash, PasswordUtil
  web/     AuthFilter (phân quyền theo vai trò), EncodingFilter
src/main/webapp/
  login.jsp, doLogin.jsp, doLogout.jsp
  view/reader/     ReaderHomeView5, DocumentSearchView5, DocumentDetailView5
  view/librarian/  LibrarianHomeView5, DocumentLendingView5, ReaderIdentificationView5,
  DocumentCopySelectionView5, BorrowingSlipView5, doSaveBorrowingSlip5
```

## Khác biệt nhỏ so với báo cáo

- Cột `condition` của `tblDocumentCopy5` đặt tên `copyCondition` (CONDITION là từ khóa MySQL).
- Mã phiếu mượn sinh tự động dạng `PM` + số thứ tự 3 chữ số (PM001, PM002, ...).
- Mật khẩu lưu dạng SHA-256 (đủ cho bài tập; hệ thống thật nên dùng bcrypt/argon2 có salt).
- Hạn trả mặc định gợi ý 30 ngày (`LendingSession.DEFAULT_LOAN_DAYS`), nhân viên sửa được.
- Giao diện dùng Google Fonts (Be Vietnam Pro, Newsreader); khi offline sẽ dùng font hệ thống.
