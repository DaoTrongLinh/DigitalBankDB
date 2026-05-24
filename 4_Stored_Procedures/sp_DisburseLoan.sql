DROP PROCEDURE IF EXISTS sp_DisburseLoan;

DELIMITER //
CREATE PROCEDURE sp_DisburseLoan(
    IN p_customer_id INT,
    IN p_account_id VARCHAR(20),
    IN p_amount DECIMAL(20,2),
    IN p_interest_rate DECIMAL(5,2),
    IN p_term_months INT,
    IN p_employee_id INT
)
BEGIN
    DECLARE v_account_exists INT;
    DECLARE v_total_interest DECIMAL(20,2); 
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK; 
        RESIGNAL; 
    END;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    START TRANSACTION;

        -- CHỐT CHẶN HẠN MỨC VÀ ĐIỀU KIỆN HỢP ĐỒNG
        IF p_amount < 5000000 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi Giao Dịch: Số tiền giải ngân tối thiểu phải từ 5.000.000đ trở lên.';
        END IF;

        IF p_term_months <= 0 OR p_interest_rate < 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Kỳ hạn hoặc lãi suất giải ngân không hợp lệ.';
        END IF;

        SELECT COUNT(*) INTO v_account_exists 
        FROM accounts 
        WHERE account_id = p_account_id AND customer_id = p_customer_id;

        IF v_account_exists = 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Tài khoản nhận giải ngân không hợp lệ.';
        ELSE
            SET v_total_interest = p_amount * (p_interest_rate / 100) * (p_term_months / 12);

            INSERT INTO loans (
                customer_id, loan_amount, remaining_balance, 
                interest_rate, term_months, status, maturity_date,
                interest_due 
            ) 
            VALUES (
                p_customer_id, p_amount, p_amount, 
                p_interest_rate, p_term_months, 'Active', 
                DATE_ADD(CURRENT_TIMESTAMP, INTERVAL p_term_months MONTH),
                v_total_interest 
            );

            UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_account_id;

            INSERT INTO transactions (account_receiver_id, employee_id, amount, transaction_type) 
            VALUES (p_account_id, p_employee_id, p_amount, 'LDB');

            COMMIT;
        END IF;
END //
DELIMITER ;