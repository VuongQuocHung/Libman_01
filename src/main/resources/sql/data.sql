-- LibMan - dữ liệu mẫu (lấy theo kịch bản trong báo cáo). Mật khẩu mọi tài khoản: 123456
-- (lưu dạng SHA-256: 8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92)

INSERT INTO tblMember5 (id, username, password, fullName, birthDate, email, phone, address, is_active) VALUES
 (1, 'quanly', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Nguyễn Thị Lan', '1985-05-20', 'lan.nt@libman.edu.vn', '0911111111', 'Hà Nội', TRUE),
 (2, 'mai',    '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Trần Thị Mai',    '1992-03-15', 'mai.tt@libman.edu.vn', '0922222222', 'Hà Nội', TRUE),
 (3, 'hung',   '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Vương Quốc Hưng', '2005-01-01', 'vqh@gmail.com',        '0123456789', 'Hà Nội', TRUE),
 (4, 'an',     '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Nguyễn Văn An',   '2004-07-09', 'an.nv@gmail.com',      '0933333333', 'Hải Phòng', TRUE),
 (5, 'binh',   '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Lê Thị Bình',     '2005-11-23', 'binh.lt@gmail.com',    '0944444444', 'Nam Định', TRUE),
 (6, 'duc',    '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', 'Phạm Minh Đức',   '2004-02-02', 'duc.pm@gmail.com',     '0955555555', 'Hà Nội', TRUE);

INSERT INTO tblStaff5 (id, staffCode, position, startDate) VALUES
 (1, 'QL001', 'Trưởng phòng thư viện', '2015-09-01'),
 (2, 'NV001', 'Thủ thư', '2021-03-01');

INSERT INTO tblManager5 (id, `level`) VALUES (1, 'Cấp 1');
INSERT INTO tblLibrarian5 (id, schedule) VALUES (2, 'Ca sáng');

INSERT INTO tblReader5 (id, readerCode) VALUES
 (3, 'BD001'),
 (4, 'BD002'),
 (5, 'BD003'),
 (6, 'BD004');

-- THE001: hợp lệ (đúng kịch bản báo cáo). THE002: đã hết hạn. THE003: bị khóa. THE004: hợp lệ.
INSERT INTO tblReaderCard5 (id, cardCode, registrationDate, expiryDate, cardStatus, readerId) VALUES
 (1, 'THE001', '2023-12-31', '2028-12-31', 'Đang hoạt động', 3),
 (2, 'THE002', '2021-01-01', '2024-12-31', 'Đang hoạt động', 4),
 (3, 'THE003', '2023-06-10', '2029-06-10', 'Bị khóa',        5),
 (4, 'THE004', '2024-01-15', '2029-01-15', 'Đang hoạt động', 6);

INSERT INTO tblSupplier5 (id, supplierCode, name, email, phone, address) VALUES
 (1, 'NCC001', 'Nhà sách Giáo dục Hà Nội', 'lienhe@nsgd.vn', '02438000001', 'Hà Nội'),
 (2, 'NCC002', 'Công ty Sách Tri Thức',    'sales@tri-thuc.vn', '02838000002', 'TP. Hồ Chí Minh');

INSERT INTO tblDocument5 (id, documentCode, title, documentType, author, publisher, `year`, description, language, pageCount, documentStatus) VALUES
 (1, 'TL001', 'Cơ sở dữ liệu', 'Giáo trình', 'Nguyễn Đình Hóa', 'Nhà xuất bản ABC', 2022, 'Bứt phá A+ môn Cơ sở dữ liệu cùng thầy Nguyễn Đình Hóa', 'Tiếng Việt', 250, 'Đang sử dụng'),
 (2, 'TL002', 'Hệ quản trị cơ sở dữ liệu', 'Sách', 'Trần Văn Khoa', 'Nhà xuất bản Khoa học Kỹ thuật', 2023, 'Kiến trúc, cài đặt và vận hành các hệ quản trị cơ sở dữ liệu quan hệ phổ biến.', 'Tiếng Việt', 320, 'Đang sử dụng'),
 (3, 'TL003', 'Hệ quản trị cơ sở dữ liệu phân tán', 'Sách', 'Lê Hoàng Nam', 'Nhà xuất bản Đại học Quốc gia', 2021, 'Phân mảnh, nhân bản và xử lí giao dịch trên cơ sở dữ liệu phân tán.', 'Tiếng Việt', 410, 'Đang sử dụng'),
 (4, 'TL004', 'Lập trình hướng đối tượng', 'Giáo trình', 'Phạm Thu Hà', 'Nhà xuất bản Bưu điện', 2020, 'Các khái niệm lớp, kế thừa, đa hình và thực hành với Java.', 'Tiếng Việt', 280, 'Đang sử dụng'),
 (5, 'TL005', 'Tạp chí Công nghệ thông tin và Truyền thông', 'Tạp chí', 'Ban biên tập', 'Bộ Thông tin và Truyền thông', 2024, 'Số chuyên đề về chuyển đổi số trong giáo dục đại học.', 'Tiếng Việt', 96, 'Đang sử dụng'),
 (6, 'TL006', 'Trí tuệ nhân tạo', 'Sách', 'Đỗ Quang Vinh', 'Nhà xuất bản Thông tin và Truyền thông', 2024, 'Tài liệu mới khai báo, chưa nhập bản vật lí nào.', 'Tiếng Việt', 360, 'Đang sử dụng'),
 (7, 'TL007', 'Tin học đại cương', 'Giáo trình', 'Nhiều tác giả', 'Nhà xuất bản Giáo dục', 2015, 'Giáo trình cũ đã ngừng sử dụng.', 'Tiếng Việt', 200, 'Ngừng sử dụng');

INSERT INTO tblPurchaseInvoice5 (id, invoiceCode, importDate, supplierId, librarianId) VALUES
 (1, 'HDN001', '2023-09-01', 1, 2);

INSERT INTO tblImportDetail5 (id, quantity, price, purchaseInvoiceId, documentId) VALUES
 (1, 5, 85000, 1, 1),
 (2, 3, 95000, 1, 2),
 (3, 1, 120000, 1, 3),
 (4, 2, 78000, 1, 4),
 (5, 2, 45000, 1, 5);

INSERT INTO tblDocumentCopy5 (id, copyCode, location, copyCondition, usageStatus, documentId, importDetailId) VALUES
 (1,  'BTL001', 'Kệ A1', 'Tốt',     'Sẵn có',           1, 1),
 (2,  'BTL002', 'Kệ A1', 'Cũ',      'Sẵn có',           1, 1),
 (3,  'BTL003', 'Kệ A1', 'Tốt',     'Sẵn có',           1, 1),
 (4,  'BTL004', 'Kệ A1', 'Tốt',     'Đang được mượn',   1, 1),
 (5,  'BTL005', 'Kệ A1', 'Tốt',     'Đang được mượn',   1, 1),
 (6,  'BTL006', 'Kệ A2', 'Tốt',     'Sẵn có',           2, 2),
 (7,  'BTL007', 'Kệ A2', 'Tốt',     'Sẵn có',           2, 2),
 (8,  'BTL008', 'Kệ A2', 'Tốt',     'Đang được mượn',   2, 2),
 (9,  'BTL009', 'Kệ A2', 'Tốt',     'Sẵn có',           3, 3),
 (10, 'BTL010', 'Kệ B1', 'Tốt',     'Sẵn có',           4, 4),
 (11, 'BTL011', 'Kệ B1', 'Tốt',     'Sẵn có',           4, 4),
 (12, 'BTL012', 'Kệ C1', 'Hư hỏng', 'Tạm ngừng phục vụ', 5, 5),
 (13, 'BTL013', 'Kệ C1', 'Tốt',     'Sẵn có',           5, 5);

-- Phiếu mượn có sẵn: các bản BTL004, BTL005, BTL008 đang được độc giả BD004 giữ
INSERT INTO tblBorrowingSlip5 (id, borrowCode, borrowDate, dueDate, readerId, librarianId) VALUES
 (1, 'PM001', '2026-11-01', '2026-12-01', 6, 2);

INSERT INTO tblBorrowingDetail5 (id, conditionOnBorrowing, borrowingSlipId, documentCopyId) VALUES
 (1, 'Tốt', 1, 4),
 (2, 'Tốt', 1, 5),
 (3, 'Tốt', 1, 8);
