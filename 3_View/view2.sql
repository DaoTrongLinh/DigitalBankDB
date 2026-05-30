-- View 1: Thống kê dòng tiền theo tháng
CREATE OR REPLACE VIEW vw_monthly_cashflow AS
WITH MonthlyVolume AS (
    SELECT DATE_FORMAT(time, '%Y-%m') AS trans_month, SUM(amount) AS total_vol
    FROM transactions GROUP BY DATE_FORMAT(time, '%Y-%m')
)
SELECT trans_month, total_vol FROM MonthlyVolume;

-- View 2: Bảng xếp hạng Khách hàng VIP
CREATE OR REPLACE VIEW vw_vip_customers AS
SELECT c.name AS customer_name, a.balance AS balance,
       DENSE_RANK() OVER (ORDER BY a.balance DESC) AS rank_num
FROM customers c JOIN accounts a ON c.customer_id = a.customer_id;

-- View 3: Top chi nhánh giải ngân nhiều nhất
CREATE OR REPLACE VIEW vw_branch_disbursements AS
WITH BranchDisbursement AS (
    SELECT b.branch_name, SUM(t.amount) AS total_disbursed
    FROM transactions t
    JOIN employees e ON t.employee_id = e.employee_id
    JOIN branches b ON e.branch_id = b.branch_id
    WHERE t.transaction_type = 'LDB'
    GROUP BY b.branch_name
)
SELECT branch_name, total_disbursed FROM BranchDisbursement;