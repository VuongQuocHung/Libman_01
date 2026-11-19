-- LibMan - schema MySQL 8 (17 bảng, theo mục 3.2 báo cáo)
-- Quy ước: mỗi lệnh kết thúc bằng dấu; ở cuối dòng. Dòng bắt đầu bằng -- là chú thích.

-- ---------- Nhóm con người (kế thừa dùng chung id) ----------
-- is_active = FALSE nghĩa là tài khoản bị khóa, độc giả cũng không được mượn tài liệu
CREATE TABLE tblMember5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL,
  fullName VARCHAR(100) NOT NULL,
  birthDate DATE NULL,
  email VARCHAR(100) NULL,
  phone VARCHAR(20) NULL,
  address VARCHAR(255) NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE tblStaff5 (
  id INT PRIMARY KEY,
  staffCode VARCHAR(20) NOT NULL UNIQUE,
  position VARCHAR(100) NULL,
  startDate DATE NULL,
  CONSTRAINT fk_staff_member FOREIGN KEY (id) REFERENCES tblMember5(id)
);

CREATE TABLE tblReader5 (
  id INT PRIMARY KEY,
  readerCode VARCHAR(20) NOT NULL UNIQUE,
  CONSTRAINT fk_reader_member FOREIGN KEY (id) REFERENCES tblMember5(id)
);

CREATE TABLE tblManager5 (
  id INT PRIMARY KEY,
  `level` VARCHAR(50) NULL,
  CONSTRAINT fk_manager_staff FOREIGN KEY (id) REFERENCES tblStaff5(id)
);

CREATE TABLE tblLibrarian5 (
  id INT PRIMARY KEY,
  schedule VARCHAR(100) NULL,
  CONSTRAINT fk_librarian_staff FOREIGN KEY (id) REFERENCES tblStaff5(id)
);

CREATE TABLE tblReaderCard5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cardCode VARCHAR(20) NOT NULL UNIQUE,
  registrationDate DATE NOT NULL,
  expiryDate DATE NOT NULL,
  cardStatus VARCHAR(30) NOT NULL DEFAULT 'Đang hoạt động',
  photo VARCHAR(255) NULL,
  readerId INT NOT NULL,
  CONSTRAINT fk_card_reader FOREIGN KEY (readerId) REFERENCES tblReader5(id)
);

CREATE TABLE tblSupplier5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  supplierCode VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(100) NULL,
  phone VARCHAR(20) NULL,
  address VARCHAR(255) NULL
);

-- ---------- Nhóm tài liệu ----------
CREATE TABLE tblDocument5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  documentCode VARCHAR(20) NOT NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  documentType VARCHAR(50) NOT NULL,
  author VARCHAR(150) NULL,
  publisher VARCHAR(150) NULL,
  `year` INT NULL,
  description TEXT NULL,
  language VARCHAR(50) NULL,
  pageCount INT NULL,
  documentStatus VARCHAR(30) NOT NULL DEFAULT 'Đang sử dụng'
);

CREATE TABLE tblPurchaseInvoice5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invoiceCode VARCHAR(20) NOT NULL UNIQUE,
  importDate DATE NOT NULL,
  supplierId INT NOT NULL,
  librarianId INT NOT NULL,
  CONSTRAINT fk_invoice_supplier FOREIGN KEY (supplierId) REFERENCES tblSupplier5(id),
  CONSTRAINT fk_invoice_librarian FOREIGN KEY (librarianId) REFERENCES tblLibrarian5(id)
);

CREATE TABLE tblImportDetail5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  quantity INT NOT NULL,
  price INT NOT NULL DEFAULT 0,
  purchaseInvoiceId INT NOT NULL,
  documentId INT NOT NULL,
  CONSTRAINT uq_import_invoice_doc UNIQUE (purchaseInvoiceId, documentId),
  CONSTRAINT fk_import_invoice FOREIGN KEY (purchaseInvoiceId) REFERENCES tblPurchaseInvoice5(id),
  CONSTRAINT fk_import_document FOREIGN KEY (documentId) REFERENCES tblDocument5(id)
);

-- copyCondition = "condition" trong báo cáo (CONDITION là từ khóa của MySQL)
CREATE TABLE tblDocumentCopy5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  copyCode VARCHAR(20) NOT NULL UNIQUE,
  location VARCHAR(100) NULL,
  copyCondition VARCHAR(30) NOT NULL DEFAULT 'Tốt',
  usageStatus VARCHAR(30) NOT NULL DEFAULT 'Sẵn có',
  documentId INT NOT NULL,
  importDetailId INT NULL,
  CONSTRAINT fk_copy_document FOREIGN KEY (documentId) REFERENCES tblDocument5(id),
  CONSTRAINT fk_copy_import FOREIGN KEY (importDetailId) REFERENCES tblImportDetail5(id)
);

-- ---------- Nhóm mượn / trả / phạt ----------
CREATE TABLE tblBorrowingSlip5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  borrowCode VARCHAR(20) NULL UNIQUE,
  borrowDate DATE NOT NULL,
  dueDate DATE NOT NULL,
  readerId INT NOT NULL,
  librarianId INT NOT NULL,
  CONSTRAINT fk_bslip_reader FOREIGN KEY (readerId) REFERENCES tblReader5(id),
  CONSTRAINT fk_bslip_librarian FOREIGN KEY (librarianId) REFERENCES tblLibrarian5(id)
);

CREATE TABLE tblBorrowingDetail5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  conditionOnBorrowing VARCHAR(30) NOT NULL,
  borrowingSlipId INT NOT NULL,
  documentCopyId INT NOT NULL,
  CONSTRAINT uq_bdetail_slip_copy UNIQUE (borrowingSlipId, documentCopyId),
  CONSTRAINT fk_bdetail_slip FOREIGN KEY (borrowingSlipId) REFERENCES tblBorrowingSlip5(id),
  CONSTRAINT fk_bdetail_copy FOREIGN KEY (documentCopyId) REFERENCES tblDocumentCopy5(id)
);

CREATE TABLE tblReturnSlip5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  returnCode VARCHAR(20) NOT NULL UNIQUE,
  returnDate DATE NOT NULL,
  readerId INT NOT NULL,
  librarianId INT NOT NULL,
  CONSTRAINT fk_rslip_reader FOREIGN KEY (readerId) REFERENCES tblReader5(id),
  CONSTRAINT fk_rslip_librarian FOREIGN KEY (librarianId) REFERENCES tblLibrarian5(id)
);

CREATE TABLE tblReturnDetail5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  conditionOnReturn VARCHAR(30) NOT NULL,
  note VARCHAR(255) NULL,
  returnSlipId INT NOT NULL,
  borrowingDetailId INT NOT NULL UNIQUE,
  CONSTRAINT fk_rdetail_slip FOREIGN KEY (returnSlipId) REFERENCES tblReturnSlip5(id),
  CONSTRAINT fk_rdetail_bdetail FOREIGN KEY (borrowingDetailId) REFERENCES tblBorrowingDetail5(id)
);

-- totalAmount là thuộc tính dẫn xuất => không lưu (tổng amount của tblFineDetail5)
CREATE TABLE tblFineSlip5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fineCode VARCHAR(20) NOT NULL UNIQUE,
  createdDate DATE NOT NULL,
  paymentStatus VARCHAR(30) NOT NULL DEFAULT 'Chưa thanh toán',
  paidDate DATE NULL,
  note VARCHAR(255) NULL,
  readerId INT NOT NULL,
  librarianId INT NOT NULL,
  CONSTRAINT fk_fslip_reader FOREIGN KEY (readerId) REFERENCES tblReader5(id),
  CONSTRAINT fk_fslip_librarian FOREIGN KEY (librarianId) REFERENCES tblLibrarian5(id)
);

CREATE TABLE tblFineDetail5 (
  id INT AUTO_INCREMENT PRIMARY KEY,
  daysLate INT NOT NULL DEFAULT 0,
  amount INT NOT NULL DEFAULT 0,
  description VARCHAR(255) NULL,
  fineSlipId INT NOT NULL,
  borrowingDetailId INT NOT NULL UNIQUE,
  CONSTRAINT fk_fdetail_slip FOREIGN KEY (fineSlipId) REFERENCES tblFineSlip5(id),
  CONSTRAINT fk_fdetail_bdetail FOREIGN KEY (borrowingDetailId) REFERENCES tblBorrowingDetail5(id)
);
