DROP PROCEDURE IF EXISTS sp_RepayLoan;

DELIMITER //
CREATE PROCEDURE sp_RepayLoan(
    IN p_account_id VARCHAR(20),
    IN p_loan_id INT,
    IN p_amount DECIMAL(20,2),
    IN p_employee_id INT 
)
BEGIN
    DECLARE v_balance DECIMAL(20,2);
    DECLARE v_interest_due DECIMAL(20,2);
    DECLARE v_remaining_principal DECIMAL(20,2);
    DECLARE v_pay_for_interest DECIMAL(20,2) DEFAULT 0;
    DECLARE v_pay_for_principal DECIMAL(20,2) DEFAULT 0;

    -- Đội cứu hộ khẩn cấp
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK; 
        RESIGNAL; 
    END;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    START TRANSACTION;
    
        SELECT balance INTO v_balance FROM accounts WHERE account_id = p_account_id;
        
        SELECT interest_due, remaining_balance INTO v_interest_due, v_remaining_principal 
        FROM loans WHERE loan_id = p_loan_id;

        IF v_balance < p_amount THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tài khoản không đủ tiền để trả nợ';
        ELSE
            IF p_amount >= v_interest_due THEN
                SET v_pay_for_interest = v_interest_due;
                SET v_pay_for_principal = p_amount - v_interest_due;
            ELSE
                SET v_pay_for_interest = p_amount;
                SET v_pay_for_principal = 0;
            END IF;

            UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_account_id;
            
            UPDATE loans 
            SET interest_due = interest_due - v_pay_for_interest,
                remaining_balance = remaining_balance - v_pay_for_principal
            WHERE loan_id = p_loan_id;

            INSERT INTO payments (loan_id, account_id, amount) VALUES (p_loan_id, p_account_id, p_amount);
            
            INSERT INTO transactions (account_source_id, amount, transaction_type, employee_id)
            VALUES (p_account_id, p_amount, 'LRP', p_employee_id);

            IF (SELECT (remaining_balance + interest_due) FROM loans WHERE loan_id = p_loan_id) <= 0 THEN
                UPDATE loans SET status = 'Paid_Off' WHERE loan_id = p_loan_id;
            END IF;
            
            COMMIT;
        END IF;
END //
DELIMITER ;