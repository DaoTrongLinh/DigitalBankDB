ALTER TABLE accounts 
ADD CONSTRAINT uk_customer_account UNIQUE (customer_id);