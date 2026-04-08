CREATE TABLE customers(
	customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(15)  UNIQUE NOT NULL,
    address VARCHAR(100),
    email VARCHAR(100)
);

CREATE TABLE accounts(
	account_id VARCHAR(20) PRIMARY KEY,
    customer_id INT NOT NULL,
    balance DECIMAL(20,2) DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE transaction_type(
	transaction_type_id VARCHAR(10) PRIMARY KEY,
    transaction_type_name VARCHAR(30) NOT NULL
);

CREATE TABLE transactions(
	transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    account_source_id VARCHAR(20) NULL,
    acount_receiver_id VARCHAR(20) NULL,
    amount DECIMAL(20,2) NOT NULL,
    transaction_type VARCHAR(10) NOT NULL,
    time DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (transaction_type) REFERENCES transaction_type(transaction_type_id),
    FOREIGN KEY (account_source_id) REFERENCES accounts(account_id),
    FOREIGN KEY (acount_receiver_id) REFERENCES accounts(account_id)
);

INSERT INTO transaction_type
VALUES
('NAP', 'Nạp tiền'),
('CHUYEN', 'Chuyển tiền'),
('RUT', 'Rút tiền')
