CREATE DATABASE digital_bank;
USE digital_bank;


CREATE TABLE branches(
    branch_id INT PRIMARY KEY AUTO_INCREMENT,
    branch_name VARCHAR(100) NOT NULL,
    location VARCHAR(200)
);


CREATE TABLE employees(
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    role VARCHAR(50) DEFAULT 'Teller', 
    branch_id INT NOT NULL,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);


CREATE TABLE customers(
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    address VARCHAR(100),
    email VARCHAR(100)
);


CREATE TABLE accounts(
    account_id VARCHAR(20) PRIMARY KEY,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    balance DECIMAL(20,2) DEFAULT 0,
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id),
    CONSTRAINT chk_balance CHECK (balance >= 0) 
);


CREATE TABLE loans(
    loan_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    loan_amount DECIMAL(20,2) NOT NULL,       
    remaining_balance DECIMAL(20,2) NOT NULL, 
    interest_due DECIMAL(20,2) DEFAULT 0,     
    interest_rate DECIMAL(5,2) NOT NULL,      
    status ENUM('Active', 'Paid_Off', 'Bad_Debt') DEFAULT 'Active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


CREATE TABLE payments(
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id INT NOT NULL,
    account_id VARCHAR(20) NOT NULL, 
    amount DECIMAL(20,2) NOT NULL, 
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);


CREATE TABLE transaction_type(
    transaction_type_id CHAR(3) PRIMARY KEY,
    transaction_type_name VARCHAR(20) NOT NULL
);

INSERT INTO transaction_type VALUES
('DPS', 'DEPOSIT'),
('TSR', 'TRANSFER'),
('WIT', 'WITHDRAW'),
('LDB', 'LOAN_DISBURSEMENT'), 
('LRP', 'LOAN_REPAYMENT'),    
('INT', 'INTEREST_ACCRUED');  


CREATE TABLE transactions(
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    account_source_id VARCHAR(20) NULL,
    account_receiver_id VARCHAR(20) NULL,
    employee_id INT NULL,
    amount DECIMAL(20,2) NOT NULL,
    transaction_type CHAR(3) NOT NULL,
    time DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (transaction_type) REFERENCES transaction_type(transaction_type_id),
    FOREIGN KEY (account_source_id) REFERENCES accounts(account_id),
    FOREIGN KEY (account_receiver_id) REFERENCES accounts(account_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);


ALTER TABLE customers 
ADD COLUMN assigned_employee_id INT NULL;


ALTER TABLE customers 
ADD FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id);


ALTER TABLE loans
ADD COLUMN term_months INT NOT NULL COMMENT 'Kỳ hạn vay (tháng)',
ADD COLUMN maturity_date DATETIME NULL COMMENT 'Ngày đáo hạn (Dùng để xét nợ xấu)';
