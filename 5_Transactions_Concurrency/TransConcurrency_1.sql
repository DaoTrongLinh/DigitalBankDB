SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;
SELECT balance FROM accounts WHERE account_id = '002604000001' FOR UPDATE; 

UPDATE accounts SET balance = balance - 1000  WHERE account_id = '002604000001';
COMMIT;

select * from accounts;

