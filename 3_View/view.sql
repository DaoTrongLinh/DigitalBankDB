-- 1.View Tổng quan tài khoản khách hàng
CREATE VIEW vw_CustomerAccountSummary AS
SELECT 
    c.customer_id,
    c.name AS customer_name,
    c.phone_number,
    a.account_id,
    a.balance,
    b.branch_name,
    e.name AS assigned_employee
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
LEFT JOIN branches b ON a.branch_id = b.branch_id
LEFT JOIN employees e ON c.assigned_employee_id = e.employee_id;

-- 2.View Báo cáo tài chính theo Chi nhánh
CREATE VIEW vw_BranchPerformance AS
SELECT 
    b.branch_id,
    b.branch_name,
    COUNT(DISTINCT a.customer_id) AS total_customers,
    COUNT(a.account_id) AS total_accounts,
    SUM(a.balance) AS total_deposits
FROM branches b
LEFT JOIN accounts a ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name;

-- 3. View Chi tiết các khoản nợ cần thu hồi
CREATE VIEW vw_ActiveLoanDetails AS
SELECT 
    l.loan_id,
    c.name AS customer_name,
    l.loan_amount,
    l.remaining_balance AS principal_remaining,
    l.interest_due,
    (l.remaining_balance + l.interest_due) AS total_debt,
    l.interest_rate,
    l.maturity_date,
    DATEDIFF(l.maturity_date, CURRENT_TIMESTAMP) AS days_until_maturity,
    l.status
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
WHERE l.status = 'Active';

-- 4.View Nhật ký giao dịch chi tiết
CREATE VIEW vw_TransactionHistory AS
SELECT 
    t.transaction_id,
    t.time AS transaction_date,
    tt.transaction_type_name,
    t.amount,
    t.account_source_id,
    t.account_receiver_id,
    e.name AS processed_by_employee
FROM transactions t
JOIN transaction_type tt ON t.transaction_type = tt.transaction_type_id
LEFT JOIN employees e ON t.employee_id = e.employee_id;

-- 5. View Danh sách nợ xấu tiềm năng
CREATE VIEW vw_PotentialBadDebts AS
SELECT 
    l.loan_id,
    c.name AS customer_name,
    c.phone_number,
    l.remaining_balance,
    l.maturity_date,
    ABS(DATEDIFF(l.maturity_date, CURRENT_TIMESTAMP)) AS days_overdue
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
WHERE l.maturity_date < CURRENT_TIMESTAMP 
  AND l.status != 'Paid_Off';