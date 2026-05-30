DROP PROCEDURE IF EXISTS sp_RepayLoan;

DELIMITER //
CREATE PROCEDURE sp_RepayLoan(
    IN p_account_id VARCHAR(20),
    IN p_loan_id INT,
    IN p_amount DECIMAL(20,2),
    IN p_employee_id INT
)
BEGIN
    DECLARE v_current_balance DECIMAL(20,2);
    DECLARE v_remaining_balance DECIMAL(20,2);
    DECLARE v_interest_due DECIMAL(20,2);
    DECLARE v_total_debt DECIMAL(20,2);
    DECLARE v_actual_paid DECIMAL(20,2);
    DECLARE v_principal_paid DECIMAL(20,2) DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK; 
        RESIGNAL; 
    END;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    START TRANSACTION;

        -- 1. Kiểm tra số dư ví của khách hàng
        SELECT balance INTO v_current_balance 
        FROM accounts 
        WHERE account_id = p_account_id FOR UPDATE;

        IF v_current_balance < p_amount THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Số dư tài khoản không đủ để thực hiện thanh toán.';
        END IF;

        -- 2. Lấy thông tin khoản vay hiện tại
        SELECT remaining_balance, interest_due INTO v_remaining_balance, v_interest_due 
        FROM loans 
        WHERE loan_id = p_loan_id AND status = 'Active' FOR UPDATE;

        IF v_remaining_balance IS NULL THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Khoản vay không tồn tại hoặc đã được tất toán.';
        END IF;

        -- 3. XỬ LÝ LOGIC HOÀN TIỀN THỪA (Sửa lỗi số dư âm)
        SET v_total_debt = v_remaining_balance + v_interest_due;
        
        IF p_amount > v_total_debt THEN
            SET v_actual_paid = v_total_debt; -- Khách trả lố -> Chỉ thu đúng bằng tổng nợ
        ELSE
            SET v_actual_paid = p_amount;     -- Trả chưa hết nợ -> Thu đúng số tiền khách nhập
        END IF;

        -- 4. Trừ tiền tài khoản (chỉ trừ phần thực thu v_actual_paid)
        UPDATE accounts 
        SET balance = balance - v_actual_paid 
        WHERE account_id = p_account_id;

        -- 5. Phân bổ tiền trả (Ưu tiên thu Lãi trước, Gốc sau)
        IF v_actual_paid >= v_interest_due THEN
            SET v_principal_paid = v_actual_paid - v_interest_due;
            UPDATE loans 
            SET interest_due = 0, 
                remaining_balance = remaining_balance - v_principal_paid 
            WHERE loan_id = p_loan_id;
        ELSE
            UPDATE loans 
            SET interest_due = interest_due - v_actual_paid 
            WHERE loan_id = p_loan_id;
        END IF;

        -- 6. Cập nhật trạng thái Tất toán nếu hết nợ
        IF (v_remaining_balance - v_principal_paid) <= 0 THEN
            UPDATE loans 
            SET remaining_balance = 0, status = 'Paid_Off' 
            WHERE loan_id = p_loan_id;
        END IF;

        -- 7. Ghi nhận lịch sử giao dịch (Chỉ ghi nhận số tiền thực thu)
        INSERT INTO payments (loan_id, account_id, amount, payment_date)
        VALUES (p_loan_id, p_account_id, v_actual_paid, CURRENT_TIMESTAMP);

        INSERT INTO transactions (account_source_id, account_receiver_id, employee_id, amount, transaction_type)
        VALUES (p_account_id, NULL, p_employee_id, v_actual_paid, 'LRP');

    COMMIT;
END //
DELIMITER ;