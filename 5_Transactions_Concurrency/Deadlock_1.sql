START TRANSACTION;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = '002604000010';

UPDATE accounts SET balance = balance + 1000 WHERE account_id = '002604000011';