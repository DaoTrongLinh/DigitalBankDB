DROP PROCEDURE IF EXISTS sp_TransferMoney;

DELIMITER //
CREATE PROCEDURE sp_TransferMoney(
    IN p_sender_account_id VARCHAR(20),
    IN p_receiver_account_id VARCHAR(20),
    IN p_amount DECIMAL(20,2),
    IN p_employee_id INT 
)
BEGIN
    DECLARE v_sender_balance DECIMAL(20,2);
    DECLARE v_receiver_exists INT;
    DECLARE v_today_spent DECIMAL(20,2) DEFAULT 0;

    -- Đội cứu hộ khẩn cấp
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK; 
        RESIGNAL; 
    END;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    START TRANSACTION;

        IF p_amount <= 0 OR p_sender_account_id = p_receiver_account_id THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số tiền không hợp lệ hoặc trùng tài khoản.';
        END IF;

        -- Kiểm tra hạn mức
        SELECT COALESCE(SUM(amount), 0) INTO v_today_spent 
        FROM transactions 
        WHERE account_source_id = p_sender_account_id 
          AND transaction_type = 'TSR' 
          AND DATE(transaction_date) = CURDATE();

        IF (v_today_spent + p_amount) > 50000000 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi Giao Dịch: Vượt quá hạn mức chuyển 50.000.000đ/ngày!';
        END IF;

        SELECT balance INTO v_sender_balance FROM accounts WHERE account_id = p_sender_account_id;
        SELECT COUNT(*) INTO v_receiver_exists FROM accounts WHERE account_id = p_receiver_account_id;

        IF v_sender_balance IS NULL OR v_receiver_exists = 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Tài khoản không tồn tại.';
        ELSEIF v_sender_balance < p_amount THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số dư tài khoản gửi không đủ.';
        ELSE
            UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_sender_account_id;
            UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_receiver_account_id;

            INSERT INTO transactions (account_source_id, account_receiver_id, employee_id, amount, transaction_type)
            VALUES (p_sender_account_id, p_receiver_account_id, p_employee_id, p_amount, 'TSR');

            COMMIT;
        END IF;
END //
DELIMITER ;