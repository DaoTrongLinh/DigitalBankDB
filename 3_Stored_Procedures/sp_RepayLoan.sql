DELIMITER //
CREATE PROCEDURE sp_RepayLoan(
    IN p_account_id VARCHAR(20),
    IN p_loan_id INT,
    IN p_amount DECIMAL(20,2),
    IN p_employee_id INT -- Truyền ID nhân viên nếu làm tại quầy, truyền NULL nếu khách tự trả qua App
)
BEGIN
    -- Khai báo các biến lưu trữ dữ liệu tạm thời để tính toán
    DECLARE v_balance DECIMAL(20,2);
    DECLARE v_interest_due DECIMAL(20,2);
    DECLARE v_remaining_principal DECIMAL(20,2);
    DECLARE v_pay_for_interest DECIMAL(20,2) DEFAULT 0;
    DECLARE v_pay_for_principal DECIMAL(20,2) DEFAULT 0;

    -- 1. Thiết lập mức độ cô lập cao nhất để tránh lỗi tranh chấp đồng thời
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
    -- 2. Bắt đầu Giao dịch (Transaction)
    START TRANSACTION;
    
        -- Đọc số dư ví hiện tại của khách
        SELECT balance INTO v_balance 
        FROM accounts 
        WHERE account_id = p_account_id;
        
        -- Đọc dư nợ lãi và dư nợ gốc hiện tại của khoản vay
        SELECT interest_due, remaining_balance INTO v_interest_due, v_remaining_principal 
        FROM loans 
        WHERE loan_id = p_loan_id;

        -- 3. Kiểm tra điều kiện: Số dư ví phải lớn hơn hoặc bằng số tiền muốn trả
        IF v_balance < p_amount THEN
            -- Hủy bỏ toàn bộ quá trình nếu không đủ tiền
            ROLLBACK;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tài khoản không đủ tiền để trả nợ';
        ELSE
            -- 4. Logic chẻ dòng tiền: Ưu tiên trả nợ lãi trước, nợ gốc sau
            IF p_amount >= v_interest_due THEN
                -- Nếu tiền trả đủ để phủ hết số lãi đang nợ
                SET v_pay_for_interest = v_interest_due;
                SET v_pay_for_principal = p_amount - v_interest_due;
            ELSE
                -- Nếu tiền trả chỉ đủ trả một phần lãi, chưa đụng được vào gốc
                SET v_pay_for_interest = p_amount;
                SET v_pay_for_principal = 0;
            END IF;

            -- 5. Thực hiện trừ tiền trong ví (accounts)
            UPDATE accounts 
            SET balance = balance - p_amount 
            WHERE account_id = p_account_id;
            
            -- 6. Thực hiện giảm nợ trong hợp đồng (loans)
            UPDATE loans 
            SET interest_due = interest_due - v_pay_for_interest,
                remaining_balance = remaining_balance - v_pay_for_principal
            WHERE loan_id = p_loan_id;

            -- 7. Ghi nhận biên lai vào bảng lịch sử trả nợ (payments)
            INSERT INTO payments (loan_id, account_id, amount) 
            VALUES (p_loan_id, p_account_id, p_amount);
            
            -- 8. Ghi sổ cái dòng tiền (transactions) với loại giao dịch Khách trả nợ ('LRP')
            INSERT INTO transactions (account_source_id, amount, transaction_type, employee_id)
            VALUES (p_account_id, p_amount, 'LRP', p_employee_id);

            -- 9. Kiểm tra nếu khách đã trả hết sạch nợ (gốc + lãi <= 0) thì đóng hợp đồng
            IF (SELECT (remaining_balance + interest_due) FROM loans WHERE loan_id = p_loan_id) <= 0 THEN
                UPDATE loans SET status = 'Paid_Off' WHERE loan_id = p_loan_id;
            END IF;
            
            -- 10. Mọi thao tác đều an toàn -> Xác nhận lưu dữ liệu vĩnh viễn
            COMMIT;
        END IF;
END //
DELIMITER ;