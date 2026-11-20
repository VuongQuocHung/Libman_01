# LibMan: quản lí thư viện (JSP)

Bài tập lớn Phân tích thiết kế hệ thống thông tin, đề số 1. Cài đặt 2 module:

1. **Độc giả tìm tài liệu**: đăng nhập, tìm theo tên (không cần gõ dấu), xem chi tiết kèm số bản có thể mượn.
2. **Nhân viên thư viện cho độc giả mượn tài liệu**: xác định độc giả bằng mã thẻ, thêm từng bản tài liệu, nhập hạn trả chung, xem phiếu, **In phiếu** để lưu và in.

## Chạy

1. Tạo CSDL và nạp dữ liệu mẫu (17 bảng):
   ```
   mysql -u root -p < src/main/resources/sql/schema.sql
   mysql -u root -p < src/main/resources/sql/data.sql
   ```
   Muốn nạp lại từ đầu: `DROP DATABASE libman;` rồi chạy lại hai lệnh trên.
2. Sao chép `src/main/resources/db.properties.example` thành `src/main/resources/db.properties`,
   rồi điền `db.username` và `db.password` của MySQL. File `db.properties` đã nằm trong `.gitignore`
   nên mật khẩu không bị đưa lên Git.
3. Build: `mvn clean package` (ra `target/libman-01.war`), hoặc để IntelliJ build.
4. Chạy trên **Tomcat 9** (dùng `javax.servlet`; Tomcat 10 trở lên sẽ không chạy).
   Cách nhanh: chép `target/libman-01.war` vào `webapps` của Tomcat rồi mở `http://localhost:8080/libman-01/`.

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
  model/   Member5, Reader5, Staff5, Librarian5, Manager5, Document5, DocumentCopy5,
           ReaderCard5, BorrowingSlip5, BorrowingDetail5 (chỉ thuộc tính và get/set)
  dao/     DAO5 (lớp cha, giữ kết nối con), MemberDAO5, ReaderCardDAO5, DocumentDAO5,
           DocumentCopyDAO5, BorrowingSlipDAO5
src/main/webapp/
  login.jsp, doLogin.jsp, doLogout.jsp
  view/reader/     ReaderHomeView5, DocumentSearchView5, DocumentDetailView5
  view/librarian/  LibrarianHomeView5, DocumentLendingView5, ReaderIdentificationView5,
                   DocumentCopySelectionView5, BorrowingSlipView5, doSaveBorrowingSlip5
  WEB-INF/jspf/    header, footer, helpers (esc, date), checkReader, checkLibrarian (phân quyền)
```

## Khác biệt nhỏ so với báo cáo

- CSDL theo sơ đồ thiết kế CSDL (mục 3.2): bảng con dùng chung id với bảng cha, khóa ngoại đặt tên
  theo bảng được tham chiếu (`tblReader5tblMember5id`, `tblLibrarian5tblStaff5Member5id`, ...).
  Ngoài sơ đồ vẫn giữ các mã nghiệp vụ `documentCode`, `copyCode`, `borrowCode`, `returnCode` và cột
  `title`, `author` của `tblDocument5` (có trong bước 2 của mục 3.2).
- Cột `condition` của `tblDocumentCopy5` đặt tên `copyCondition` (CONDITION là từ khóa MySQL).
- `tblMember5.type` là vai trò ("Độc giả", "Nhân viên thư viện", "Nhân viên quản lí"), đăng nhập dựa vào
  cột này. `isActive` = 0 nghĩa là tài khoản bị khóa: không đăng nhập được, và nếu là độc giả thì cũng
  không được mượn tài liệu.
- `tblDocument5.status` = "Ngừng sử dụng" thì tài liệu không hiện khi tìm kiếm.
- Mã phiếu mượn sinh tự động dạng `PM` + số thứ tự 3 chữ số (PM001, PM002, ...).
- Mật khẩu lưu dạng SHA-256, câu truy vấn đăng nhập so sánh bằng `SHA2(?, 256)`
  (đủ cho bài tập; hệ thống thật nên dùng bcrypt/argon2 có salt).
- Hạn trả mặc định gợi ý 30 ngày, nhân viên sửa được.
- `DAO5` có thêm hàm `close()` để đóng kết nối sau khi dùng (JSP tạo DAO trong `try (...)`).
- Giao diện dùng Google Fonts (Be Vietnam Pro, Newsreader); khi offline sẽ dùng font hệ thống.
