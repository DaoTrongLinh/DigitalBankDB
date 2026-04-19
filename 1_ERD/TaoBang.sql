CREATE DATABASE digital_bank;
USE digital_bank;

-- 1. Bảng Chi nhánh
CREATE TABLE branches(
    branch_id INT PRIMARY KEY AUTO_INCREMENT,
    branch_name VARCHAR(100) NOT NULL,
    location VARCHAR(200)
);

-- 2. Bảng Nhân viên (Phụ thuộc Chi nhánh)
CREATE TABLE employees(
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    role VARCHAR(50) DEFAULT 'Teller', -- Giao dịch viên
    branch_id INT NOT NULL,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- 3. Bảng Khách hàng (Giữ nguyên cấu trúc của bạn)
CREATE TABLE customers(
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    address VARCHAR(100),
    email VARCHAR(100)
);

-- 4. Bảng Tài khoản 
-- (Đã thêm branch_id để biết tài khoản mở ở đâu và Ràng buộc Số dư)
CREATE TABLE accounts(
    account_id VARCHAR(20) PRIMARY KEY,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    balance DECIMAL(20,2) DEFAULT 0,
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT chk_balance CHECK (balance >= 0) -- Ràng buộc chống âm tiền
);

-- 5. Bảng Khoản vay
CREATE TABLE loans(
    loan_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    loan_amount DECIMAL(20,2) NOT NULL,       -- Tiền gốc vay ban đầu
    remaining_balance DECIMAL(20,2) NOT NULL, -- Tiền gốc còn nợ
    interest_due DECIMAL(20,2) DEFAULT 0,     -- Tiền lãi phải trả
    interest_rate DECIMAL(5,2) NOT NULL,      -- Lãi suất %/năm
    status ENUM('Active', 'Paid_Off', 'Bad_Debt') DEFAULT 'Active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- 6. Bảng Lịch sử Trả nợ
CREATE TABLE payments(
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id INT NOT NULL,
    account_id VARCHAR(20) NOT NULL, 
    amount DECIMAL(20,2) NOT NULL, 
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- 7. Bảng Loại giao dịch (Đã bổ sung các nghiệp vụ mới)
CREATE TABLE transaction_type(
    transaction_type_id CHAR(3) PRIMARY KEY,
    transaction_type_name VARCHAR(20) NOT NULL
);

INSERT INTO transaction_type VALUES
('DPS', 'DEPOSIT'),
('TSR', 'TRANSFER'),
('WIT', 'WITHDRAW'),
('LDB', 'LOAN_DISBURSEMENT'), -- Giải ngân tiền vay
('LRP', 'LOAN_REPAYMENT'),    -- Khách trả nợ
('INT', 'INTEREST_ACCRUED');  -- Hệ thống tính lãi hàng tháng

-- 8. Bảng Giao dịch (Sổ cái trung tâm)
CREATE TABLE transactions(
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    account_source_id VARCHAR(20) NULL,
    account_receiver_id VARCHAR(20) NULL,
    employee_id INT NULL, -- Thêm cột này. Để NULL nếu là khách tự dùng App
    amount DECIMAL(20,2) NOT NULL,
    transaction_type CHAR(3) NOT NULL,
    time DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (transaction_type) REFERENCES transaction_type(transaction_type_id),
    FOREIGN KEY (account_source_id) REFERENCES accounts(account_id),
    FOREIGN KEY (account_receiver_id) REFERENCES accounts(account_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Thêm cột nhân viên chăm sóc vào bảng khách hàng
ALTER TABLE customers 
ADD COLUMN assigned_employee_id INT NULL;

-- Tạo khóa ngoại liên kết sang bảng employees
ALTER TABLE customers 
ADD FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id);

-- Bổ sung tham số thời gian cho khoản vay
ALTER TABLE loans
ADD COLUMN term_months INT NOT NULL COMMENT 'Kỳ hạn vay (tháng)',
ADD COLUMN maturity_date DATETIME NULL COMMENT 'Ngày đáo hạn (Dùng để xét nợ xấu)';
