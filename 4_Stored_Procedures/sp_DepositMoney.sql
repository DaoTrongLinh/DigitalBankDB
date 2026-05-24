DROP PROCEDURE IF EXISTS sp_DepositMoney;

DELIMITER //
CREATE PROCEDURE sp_DepositMoney(
    IN p_account_id VARCHAR(20),
    IN p_amount DECIMAL(20,2),
    IN p_employee_id INT 
)
BEGIN
    DECLARE v_account_exists INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK; 
        RESIGNAL; 
    END;

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;

        -- CHỐT CHẶN HẠN MỨC TỐI THIỂU
        IF p_amount < 1000 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi Giao Dịch: Số tiền nạp tối thiểu phải từ 1.000đ trở lên.';
        END IF;

        SELECT COUNT(*) INTO v_account_exists FROM accounts WHERE account_id = p_account_id;

        IF v_account_exists = 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Tài khoản không tồn tại.';
        ELSE
            UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_account_id;

            INSERT INTO transactions (account_source_id, account_receiver_id, employee_id, amount, transaction_type)
            VALUES (NULL, p_account_id, p_employee_id, p_amount, 'DPS');

            COMMIT;
        END IF;
END //
DELIMITER ;