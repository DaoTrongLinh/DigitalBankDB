DELIMITER //
CREATE TRIGGER trg_PreventNegativeBalance
BEFORE UPDATE ON accounts
FOR EACH ROW
BEGIN
    IF NEW.balance < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Lỗi Toàn Vẹn ACID: Số dư tài khoản không được phép rơi xuống mức âm!';
    END IF;
END //
DELIMITER ;