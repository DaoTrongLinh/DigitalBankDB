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

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
    START TRANSACTION;

        IF p_amount <= 0 OR p_sender_account_id = p_receiver_account_id THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số tiền không hợp lệ hoặc trùng tài khoản.';
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

