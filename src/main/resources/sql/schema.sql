-- LibMan - schema MySQL 8 (17 bảng, theo sơ đồ thiết kế CSDL mục 3.2 báo cáo)
-- Chạy: mysql -u root -p < schema.sql   (sau đó chạy data.sql để nạp dữ liệu mẫu)

-- Collation mặc định của MySQL 8 (utf8mb4_0900_ai_ci): tìm kiếm không phân biệt hoa/thường và dấu tiếng Việt
create database if not exists libman;
use libman;

-- Nhóm thành viên: bảng con dùng chung id với bảng cha (khóa chính đồng thời là khóa ngoại)

-- type: vai trò của thành viên ('Độc giả', 'Nhân viên thư viện', 'Nhân viên quản lí')
-- isActive = 0 nghĩa là tài khoản bị khóa, độc giả cũng không được mượn tài liệu
create table tblMember5 (
  id int auto_increment primary key,
  username varchar(255) not null unique,
  password varchar(255) not null,
  fullName varchar(255) not null,
  email varchar(255) not null unique,
  phone varchar(255) not null,
  address varchar(255) not null,
  type varchar(255) not null,
  isActive tinyint(1) not null default 1,
  birthDate date null,
  note varchar(255) null
);

create table tblStaff5 (
  tblMember5id int primary key,
  staffCode varchar(255) not null unique,
  position varchar(255) not null,
  startDate date not null,
  foreign key (tblMember5id) references tblMember5(id)
);

create table tblManager5 (
  tblStaff5Member5id int primary key,
  managerLevel varchar(255) not null,
  foreign key (tblStaff5Member5id) references tblStaff5(tblMember5id)
);

create table tblLibrarian5 (
  tblStaff5Member5id int primary key,
  schedule varchar(255) null,
  foreign key (tblStaff5Member5id) references tblStaff5(tblMember5id)
);

create table tblReader5 (
  tblMember5id int primary key,
  readerCode varchar(255) not null unique,
  foreign key (tblMember5id) references tblMember5(id)
);

create table tblReaderCard5 (
  id int auto_increment primary key,
  cardCode varchar(255) not null unique,
  registrationDate date not null,
  expiryDate date not null,
  cardStatus varchar(255) not null,
  photo varchar(255) null,
  tblReader5tblMember5id int not null,
  foreign key (tblReader5tblMember5id) references tblReader5(tblMember5id)
);

-- Nhóm tài liệu và nhập tài liệu

create table tblSupplier5 (
  id int auto_increment primary key,
  supplierCode varchar(255) not null unique,
  name varchar(255) not null,
  email varchar(255) not null unique,
  phone varchar(255) not null,
  address varchar(255) not null,
  note varchar(255) null
);

-- status: trạng thái quản lí ('Đang sử dụng', 'Ngừng sử dụng')
create table tblDocument5 (
  id int auto_increment primary key,
  documentCode varchar(255) not null unique,
  title varchar(255) not null,
  documentType varchar(255) not null,
  author varchar(255) not null,
  publisher varchar(255) not null,
  `year` int not null,
  description varchar(255) not null,
  status varchar(255) null
);

-- copyCondition = "condition" trong báo cáo (condition là từ khóa của MySQL)
create table tblDocumentCopy5 (
  id int auto_increment primary key,
  copyCode varchar(255) not null unique,
  location varchar(255) not null,
  copyCondition varchar(255) not null,
  usageStatus varchar(255) not null,
  tblDocument5id int not null,
  foreign key (tblDocument5id) references tblDocument5(id)
);

create table tblPurchaseInvoice5 (
  id int auto_increment primary key,
  invoiceCode varchar(255) null unique,
  importDate date not null,
  tblSupplier5id int not null,
  tblLibrarian5tblStaff5Member5id int not null,
  foreign key (tblSupplier5id) references tblSupplier5(id),
  foreign key (tblLibrarian5tblStaff5Member5id) references tblLibrarian5(tblStaff5Member5id)
);

create table tblImportDetail5 (
  id int auto_increment primary key,
  quantity int not null,
  price int not null,
  tblPurchaseInvoice5id int not null,
  tblDocument5id int not null,
  foreign key (tblPurchaseInvoice5id) references tblPurchaseInvoice5(id),
  foreign key (tblDocument5id) references tblDocument5(id)
);

-- Nhóm mượn, trả, phạt

-- borrowCode để trống lúc insert, sinh từ id ngay sau đó (PM001, PM002...)
create table tblBorrowingSlip5 (
  id int auto_increment primary key,
  borrowCode varchar(255) null unique,
  borrowDate date not null,
  dueDate date not null,
  tblReader5tblMember5id int not null,
  tblLibrarian5tblStaff5Member5id int not null,
  foreign key (tblReader5tblMember5id) references tblReader5(tblMember5id),
  foreign key (tblLibrarian5tblStaff5Member5id) references tblLibrarian5(tblStaff5Member5id)
);

-- Một bản chỉ xuất hiện một lần trong một phiếu mượn
create table tblBorrowingDetail5 (
  id int auto_increment primary key,
  conditionOnBorrowing varchar(255) not null,
  tblBorrowingSlip5id int not null,
  tblDocumentCopy5id int not null,
  unique (tblBorrowingSlip5id, tblDocumentCopy5id),
  foreign key (tblBorrowingSlip5id) references tblBorrowingSlip5(id),
  foreign key (tblDocumentCopy5id) references tblDocumentCopy5(id)
);

create table tblReturnSlip5 (
  id int auto_increment primary key,
  returnCode varchar(255) null unique,
  returnDate date not null,
  note varchar(255) null,
  tblReader5tblMember5id int not null,
  tblLibrarian5tblStaff5Member5id int not null,
  foreign key (tblReader5tblMember5id) references tblReader5(tblMember5id),
  foreign key (tblLibrarian5tblStaff5Member5id) references tblLibrarian5(tblStaff5Member5id)
);

-- Mỗi chi tiết mượn được trả nhiều nhất một lần (quan hệ 1 - 0..1)
create table tblReturnDetail5 (
  id int auto_increment primary key,
  conditionOnReturn varchar(255) not null,
  note varchar(255) null,
  tblReturnSlip5id int not null,
  tblBorrowingDetail5id int not null unique,
  foreign key (tblReturnSlip5id) references tblReturnSlip5(id),
  foreign key (tblBorrowingDetail5id) references tblBorrowingDetail5(id)
);

-- totalAmount là thuộc tính dẫn xuất => không lưu (tổng amount của tblFineDetail5)
create table tblFineSlip5 (
  id int auto_increment primary key,
  fineCode varchar(255) not null unique,
  createdDate date not null,
  paymentStatus varchar(255) not null,
  paidDate date null,
  note varchar(255) null,
  tblReader5tblMember5id int not null,
  tblLibrarian5tblStaff5Member5id int not null,
  foreign key (tblReader5tblMember5id) references tblReader5(tblMember5id),
  foreign key (tblLibrarian5tblStaff5Member5id) references tblLibrarian5(tblStaff5Member5id)
);

-- Mỗi chi tiết mượn bị phạt nhiều nhất một lần (quan hệ 1 - 0..1)
create table tblFineDetail5 (
  id int auto_increment primary key,
  amount int not null,
  daysLate int not null,
  description varchar(255) null,
  note varchar(255) null,
  tblFineSlip5id int not null,
  tblBorrowingDetail5id int not null unique,
  foreign key (tblFineSlip5id) references tblFineSlip5(id),
  foreign key (tblBorrowingDetail5id) references tblBorrowingDetail5(id)
);
