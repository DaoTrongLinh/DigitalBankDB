DROP PROCEDURE IF EXISTS sp_withdraw;

DELIMITER $$
CREATE PROCEDURE sp_withdraw (
    IN p_account_id VARCHAR(20),
    IN p_amount DECIMAL(20,2),
    IN p_employee_id INT 
)
BEGIN
    DECLARE v_balance DECIMAL(20,2);
    DECLARE v_today_spent DECIMAL(20,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK; 
        RESIGNAL; 
    END;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    START TRANSACTION;

        -- CHỐT CHẶN HẠN MỨC TỐI THIỂU
        IF p_amount < 1000 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi Giao Dịch: Số tiền rút tối thiểu phải từ 1.000đ trở lên.';
        END IF;

        -- Kiểm tra hạn mức tối đa trong ngày
        SELECT COALESCE(SUM(amount), 0) INTO v_today_spent 
        FROM transactions 
        WHERE account_source_id = p_account_id 
          AND transaction_type = 'WIT' 
          AND DATE(transaction_date) = CURDATE();

        IF (v_today_spent + p_amount) > 50000000 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi Giao Dịch: Vượt quá hạn mức rút 50.000.000đ/ngày!';
        END IF;

        SELECT balance INTO v_balance FROM accounts WHERE account_id = p_account_id;
        
        IF v_balance IS NULL THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Tài khoản không tồn tại.';
        ELSEIF v_balance < p_amount THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số dư không đủ để thực hiện giao dịch rút tiền.';
        ELSE
            UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_account_id;

            INSERT INTO transactions (account_source_id, account_receiver_id, employee_id, amount, transaction_type)
            VALUES (p_account_id, NULL, p_employee_id, p_amount, 'WIT');
            
            COMMIT;
        END IF;
END$$
DELIMITER ;