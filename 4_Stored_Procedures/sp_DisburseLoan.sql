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
    -- Khai báo biến kiểm tra
    DECLARE v_account_exists INT;

    -- 1. Thiết lập mức độ cô lập
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
    -- 2. Bắt đầu giao dịch an toàn
    START TRANSACTION;

        -- 3. Kiểm tra logic đầu vào (Tiền, kỳ hạn, lãi suất phải hợp lệ)
        IF p_amount <= 0 OR p_term_months <= 0 OR p_interest_rate < 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Thông tin giải ngân (số tiền, kỳ hạn, lãi suất) không hợp lệ.';
        END IF;

        -- 4. Kiểm tra xem tài khoản có tồn tại và CÓ ĐÚNG là của khách hàng này không
        SELECT COUNT(*) INTO v_account_exists 
        FROM accounts 
        WHERE account_id = p_account_id AND customer_id = p_customer_id;

        IF v_account_exists = 0 THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lỗi: Tài khoản không tồn tại hoặc không thuộc về khách hàng này.';
        ELSE
            -- 5. Chèn vào bảng loans (Tạo hợp đồng vay)
            INSERT INTO loans (
                customer_id, loan_amount, remaining_balance, 
                interest_rate, term_months, status, maturity_date
            ) 
            VALUES (
                p_customer_id, p_amount, p_amount, 
                p_interest_rate, p_term_months, 'Active', 
                DATE_ADD(CURRENT_TIMESTAMP, INTERVAL p_term_months MONTH)
            );

            -- 6. Cộng tiền giải ngân vào tài khoản của khách hàng
            UPDATE accounts 
            SET balance = balance + p_amount 
            WHERE account_id = p_account_id;

            -- 7. Ghi nhận vào sổ cái transactions
            -- account_receiver_id có dữ liệu, account_source_id để NULL vì tiền từ ngân hàng xuất ra
            INSERT INTO transactions (
                account_receiver_id, employee_id, amount, transaction_type
            ) 
            VALUES (
                p_account_id, p_employee_id, p_amount, 'LDB'
            );

            -- 8. Hoàn tất và lưu vĩnh viễn
            COMMIT;
        END IF;

END //

DELIMITER ;
