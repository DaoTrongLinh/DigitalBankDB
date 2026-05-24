DROP PROCEDURE IF EXISTS sp_UpdateBadDebts;

DELIMITER //
CREATE PROCEDURE sp_UpdateBadDebts()
BEGIN
    -- Đội cứu hộ khẩn cấp
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK; 
        RESIGNAL; 
    END;

    START TRANSACTION;

        SET SQL_SAFE_UPDATES = 0;

        UPDATE loans 
        SET status = 'Bad_Debt' 
        WHERE status = 'Active' 
          AND DATE(maturity_date) < CURDATE();

        SET SQL_SAFE_UPDATES = 1;

    COMMIT;
END //
DELIMITER ;