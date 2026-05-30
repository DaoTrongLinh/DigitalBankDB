INSERT INTO branches (branch_name, location)
WITH RECURSIVE seq AS (
    SELECT 12 AS val UNION ALL SELECT val + 1 FROM seq WHERE val <= 50
)
SELECT 
    CONCAT('Chi nhánh Số ', val), 
    CONCAT('Địa chỉ mô phỏng số ', val, ', Hà Nội')
FROM seq;