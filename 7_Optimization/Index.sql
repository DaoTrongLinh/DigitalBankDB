CREATE INDEX idx_customers_employee ON customers(assigned_employee_id);
CREATE INDEX idx_accounts_customer ON accounts(customer_id);
CREATE INDEX idx_accounts_branch ON accounts(branch_id);

CREATE INDEX idx_transactions_source ON transactions(account_source_id);
CREATE INDEX idx_transactions_receiver ON transactions(account_receiver_id);
CREATE INDEX idx_transactions_time ON transactions(time);

CREATE INDEX idx_loans_customer ON loans(customer_id);
CREATE INDEX idx_loans_status ON loans(status);

