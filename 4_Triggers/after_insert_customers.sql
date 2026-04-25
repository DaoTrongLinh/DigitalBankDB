DELIMITER //

CREATE TRIGGER trg_after_customer_insert
AFTER INSERT ON customers
FOR EACH ROW
BEGIN
    DECLARE v_new_account_id VARCHAR(20);
    DECLARE v_branch_id INT;
    
    IF NEW.assigned_employee_id IS NOT NULL THEN
        SELECT branch_id INTO v_branch_id
        FROM employees
        WHERE employee_id = NEW.assigned_employee_id;
    ELSE
        SET v_branch_id = 1;
    END IF;

    -- Cấu trúc: 00 (Mã NH) + YYMM (Năm tháng) + 6 số Customer ID
    SET v_new_account_id = CONCAT('00', DATE_FORMAT(NOW(), '%y%m'), LPAD(NEW.customer_id, 6, '0'));
    
    INSERT INTO accounts (account_id, customer_id, branch_id, balance)
    VALUES (v_new_account_id, NEW.customer_id, v_branch_id, 0);
    
END //

DELIMITER ;