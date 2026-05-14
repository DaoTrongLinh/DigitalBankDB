DELIMITER $$

CREATE PROCEDURE sp_withdraw (
    IN p_account_id VARCHAR(20),
    IN p_amount DECIMAL(20,2),
    IN p_employee_id INT 
)
BEGIN
    DECLARE v_balance DECIMAL(20,2);

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
    START TRANSACTION;

        IF p_amount <= 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số tiền rút phải lớn hơn 0.';
        END IF;

        SELECT balance INTO v_balance FROM accounts WHERE account_id = p_account_id;
        
        IF v_balance IS NULL THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Tài khoản không tồn tại.';
        ELSEIF v_balance < p_amount THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số dư không đủ để thực hiện giao dịch rút tiền.';
        ELSE
        
            UPDATE accounts
            SET balance = balance - p_amount
            WHERE account_id = p_account_id;

            INSERT INTO transactions (
                account_source_id,
                account_receiver_id,
                employee_id,
                amount,
                transaction_type
            )
            VALUES (
                p_account_id, 
                NULL,          
                p_employee_id, 
                p_amount,
                'WDR'
            );

           
            COMMIT;
        END IF;
END$$

DELIMITER ;
